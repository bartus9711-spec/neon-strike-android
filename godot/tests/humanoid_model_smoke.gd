extends SceneTree
## End-to-end Godot GLB import regression test for actual humanoid meshes.
const CHARACTER = preload("res://scripts/operative.gd")
var issues: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _verify(condition: bool, message: String) -> void:
    if not condition:
        issues.append(message)
        push_error("TEAMCS_HUMAN_FAILURE: "+message)

func _run() -> void:
    for index in range(2):
        var actor = CHARACTER.new()
        actor.prefer_detail_lod = index == 0
        get_root().add_child(actor)
        actor.build(index,index,2)
        _verify(is_instance_valid(actor.imported_model),"model imported team "+str(index))
        if is_instance_valid(actor.imported_model):
            var geometry: Array[Node] = actor.imported_model.find_children("*","MeshInstance3D",true,false)
            _verify(geometry.size()>0,"imported model has mesh team "+str(index))
            print("TEAMCS_HUMAN_GEOMETRY team=",index," meshes=",geometry.size())
            var aabb_count := 0
            for shape in geometry:
                if (shape as MeshInstance3D).get_aabb().size.length_squared() > 0:
                    aabb_count += 1
            _verify(aabb_count>0,"imported model geometry not empty")
            var bottom := Vector3(INF,INF,INF)
            var top := Vector3(-INF,-INF,-INF)
            for surface in geometry:
                var mesh := surface as MeshInstance3D
                var to_actor: Transform3D = actor.global_transform.affine_inverse() * mesh.global_transform
                for v in range(8):
                    var point: Vector3 = to_actor * mesh.get_aabb().get_endpoint(v)
                    bottom = bottom.min(point)
                    top = top.max(point)
            var size: Vector3 = top-bottom
            print("TEAMCS_HUMAN_NORMALIZED_SIZE: team=",index," size=",size)
            _verify(size.y > 1.48 and size.y < 2.05,"imported model standing height ~1.75m")
            _verify(size.x > .25 and size.x < 2.1,"imported model plausible width")
            _verify(size.z > .15 and size.z < 2.1,"imported model plausible depth")
        if index == 1:
            _verify(is_instance_valid(actor.imported_anim),"rigged in-game humanoid has animator")
            if is_instance_valid(actor.imported_anim):
                print("TEAMCS_HUMAN_CLIPS: ",actor.imported_anim.get_animation_list())
                _verify(actor.anim_idle != &"","rigged humanoid includes idle animation")
                _verify(actor.anim_walk != &"","rigged humanoid includes walking animation")
                _verify(actor.anim_run != &"","rigged humanoid includes running animation")
                _verify(actor.anim_sprint != &"","rigged humanoid includes sprint animation")
                actor.update_pose(0.0,.20)
                _verify(actor.imported_anim.current_animation == actor.anim_idle,"stopped actor must use idle")
                actor.update_pose(1.2,.20)
                _verify(actor.imported_anim.current_animation == actor.anim_walk,"slow actor must use walk clip")
                actor.update_pose(3.0,.20)
                _verify(actor.imported_anim.current_animation == actor.anim_run,"moving actor must use run clip")
                actor.update_pose(5.2,.20)
                _verify(actor.imported_anim.current_animation == actor.anim_sprint,"fast actor must use sprint clip")
                actor.update_pose(0.0,.20)
                _verify(actor.imported_anim.current_animation == actor.anim_idle,"actor returns to idle without freezing")
                print("TEAMCS_HUMAN_MOTION_STATES_PASS: idle/walk/run/sprint/idle")
        actor.update_pose(2.5,.016)
    if issues.is_empty():
        print("TEAMCS_HUMAN_IMPORT_PASS")
        quit(0)
    else:
        print("TEAMCS_HUMAN_IMPORT_FAIL: ",issues)
        quit(1)
