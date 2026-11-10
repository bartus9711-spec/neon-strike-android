extends SceneTree
const LOBBY = preload("res://scripts/lobby.gd")
const CHECK = preload("res://tests/character_render_check.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var lobby = LOBBY.new()
    root.add_child(lobby)
    # Negative control: mesh nodes still exist and report sensible bounds, but
    # no character is rendered. The pixel gate must reject this configuration.
    if "--invisible-models" in OS.get_cmdline_user_args():
        for actor in lobby.previews:
            actor.imported_model.hide()
    var directory := OS.get_environment("TEAMCS_QA_OUTPUT") if OS.has_environment("TEAMCS_QA_OUTPUT") else "res://.."
    var ok: bool = await CHECK.new().run(lobby, directory)
    lobby.queue_free()
    await process_frame
    quit(0 if ok else 1)
