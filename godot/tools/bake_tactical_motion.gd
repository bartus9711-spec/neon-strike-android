extends SceneTree
## Offline adaptation of the pinned soldier's motion to the tactical rig.
## Run after fetching/importing models. No donor skeleton or CPU skinning on phone.
const CHARACTER = preload("res://scripts/operative.gd")
const BOUNDS = preload("res://scripts/skinned_bounds.gd")
const OUTPUT := "res://assets/models/tactical_motion.tres"
const CLIPS := ["ready_idle", "ready_walk", "ready_run", "ready_sprint"]
const SOURCE_CLIPS := ["ready_idle", "mocap_walk_F_1_1733", "mocap_jog_F_1_7529", "mocap_run2_F_2_0049"]
const SAMPLE_RATE := 60.0

func _initialize() -> void:
    call_deferred("_run")

func _name(bone: String) -> String:
    var suffix := RegEx.new()
    suffix.compile("_0[0-9]+$")
    return suffix.sub(bone.replace("mixamorig_", ""), "")

func _binds(mesh: MeshInstance3D, skeleton: Skeleton3D) -> Dictionary:
    var result := {}
    for bind in range(mesh.skin.get_bind_count()):
        var bone := mesh.skin.get_bind_bone(bind)
        if mesh.skin.get_bind_name(bind) != &"":
            bone = skeleton.find_bone(mesh.skin.get_bind_name(bind))
        result[bone] = mesh.skin.get_bind_pose(bind)
    return result

func _mesh(model: Node3D) -> MeshInstance3D:
    for node in model.find_children("*", "MeshInstance3D", true, false):
        if node.skin != null:
            return node
    return null

