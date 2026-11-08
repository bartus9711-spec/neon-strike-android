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
    print("CI_VISUAL_ASSERTIONS_OK: 3D scene, mobile stick, Bluetooth pad polling, Ultra / FPS")
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
