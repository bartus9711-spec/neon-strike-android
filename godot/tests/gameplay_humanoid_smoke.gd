extends SceneTree
## Exercise the fitted/animated characters in the real 5v5 scene on every map.
const BOUNDS = preload("res://scripts/skinned_bounds.gd")
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, label: String) -> void:
    if not ok:
        failures.append(label)
        push_error("TEAMCS_GAMEPLAY_FAILURE: " + label)

func _run() -> void:
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    _check(game.arena.maps.size() == 8, "eight existing arenas")
    _check(root.disable_3d, "arena rendering stops behind the lobby")
    game.lobby._play()
    _check(not root.disable_3d, "PLAY restores main 3D rendering")
    game._close_buy_phase()
    _check(not root.disable_3d, "match remains visible after buying")
    game._return_to_lobby()
    _check(root.disable_3d, "return to lobby stops hidden arena rendering")
    for index in range(game.arena.maps.size()):
        game.switch_map(index)
        await process_frame
        _check(game.bots.roster.size() == 9, "nine bots on map %d" % index)
        var teams := [0,0]
        for bot in game.bots.roster:
            teams[bot.team] += 1
            var actor = bot.operative
            _check(is_instance_valid(actor.imported_model), "imported in-game humanoid")
            _check(is_instance_valid(actor.imported_anim), "in-game animator")
            _check(actor.imported_source_path.ends_with("soldier_tac.glb" if bot.team == 0 else "soldier.glb"), "distinct CT/T models in the actual match")
        _check(teams == [4,5], "player + four CT versus five T")
        var operative = game.bots.roster[0].operative
        operative.update_pose(3.0,.2)
        operative.imported_anim.advance(.25)
        var body: AABB = BOUNDS.model_bounds(operative.imported_model, operative)
        _check(body.size.y > 1.3 and body.size.y < 2.1, "animated body stays human-sized")
        _check(body.size.x < 2.0 and body.size.z < 2.0, "no exploding skin in run pose")
        print("TEAMCS_GAMEPLAY_MAP_OK: ",index," bots=",teams," animated_size=",body.size)
    game.queue_free()
    await process_frame
    if failures.is_empty():
        print("TEAMCS_GAMEPLAY_HUMANOIDS_PASS: eight maps, 5v5, animated fitted bodies")
        quit(0)
    else:
        quit(1)
