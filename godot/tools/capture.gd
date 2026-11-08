extends SceneTree
## CI visual smoke run: boots scene, checks critical touch/pad/graphics hooks and saves a real render.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed = load("res://scenes/main.tscn")
    if packed == null:
        push_error("CI: main scene did not load")
        quit(2)
        return
    var main = packed.instantiate()
    root.add_child(main)
    await process_frame
    await process_frame
    if main == null or main.hud == null:
        push_error("CI: HUD missing")
        quit(3)
        return
    if not is_instance_valid(main.camera) or not is_instance_valid(main.hero):
        push_error("CI: 3D player/camera missing")
        quit(4)
        return
    if main.hud.fps_select.item_count != 4:
        push_error("CI: 30/60/90/120 FPS settings missing")
        quit(5)
        return
    if main.hud.touch_base == null or main.hud.touch_knob == null:
        push_error("CI: touch stick missing")
        quit(6)
        return
    if main.hud.profile_select.item_count != 3:
        push_error("CI: graphics profiles missing")
        quit(7)
        return
    main.hud._emit_graphics()
    if Engine.max_fps != 120:
        push_error("CI: 120 FPS configuration was not applied")
        quit(9)
        return
    # Simulate separate virtual thumbstick and right-side look touch pointers.
    var left_press := InputEventScreenTouch.new()
    left_press.index = 1
    left_press.pressed = true
    left_press.position = Vector2(100, 560)
    main.hud._input(left_press)
    var left_drag := InputEventScreenDrag.new()
    left_drag.index = 1
    left_drag.position = Vector2(170, 520)
    left_drag.relative = Vector2(70, -40)
    main.hud._input(left_drag)
    if main.hud.touch_move.length() < .10:
        push_error("CI: left touch virtual movement failed")
        quit(10)
        return
    var right_press := InputEventScreenTouch.new()
    right_press.index = 2
    right_press.pressed = true
    right_press.position = Vector2(1050, 330)
    main.hud._input(right_press)
    var right_drag := InputEventScreenDrag.new()
    right_drag.index = 2
    right_drag.position = Vector2(1090, 310)
    right_drag.relative = Vector2(40, -20)
    main.hud._input(right_drag)
    if main.hud.consume_look().length() < 1:
        push_error("CI: right touch look control failed")
        quit(11)
        return
    var left_release := InputEventScreenTouch.new()
    left_release.index = 1
    left_release.pressed = false
    left_release.position = Vector2(170, 520)
    main.hud._input(left_release)
    if main.hud.touch_move.length() != 0:
        push_error("CI: virtual movement failed to release")
        quit(12)
        return
    var right_release := InputEventScreenTouch.new()
    right_release.index = 2
    right_release.pressed = false
    main.hud._input(right_release)
    print("CI_VISUAL_ASSERTIONS_OK: Godot 3D, dual touch inputs, Ultra and 120 FPS options; real Bluetooth pad still needs device test")
    await create_timer(3.0).timeout
    var folder := ProjectSettings.globalize_path("res://visual-qa")
    DirAccess.make_dir_recursive_absolute(folder)
    var capture := root.get_texture().get_image()
    var saved := capture.save_png(folder.path_join("teamcs-godot-preview.png"))
    print("VISUAL_CAPTURE: ", saved, " dimensions: ", capture.get_width(),"x", capture.get_height())
    if saved != OK or capture.get_width() < 400:
        quit(8)
        return
    quit(0)
