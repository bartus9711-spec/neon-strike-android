extends SceneTree
## Exercise real fitted skin vertices throughout each baked gait, not just keys.
const CHARACTER = preload("res://scripts/operative.gd")
const BOUNDS = preload("res://scripts/skinned_bounds.gd")
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, label: String) -> void:
    if not ok:
        failures.append(label)
        push_error("TEAMCS_TACTICAL_MOTION_FAILURE: " + label)

func _run() -> void:
    var actor = CHARACTER.new()
    actor.prefer_detail_lod = true
    root.add_child(actor)
    actor.build(0, 0, 2)
    if not is_instance_valid(actor.imported_anim):
        _check(false, "detailed CT must have an animator")
        quit(1)
        return
    var player: AnimationPlayer = actor.imported_anim
    var skeletons: Array[Node] = actor.imported_model.find_children("*", "Skeleton3D", true, false)
    _check(skeletons.size() == 1, "no donor skeleton left in the scene")
    var skeleton := skeletons[0] as Skeleton3D
    var knee := -1
    # Match by canonical name; the suffix is an importer identifier, not anatomy.
    for b in range(skeleton.get_bone_count()):
        if str(skeleton.get_bone_name(b)).begins_with("mixamorig_LeftLeg_"):
            knee = b
    _check(knee >= 0, "left knee exists")
    var spine := skeleton.find_bone("mixamorig_Spine2_04")
    var actor_transform: Transform3D = actor.transform
    for clip in [actor.anim_idle, actor.anim_walk, actor.anim_run, actor.anim_sprint]:
        _check(clip != &"", "all four tactical clips are present")
        if clip == &"":
            continue
        var animation := player.get_animation(clip)
        _check(animation.loop_mode == Animation.LOOP_LINEAR, str(clip) + " loops")
        var minimum := INF
        var maximum := -INF
        var knee_start := Quaternion.IDENTITY
        var knee_motion := 0.0
        var spine_start := Quaternion.IDENTITY
        var spine_motion := 0.0
        var samples := roundi(animation.length * 120.0)
        player.play(clip)
        for frame in range(samples):
            player.seek(animation.length * float(frame) / float(samples), true)
            player.pause()
            skeleton.force_update_all_bone_transforms()
            var bounds: AABB = BOUNDS.model_bounds(actor.imported_model, actor)
            _check(bounds.position.is_finite() and bounds.size.is_finite(), str(clip) + " finite skin")
            _check(bounds.size.y > 1.25 and bounds.size.y < 2.05, str(clip) + " human height")
            _check(bounds.size.x < 1.5 and bounds.size.z < 1.8, str(clip) + " no exploding limbs/accessories")
            minimum = minf(minimum, bounds.position.y)
            maximum = maxf(maximum, bounds.position.y)
            var rotation := skeleton.get_bone_pose_rotation(knee)
            if frame == 0:
                knee_start = rotation
                spine_start = skeleton.get_bone_pose_rotation(spine)
            knee_motion = maxf(knee_motion, knee_start.angle_to(rotation))
            spine_motion = maxf(spine_motion, spine_start.angle_to(skeleton.get_bone_pose_rotation(spine)))
        _check(minimum > -.02, str(clip) + " boots do not sink into ground")
        _check(minimum < .02, str(clip) + " has grounded stance phase")
        _check(maximum < (.02 if clip in [actor.anim_idle, actor.anim_walk] else .30), str(clip) + " bounded sole clearance")
        if clip != actor.anim_idle:
            _check(knee_motion > .25, str(clip) + " knee actually flexes")
        else:
            _check(spine_motion > .005, "idle includes chest breathing")
        for track in range(animation.get_track_count()):
            var last := animation.track_get_key_count(track) - 1
            var a: Variant = animation.track_get_key_value(track, 0)
            var b: Variant = animation.track_get_key_value(track, last)
            if a is Quaternion:
                _check(a.angle_to(b) < .002, str(clip) + " continuous rotation seam")
            elif a is Vector3:
                _check(a.distance_to(b) < .0001, str(clip) + " continuous position seam")
        player.play(clip)
        player.advance(animation.length * 3.25)
        _check(player.is_playing(), str(clip) + " survives three cycles")
        _check(actor.transform == actor_transform, "animation never moves CharacterBody/world root")
        print("TEAMCS_TACTICAL_CYCLE: ", clip, " clearance=", Vector2(minimum,maximum), " knee_radians=", knee_motion)
    var second = CHARACTER.new()
    second.prefer_detail_lod = true
    root.add_child(second)
    second.build(0, 1, 2)
    _check(second.imported_anim.get_animation_library(&"") == player.get_animation_library(&""), "actors share baked animation data")
    var soldier = CHARACTER.new()
    root.add_child(soldier)
    soldier.build(1, 0, 1)
    for clip in [soldier.anim_idle, soldier.anim_walk, soldier.anim_run, soldier.anim_sprint]:
        soldier.imported_anim.play(clip)
        soldier.imported_anim.advance(soldier.imported_anim.get_animation(clip).length * 3.25)
        _check(soldier.imported_anim.is_playing(), "existing soldier gait stays looping: " + str(clip))
    actor.free()
    second.free()
    soldier.free()
    print("TEAMCS_TACTICAL_MOTION_PASS" if failures.is_empty() else "TEAMCS_TACTICAL_MOTION_FAIL")
    quit(0 if failures.is_empty() else 1)
