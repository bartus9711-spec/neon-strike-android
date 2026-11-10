extends RefCounted
## Evaluate the same bone/skin transforms used for rendered vertices.
## Raw Mesh AABBs are in bind space, which is not the visible character space.

static func mesh_bounds(instance: MeshInstance3D, relative_to: Node3D) -> AABB:
    var into_root: Transform3D = relative_to.global_transform.affine_inverse() * instance.global_transform
    var skeleton := instance.get_node_or_null(instance.skeleton) as Skeleton3D
    if instance.skin == null or skeleton == null:
        return into_root * instance.get_aabb()
    skeleton.force_update_all_bone_transforms()
    var skin: Skin = instance.skin
    var transforms: Array[Transform3D] = []
    for bind in range(skin.get_bind_count()):
        var bone: int = skin.get_bind_bone(bind)
        if skin.get_bind_name(bind) != &"":
            bone = skeleton.find_bone(skin.get_bind_name(bind))
        assert(bone >= 0, "Missing skin bone")
        transforms.append(skeleton.get_bone_global_pose(bone) * skin.get_bind_pose(bind))
    var smallest := Vector3(INF, INF, INF)
    var largest := Vector3(-INF, -INF, -INF)
    for surface in range(instance.mesh.get_surface_count()):
        var arrays: Array = instance.mesh.surface_get_arrays(surface)
        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
        var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
        var influences: int = bones.size() / maxi(vertices.size(), 1)
        for v in range(vertices.size()):
            var point := Vector3.ZERO
            if influences == 0:
                point = vertices[v]
            else:
                for influence in range(influences):
                    var index: int = v * influences + influence
                    if weights[index] > 0.0:
                        point += (transforms[bones[index]] * vertices[v]) * weights[index]
            point = into_root * point
            smallest = smallest.min(point)
            largest = largest.max(point)
    return AABB(smallest, largest - smallest)

static func model_bounds(model: Node3D, relative_to: Node3D) -> AABB:
    var result := AABB()
    var first := true
    for node in model.find_children("*", "MeshInstance3D", true, false):
        var bounds: AABB = mesh_bounds(node as MeshInstance3D, relative_to)
        result = bounds if first else result.merge(bounds)
        first = false
    return result

static func offset_skin(mesh: MeshInstance3D, model: Node3D, offset: Vector3) -> void:
    # Change only this accessory's bind transforms, not the shared source Skin
    # or the armature. The offset stays attached when its bone is animated.
    var skeleton := mesh.get_node(mesh.skeleton) as Skeleton3D
    var skin := mesh.skin.duplicate() as Skin
    var into_model: Transform3D = model.global_transform.affine_inverse() * mesh.global_transform
    var translation := Transform3D(Basis.IDENTITY, into_model.basis.inverse() * offset)
    for bind in range(skin.get_bind_count()):
        var bone := skin.get_bind_bone(bind)
        if skin.get_bind_name(bind) != &"":
            bone = skeleton.find_bone(skin.get_bind_name(bind))
        var pose := skeleton.get_bone_global_pose(bone)
        skin.set_bind_pose(bind, pose.affine_inverse() * translation * pose * skin.get_bind_pose(bind))
    mesh.skin = skin
