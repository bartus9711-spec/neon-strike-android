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
