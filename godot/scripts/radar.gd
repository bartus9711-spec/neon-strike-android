extends Control
## Small, inexpensive tactical radar using live map collisions and bot positions.
## No fake positions; draws from the actual current scene.
var tracked_player: CharacterBody3D
var squad
var current_arena
var elapsed := 0.0

func configure(player: CharacterBody3D, bot_controller: Node3D, arena_node: Node3D) -> void:
    tracked_player = player
    squad = bot_controller
    current_arena = arena_node
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    if elapsed >= .16 and visible:
        elapsed = 0.0
        queue_redraw()

func _point(x: float, z: float, side: float) -> Vector2:
    return Vector2(
        size.x * (0.5 + x / (side * 2.0)),
        size.y * (0.5 + z / (side * 2.0))
    )

func _draw() -> void:
    var dims := size
    if dims.x < 20 or dims.y < 20:
        return
    draw_rect(Rect2(Vector2.ZERO,dims),Color(.025,.041,.050,.89))
    var side := 42.0
    if is_instance_valid(current_arena):
        side = maxf(20.0,float(current_arena.current_map.get("side",42.0)))
        var obstacles: Array = current_arena.current_map.get("obstacles",[])
        for raw in obstacles:
            if not raw is Dictionary:
                continue
            var obstacle: Dictionary = raw
            var w := float(obstacle.get("w",0.0))
            var d := float(obstacle.get("d",0.0))
            var center := _point(float(obstacle.get("x",0.0)),float(obstacle.get("z",0.0)),side)
            var block := Vector2(w/side*.5*dims.x,d/side*.5*dims.y)
            draw_rect(Rect2(center-block*.5,block),Color(.37,.42,.43,.40))
    draw_line(Vector2(dims.x*.5,5),Vector2(dims.x*.5,dims.y-5),Color(.30,.39,.42,.35),1.0)
    draw_line(Vector2(5,dims.y*.5),Vector2(dims.x-5,dims.y*.5),Color(.30,.39,.42,.35),1.0)
    if is_instance_valid(squad):
        for bot in squad.roster:
            if not bool(bot.get("alive",false)):
                continue
            var body: Node3D = bot.get("body")
            if not is_instance_valid(body):
                continue
            var pos := body.global_position
            var tint := Color(.49,.82,.90) if int(bot.get("team",0)) == 0 else Color(.90,.51,.38)
            draw_circle(_point(pos.x,pos.z,side),3.0,tint)
    if is_instance_valid(tracked_player):
        var here := tracked_player.global_position
        var p := _point(here.x,here.z,side)
        draw_circle(p,5.1,Color(.97,.95,.78))
        draw_arc(p,8.0,0,TAU,18,Color(.93,.90,.68,.38),1.0)
    draw_rect(Rect2(Vector2.ZERO,dims),Color(.43,.57,.60,.80),false,1.2)
