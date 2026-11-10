extends SceneTree
## Exercise actual AI deceleration; moving bots must not switch to an idle pose.
const BOTS = preload("res://scripts/bots.gd")
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, label: String) -> void:
    if not ok:
        failures.append(label)
        push_error("TEAMCS_BOT_MOTION_FAILURE: " + label)

func _run() -> void:
    var bots = BOTS.new()
    root.add_child(bots)
    bots.set_physics_process(false)
    var bot: Dictionary = bots._make_actor(0,"MotionTest",Vector3(0,1,0),0)
    bots.roster.append(bot)
    bot.think = 10.0
    bot.cooldown = 10.0
    bot.goal = Vector3(0,1,-5)
    bot.body.velocity = Vector3(0,0,-1.2)
    bots._physics_process(1.0/60.0)
    _check(bot.body.velocity.length() > 1.0,"bot is still moving while braking near target")
    _check(bot.operative.imported_anim.current_animation == bot.operative.anim_walk,"braking motion uses walk, not idle")
    # Acceleration to a distant goal also starts a walk below the old 1.5 m/s gate.
    bot.goal = Vector3(0,1,-20)
    bot.body.velocity = Vector3(0,0,-.7)
    bots._physics_process(1.0/60.0)
    _check(bot.operative.imported_anim.current_animation == bot.operative.anim_walk,"slow acceleration uses walk")
    bot.goal = bot.body.global_position
    bot.body.velocity = Vector3.ZERO
    bots._physics_process(1.0/60.0)
    _check(bot.operative.imported_anim.current_animation == bot.operative.anim_idle,"stationary bot returns to idle")
    bots.queue_free()
    await process_frame
    if failures.is_empty():
        print("TEAMCS_BOT_MOTION_PASS: acceleration, braking, stop")
        quit(0)
    else:
        quit(1)