func _run() -> void:
    var started := Time.get_ticks_msec()
    var source = CHARACTER.new()
    root.add_child(source)
    source.build(1, 0, 2)
    var target = CHARACTER.new()
    target.prefer_detail_lod = true
    root.add_child(target)
    target.build(0, 0, 2)
    if is_instance_valid(target.imported_anim):
        target.imported_anim.stop()
    var src: Skeleton3D = source.imported_model.find_children("*", "Skeleton3D", true, false)[0]
    var dst: Skeleton3D = target.imported_model.find_children("*", "Skeleton3D", true, false)[0]
    dst.reset_bone_poses()
    dst.force_update_all_bone_transforms()
    var sm := _mesh(source.imported_model)
    var tm := _mesh(target.imported_model)
    var sb := _binds(sm, src)
    var tb := _binds(tm, dst)
    var src_model: Transform3D = source.imported_model.global_transform.affine_inverse() * sm.global_transform
    var dst_model: Transform3D = target.imported_model.global_transform.affine_inverse() * tm.global_transform
    var source_names := {}
    for bone in range(src.get_bone_count()):
        source_names[_name(src.get_bone_name(bone))] = bone
    # Mocap supplies pelvis/legs; retain the source tactical ready grip above
    # the pelvis instead of allowing unused mocap arm tracks to restore T-pose.
    source.imported_anim.play("ready_idle")
    source.imported_anim.seek(0, true)
    source.imported_anim.pause()
    var upper_pose := {}
    for bone in range(src.get_bone_count()):
        var ancestor := bone
        var lower_body := _name(src.get_bone_name(bone)) == "Hips"
        while ancestor >= 0:
            if _name(src.get_bone_name(ancestor)) in ["LeftUpLeg", "RightUpLeg"]:
                lower_body = true
            ancestor = src.get_bone_parent(ancestor)
        if not lower_body:
            upper_pose[bone] = [src.get_bone_pose_position(bone), src.get_bone_pose_rotation(bone), src.get_bone_pose_scale(bone)]
    var mapping := {}
    for bone in range(dst.get_bone_count()):
        var key := _name(dst.get_bone_name(bone))
        if source_names.has(key) and tb.has(bone) and sb.has(source_names[key]):
            mapping[bone] = source_names[key]
    if mapping.size() != 65:
        push_error("TEAMCS_TACTICAL_BAKE_FAIL: pinned rig mapping changed")
        quit(1)
        return
    var hip := dst.find_bone("mixamorig_Hips_01")
    var rest_hip := dst.get_bone_pose_position(hip)
    var into_actor: Transform3D = target.global_transform.affine_inverse() * dst.global_transform
    var hip_parent := dst.get_bone_parent(hip)
    var up_in_hip_parent := dst.get_bone_global_pose(hip_parent).basis.inverse() * into_actor.basis.inverse() * Vector3.UP
    var library := AnimationLibrary.new()
    library.set_meta("source_clips", SOURCE_CLIPS)
    library.set_meta("source_commit", "130ac2a5c856401ec36e7d35afcfefe40c5801f4")
    library.set_meta("sample_rate", SAMPLE_RATE)
    for index in range(CLIPS.size()):
        var clip: String = CLIPS[index]
        var source_clip: String = SOURCE_CLIPS[index]
        var original: Animation = source.imported_anim.get_animation(source_clip)
        var animation := Animation.new()
        animation.resource_name = clip
        animation.length = 4.0 if clip == "ready_idle" else original.length
        animation.loop_mode = Animation.LOOP_LINEAR
        var tracks := {}
        for bone in mapping:
            var track := animation.add_track(Animation.TYPE_ROTATION_3D)
            animation.track_set_path(track, NodePath(".:" + dst.get_bone_name(bone)))
            tracks[bone] = track
        var position_track := animation.add_track(Animation.TYPE_POSITION_3D)
        animation.track_set_path(position_track, NodePath(".:" + dst.get_bone_name(hip)))
        var frames := roundi(animation.length * SAMPLE_RATE)
        var first_rotations := {}
        var previous_rotations := {}
        var first_position := Vector3.ZERO
        var lowest := INF
        var highest := -INF
        source.imported_anim.play(source_clip)
        for frame in range(frames):
            var time := animation.length * float(frame) / float(frames)
            source.imported_anim.seek(time, true)
            source.imported_anim.pause()
            for bone in upper_pose:
                src.set_bone_pose_position(bone, upper_pose[bone][0])
                src.set_bone_pose_rotation(bone, upper_pose[bone][1])
                src.set_bone_pose_scale(bone, upper_pose[bone][2])
            if clip == "ready_idle":
                # The source ready pose is static. Add restrained chest motion,
                # without scaling the whole figure or moving the collision body.
                var spine := src.find_bone("mixamorig_Spine2")
                src.set_bone_pose_rotation(spine, src.get_bone_pose_rotation(spine) * Quaternion(Vector3.RIGHT, sin(time / animation.length * TAU) * .008))
            src.force_update_all_bone_transforms()
            dst.set_bone_pose_position(hip, rest_hip)
            # Bind bases account for both rest-pose orientation and authoring
            # axes/units. Copying local quaternions directly twists these rigs.
            # Bone order is parent-first; preserve target limb lengths/scales.
            for bone in mapping:
                var s: int = mapping[bone]
                var wanted: Basis = (dst_model.basis.inverse() * src_model.basis * src.get_bone_global_pose(s).basis * sb[s].basis * tb[bone].basis.inverse()).orthonormalized()
                var parent := dst.get_bone_parent(bone)
                if parent >= 0:
                    wanted = dst.get_bone_global_pose(parent).basis.orthonormalized().inverse() * wanted
                var rotation := wanted.get_rotation_quaternion().normalized()
                if previous_rotations.has(bone) and rotation.dot(previous_rotations[bone]) < 0:
                    rotation = -rotation
                dst.set_bone_pose_rotation(bone, rotation)
                dst.force_update_all_bone_transforms()
                animation.rotation_track_insert_key(tracks[bone], time, rotation)
                previous_rotations[bone] = rotation
                if frame == 0:
                    first_rotations[bone] = rotation
            # Match source sole clearance in fitted metres, not raw hip units.
            # Walking stays grounded; running retains the source flight phase.
            # Only vertical displacement is baked: CharacterBody owns X/Z motion.
            var source_floor: float = BOUNDS.model_bounds(source.imported_model, source).position.y
            var target_floor: float = BOUNDS.model_bounds(target.imported_model, target).position.y
            var clearance := maxf(0.0, source_floor) if clip in ["ready_run", "ready_sprint"] else 0.0
            var position := rest_hip + up_in_hip_parent * (clearance - target_floor)
            animation.position_track_insert_key(position_track, time, position)
            lowest = minf(lowest, clearance)
            highest = maxf(highest, clearance)
            if frame == 0:
                first_position = position
        # Exact endpoints prevent a rest-pose pop at the loop seam.
        for bone in mapping:
            animation.rotation_track_insert_key(tracks[bone], animation.length, first_rotations[bone])
        animation.position_track_insert_key(position_track, animation.length, first_position)
        # Mocap exports have a per-clip floor offset. Remove the cycle minimum
        # so a stance foot reaches the floor, while preserving flight clearance.
        for key in range(animation.track_get_key_count(position_track)):
            var position: Vector3 = animation.track_get_key_value(position_track, key)
            animation.track_set_key_value(position_track, key, position - up_in_hip_parent * lowest)
        # Hands in a ready grip contain many constant tracks. Keep the endpoints
        # without duplicating the same quaternion 60 times per second on mobile.
        for bone in mapping:
            var track: int = tracks[bone]
            var constant := true
            for key in range(animation.track_get_key_count(track)):
                var rotation: Quaternion = animation.track_get_key_value(track, key)
                if not rotation.is_equal_approx(first_rotations[bone]):
                    constant = false
                    break
            if constant:
                for key in range(animation.track_get_key_count(track) - 2, 0, -1):
                    animation.track_remove_key(track, key)
        library.add_animation(clip, animation)
        print("TEAMCS_TACTICAL_BAKED: ", clip, " source=", source_clip, " frames=", frames, " bones=", mapping.size(), " sole_clearance=", Vector2(0, highest - lowest))
    var error := ResourceSaver.save(library, OUTPUT)
    source.free()
    target.free()
    print("TEAMCS_TACTICAL_BAKE_", "PASS" if error == OK else "FAIL", ": ms=", Time.get_ticks_msec() - started)
    quit(0 if error == OK else 1)
