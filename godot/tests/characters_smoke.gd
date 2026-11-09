extends SceneTree
const OPERATOR = preload("res://scripts/operative.gd")
var failures: Array[String] = []

func _assert(value: bool, label: String) -> void:
    if not value:
        failures.append(label)
        push_error("TEAMCS_ACTOR_FAIL: "+label)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for team in [0,1]:
        var actor = OPERATOR.new()
        get_root().add_child(actor)
        actor.build(team,2,2)
        _assert(is_instance_valid(actor.imported_holder),"imported mesh replaces primitives for team %d" % team)
        if not is_instance_valid(actor.imported_holder):
            continue
        var meshes = actor.imported_holder.find_children("*","MeshInstance3D",true,false)
        _assert(meshes.size() > 0,"actual detailed 3D meshes for team %d" % team)
        _assert(not is_instance_valid(actor.root),"no primitive geometry for team %d" % team)
        for i in range(8):
            actor.update_pose(2.3,0.05)
        actor.set_quality(0)
        actor.set_quality(2)
        if team == 1:
            _assert(is_instance_valid(actor.imported_animation),"rigged second character has an animation player")
            _assert(actor.imported_idle != "" or actor.imported_walk != "","second character has usable animation clips")
        actor.queue_free()
    if failures.is_empty():
        print("TEAMCS_REAL_CHARACTERS_PASS: both imported GLB actors and animation inspected")
        quit(0)
    else:
        print("TEAMCS_REAL_CHARACTERS_FAIL: ",failures)
        quit(1)
