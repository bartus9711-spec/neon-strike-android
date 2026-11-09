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
    # Native FPS gameplay must really exist, not just render empty scenery.
    if main.bots.count_bots() != 7 or main.bots.count_visible_rivals() != 4:
        push_error("CI: 4v4 gameplay actors missing")
        quit(24)
        return
    var first_rig = main.bots.roster[0]["operative"
    if first_rig == null or not is_instance_valid(first_rig) or first_rig.left_leg == null or first_rig.helmet == null:
        push_error("CI: procedural human operative geometry/animation pivots missing")
        quit(25)
        return
    first_rig.update_pose(3.5,.08)
    if absf(first_rig.left_leg.rotation.x) < .001:
        first_rig.update_pose(3.5,.21)
    if absf(first_rig.left_leg.rotation.x) < .001:
        push_error("CI: procedural humanoid gait never moved")
        quit(31)
        return
    var ally: CharacterBody3D = main.bots.roster[0]["body"]
    if ally.global_position.distance_to(main.hero.global_position) < 3.0:
        push_error("CI: human player spawned inside AI teammate")
        quit(26)
        return
    var rival: CharacterBody3D = main.bots.roster[3]["body"]
    if not main.bots.tag_from_player(rival) or main.bots.cyan_score != 1:
        push_error("CI: energy-tag scoring/respawn gameplay broken")
        quit(27)
        return
    main.switch_map(0)
    main._emit_pulse()
    if main.energy != 23 or main.pulse_cooldown <= 0.0:
        push_error("CI: first-person pulse/energy gameplay failed")
        quit(28)
        return
    main._recharge()
    if main.recharge_remaining <= 0.0:
        push_error("CI: recharge input failed")
        quit(29)
        return
    main.switch_map(0)
    print("CI_FPS_GAMEPLAY_OK: 4v4 animated actors, team score, respawn, first-person energy-tag and recharge")
    main.hud._emit_graphics()
    if Engine.max_fps != 60:
        push_error("CI: safe 60 FPS default configuration was not applied")
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
    # Verify that Low really removes PBR textures and optional geometry,
    # then Ultra restores them — across maps, not just in a settings menu.
    main.hud._on_profile_selected(0)
    await process_frame
    if Engine.max_fps != 60 or main.arena.detail_level != 0 or main.arena.texture_enabled:
        push_error("CI: LOW does not apply real performance reductions")
        quit(19)
        return
    main.hud._on_profile_selected(2)
    await process_frame
    if Engine.max_fps != 120 or main.arena.detail_level != 2 or not main.arena.texture_enabled:
        push_error("CI: ULTRA fails to restore texture and details")
        quit(20)
        return
    if main.hud.network_toggle.button_pressed or main.net.smart_enabled:
        push_error("CI: smart network routing must be explicitly opt-in")
        quit(21)
        return
    main.hud.network_toggle.button_pressed = true
    main.hud._emit_graphics()
    if not main.net.smart_enabled:
        push_error("CI: explicit network preference was not routed to network monitor")
        quit(22)
        return
    main.hud.network_toggle.button_pressed = false
    main.hud._emit_graphics()
    if main.net.game_server_rtt_ms >= 0:
        push_error("CI: game server ping must not be invented")
        quit(23)
        return
    print("CI_PERFORMANCE_AND_NETWORK_SETTINGS_OK: Low / Ultra affect materials, render and user opt-in")
    if main.arena.maps.size() != 8:
        push_error("CI: map selector missing some of the eight original arenas")
        quit(13)
        return
    var folder := ProjectSettings.globalize_path("res://visual-qa")
    DirAccess.make_dir_recursive_absolute(folder)
    var ids := {}
    for i in range(8):
        main.switch_map(i)
        await process_frame
        await process_frame
        await create_timer(.65).timeout
        var map_id := str(main.arena.current_map.get("id", ""))
        ids[map_id] = true
        if main.bots.count_bots() != 7 or main.bots.count_visible_rivals() != 4:
            push_error("CI: missing 4v4 characters on map index "+str(i))
            quit(30)
            return
        if main.arena.current_index != i:
            push_error("CI: selected map index not loaded")
            quit(14)
            return
        if main.arena.world.get_child_count() < 12:
            push_error("CI: arena has too little geometry: " + map_id)
            quit(15)
            return
        if main.hud.map_select.selected != i:
            push_error("CI: map selection HUD mismatch: " + map_id)
            quit(16)
            return
        var capture := root.get_texture().get_image()
        var filename := "teamcs-" + map_id + ".png"
        var saved := capture.save_png(folder.path_join(filename))
        if saved != OK or capture.get_width() < 400:
            push_error("CI: map screenshot failed: " + filename)
            quit(17)
            return
        print("MAP_VISUAL_CAPTURE_OK: ", map_id, "  render dimensions=", capture.get_width(),"x", capture.get_height())
        if i == 0:
            capture.save_png(folder.path_join("teamcs-godot-preview.png"))
    if ids.size() != 8:
        push_error("CI: map identifiers are not distinct")
        quit(18)
        return
    print("ALL_EIGHT_ARENAS_RENDERED_AND_TESTED")
    quit(0)
