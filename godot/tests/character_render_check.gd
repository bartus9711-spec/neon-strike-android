extends RefCounted
## Requires a real renderer (Xvfb is fine); headless dummy rendering is not QA.
## Compare actual rendered pixels with the same scene without its characters.
var failures: Array[String] = []
var output_dir := "res://.."
var tree: SceneTree

func _check(ok: bool, message: String) -> void:
    if not ok:
        failures.append(message)
        push_error("TEAMCS_RENDER_FAILURE: " + message)

func _frame() -> void:
    # Visibility/animation updates must have reached the rendered frame.
    for i in range(3):
        await tree.process_frame
        await RenderingServer.frame_post_draw

func _save(image: Image, name: String) -> void:
    _check(image.save_png(output_dir.path_join(name)) == OK, "save " + name)

func _coverage(scene: Image, empty: Image, team: int) -> void:
    var w := scene.get_width()
    var h := scene.get_height()
    var count := 0
    var lo := Vector2i(w, h)
    var hi := Vector2i.ZERO
    for y in range(h):
        for x in range(w):
            var a := scene.get_pixel(x, y)
            var b := empty.get_pixel(x, y)
            if absf(a.r-b.r) + absf(a.g-b.g) + absf(a.b-b.b) > .12:
                count += 1
                lo = lo.min(Vector2i(x,y))
                hi = hi.max(Vector2i(x,y))
    var extent := hi - lo
    print("TEAMCS_RENDER_COVERAGE: team=",team," pixels=",count,
        " image=",Vector2i(w,h)," origin=",lo," extent=",extent)
    _check(count > w*h*.025, "team %d covers a full visible silhouette" % team)
    _check(extent.y > h*.55 and extent.x > w*.08, "team %d head-to-boots extent" % team)
    _check(lo.y > 1 and hi.y < h-2, "team %d fits vertically in frame" % team)
    _check(lo.x > 1 and hi.x < w-2, "team %d fits horizontally in frame" % team)
    var center := (lo.x + hi.x)*.5
    _check(center < w*.5 if team == 0 else center > w*.5, "correct faction side")

func run(lobby: CanvasLayer, directory: String) -> bool:
    tree = lobby.get_tree()
    output_dir = directory
    if DisplayServer.get_name() == "headless":
        push_error("TEAMCS_RENDER_FAILURE: use a real graphics driver, not --headless")
        return false
    var was_active: bool = lobby.active
    lobby.active = false
    for actor in lobby.previews:
        if is_instance_valid(actor.imported_anim):
            actor.imported_anim.advance(.4)
            actor.imported_anim.pause()
    await _frame()
    print("TEAMCS_QA_RENDER_COST: draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
        " primitives=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
    _save(tree.root.get_texture().get_image(), "teamcs-lobby.png")
    _save(lobby.preview.get_texture().get_image(), "teamcs-operators.png")
    for actor in lobby.previews:
        actor.hide()
    await _frame()
    var empty: Image = lobby.preview.get_texture().get_image()
    _save(empty, "teamcs-empty-stage.png")
    for team in range(lobby.previews.size()):
        var actor: Node3D = lobby.previews[team]
        actor.show()
        await _frame()
        var rendered: Image = lobby.preview.get_texture().get_image()
        _save(rendered, "teamcs-operator-%d.png" % team)
        _coverage(rendered, empty, team)
        actor.hide()
    # The detailed CT used to have no clips at all. Prove the skinned pixels
    # change with each gait, on desktop AND inside the exported Android APK.
    var ct = lobby.previews[0]
    ct.show()
    if not is_instance_valid(ct.imported_anim):
        _check(false, "detailed CT animator exists")
    else:
        for clip in ["ready_walk", "ready_run", "ready_sprint"]:
            var images: Array[Image] = []
            var animation: Animation = ct.imported_anim.get_animation(clip)
            for phase in [.125, .625]:
                ct.imported_anim.play(clip)
                ct.imported_anim.seek(animation.length * phase, true)
                ct.imported_anim.pause()
                await _frame()
                var pose: Image = lobby.preview.get_texture().get_image()
                images.append(pose)
                _save(pose, "teamcs-ct-%s-%d.png" % [clip, images.size()])
            var changed := 0
            for y in range(images[0].get_height()):
                for x in range(images[0].get_width()):
                    var a := images[0].get_pixel(x,y)
                    var b := images[1].get_pixel(x,y)
                    if absf(a.r-b.r) + absf(a.g-b.g) + absf(a.b-b.b) > .12:
                        changed += 1
            _check(changed > images[0].get_width()*images[0].get_height()*.003, clip + " changes visible CT pixels")
            print("TEAMCS_TACTICAL_RENDER_MOTION: ", clip, " changed_pixels=", changed)
        ct.imported_anim.play(ct.anim_idle)
        ct.imported_anim.advance(0)
    for actor in lobby.previews:
        actor.show()
    lobby.active = was_active
    await _frame()
    if failures.is_empty():
        print("TEAMCS_CHARACTER_RENDER_PASS")
        return true
    else:
        print("TEAMCS_CHARACTER_RENDER_FAIL: ",failures)
        return false

func capture_gameplay(game: Node3D) -> void:
    # Exercise the real PLAY -> purchase -> match transition in the exported
    # APK as well. Save the actual first-person view for manual visual review.
    game.lobby._play()
    game._close_buy_phase()
    game.set_physics_process(false)
    game.bots.process_mode = Node.PROCESS_MODE_DISABLED
    await _frame()
    _check(not tree.root.disable_3d, "PLAY restores the main Android 3D viewport")
    _check(not game.lobby.root.visible, "match hides the lobby")
    _save(tree.root.get_texture().get_image(), "teamcs-match.png")
    print("TEAMCS_QA_MATCH_COST: draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
    game._return_to_lobby()
    game.set_physics_process(true)
    await _frame()
    if failures.is_empty():
        print("TEAMCS_GAMEPLAY_RENDER_PASS")
