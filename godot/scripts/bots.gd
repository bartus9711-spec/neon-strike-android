extends Node3D
## TeamCS 3D arena match: 4 vs 4, non-graphic energy-tag FPS gameplay.
## Animated original CC0 humanoid GLB, team uniforms, collision, AI and respawns.
## AI can tag an opponent only with a clear line of sight.
signal score_changed(cyan: int, magenta: int)
signal player_tagged()
signal round_finished(winner: int)

const MODEL_PATH := "res://assets/models/RobotExpressive.glb"
const WIN_SCORE := 12
const RESPAWN_DELAY := 3.4

var roster: Array[Dictionary] = []
var cyan_score := 0
var magenta_score := 0
var round_over := false
var actor_quality := 2
var time_left := 300.0
var hero: CharacterBody3D
var arena
var spawn_sets: Array = []
var _timer := 0.0
var _rng := RandomNumberGenerator.new()
var _colored_materials: Array[StandardMaterial3D] = []
var _model_resource: PackedScene

func _ready() -> void:
    _rng.randomize()
    if ResourceLoader.exists(MODEL_PATH):
        _model_resource = load(MODEL_PATH) as PackedScene
    _colored_materials = [_make_team_material(Color(.09,.85,.95)),_make_team_material(Color(1,.25,.61))]

func _make_team_material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = .26
    mat.metallic = .45
    mat.emission_enabled = true
    mat.emission = color * .7
    mat.emission_energy_multiplier = 1.05
    return mat

func _color_disc(body: Node3D, color_team: int) -> void:
    var halo := MeshInstance3D.new()
    halo.name = "TeamIdentification"
    var ring := TorusMesh.new()
    ring.inner_radius = .24
    ring.outer_radius = .33
    halo.mesh = ring
    halo.position = Vector3(0,2.02,0)
    halo.rotation_degrees.x = 90
    halo.material_override = _colored_materials[color_team]
    body.add_child(halo)
    var badge := MeshInstance3D.new()
    badge.name = "SuitChevron"
    var chevron := SphereMesh.new()
    chevron.radius = .095
    chevron.height = .19
    badge.mesh = chevron
    badge.position = Vector3(0,1.45,.29)
    badge.material_override = _colored_materials[color_team]
    body.add_child(badge)

func _fallback_avatar(root: Node3D, team: int) -> void:
    # Intentional contingency if CC0 GLB fetch/import failed: no box-man.
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(.22,.29,.36) if team == 0 else Color(.31,.24,.32)
    mat.roughness = .44
    for spec in [
        [Vector3(0,1.13,0),Vector3(.45,.67,.27)],
        [Vector3(0,1.73,0),Vector3(.19,.23,.19)],
        [Vector3(-.43,1.20,0),Vector3(.16,.61,.17)],
        [Vector3(.43,1.20,0),Vector3(.16,.61,.17)],
        [Vector3(-.17,.49,0),Vector3(.18,.67,.20)],
        [Vector3(.17,.49,0),Vector3(.18,.67,.20)]
    ]:
        var part := MeshInstance3D.new()
        var mesh := CapsuleMesh.new()
        mesh.radius = 1
        mesh.height = 2
        part.mesh = mesh
        part.position = spec[0]
        part.scale = spec[1]
        part.material_override = mat
        root.add_child(part)
    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = .21
    sphere.height = .43
    head.mesh = sphere
    head.position = Vector3(0,1.76,0)
    head.material_override = _colored_materials[team]
    root.add_child(head)

func _fit_model(root: Node3D) -> void:
    # Scale any source units to ~1.78m so imported humanoids do not dwarf arenas.
    # glTF rigs may offset the model origin; recenter using mesh bounds.
    var lowest := INF
    var highest := -INF
    for node in root.find_children("*","MeshInstance3D",true,false):
        var mesh_node := node as MeshInstance3D
        var box := mesh_node.get_aabb()
        var relative := root.global_transform.affine_inverse() * mesh_node.global_transform
        for corner in range(8):
            var y := (relative * box.get_endpoint(corner)).y
            lowest = minf(lowest,y)
            highest = maxf(highest,y)
    if lowest == INF or highest <= lowest:
        return
    var sc := clampf(1.73/(highest-lowest),.015,12.)
    root.scale = Vector3.ONE * sc
    root.position.y = -lowest * sc

func _make_actor(team: int, name: String, position: Vector3, index: int) -> Dictionary:
    var actor := CharacterBody3D.new()
    actor.name = name
    actor.collision_layer = 4
    actor.collision_mask = 1
    actor.floor_snap_length = .24
    actor.position = position
    var capsule := CapsuleShape3D.new()
    capsule.radius = .35
    capsule.height = 1.76
    var collision := CollisionShape3D.new()
    collision.shape = capsule
    collision.position.y = .90
    actor.add_child(collision)
    add_child(actor)
    var animated: Node3D = Node3D.new()
    animated.name = "Character"
    actor.add_child(animated)
    var animation_player: AnimationPlayer = null
    if _model_resource != null:
        var model := _model_resource.instantiate() as Node3D
        if model != null:
            animated.add_child(model)
            _fit_model(model)
            model.rotation.y = PI
            for node in model.find_children("*","AnimationPlayer",true,false):
                animation_player = node as AnimationPlayer
                break
    else:
        _fallback_avatar(animated,team)
    _color_disc(actor,team)
    var entry := {
        "body":actor, "visual":animated, "animation_player":animation_player,
        "team":team, "index":index, "alive":true, "respawn":0.0,
        "cooldown":_rng.randf_range(.5,2.2), "think":0.0,
        "goal":Vector3.ZERO, "motion":0.0, "speed":_rng.randf_range(2.7,3.5),
        "avoid":float(_rng.randi_range(-1,1))
    }
    _play(entry,"Idle")
    return entry

func _play(bot: Dictionary, action: String) -> void:
    var player: AnimationPlayer = bot["animation_player"]
    if player == null or actor_quality == 0:
        return
    var desired := action.to_lower()
    for animation_name in player.get_animation_list():
        if str(animation_name).to_lower().contains(desired):
            if player.current_animation != str(animation_name):
                player.play(str(animation_name),.24)
            return
    var names := player.get_animation_list()
    if names.size() > 0 and player.current_animation == "":
        player.play(str(names[0]))

func new_round(data: Dictionary, arena_node: Node3D, player_body: CharacterBody3D) -> void:
    for entry in roster:
        var body: CharacterBody3D = entry["body"]
        if is_instance_valid(body):
            body.collision_layer = 0
            body.queue_free()
    roster.clear()
    hero = player_body
    arena = arena_node
    cyan_score = 0
    magenta_score = 0
    round_over = false
    time_left = 300.0
    spawn_sets = [data.get("spawnBlue",[]), data.get("spawnRed",[])]
    # 3 cyan allies + human, versus 4 red challengers: 4v4.
    for team in [0,1]:
        var number := 3 if team == 0 else 4
        for i in range(number):
            var where := _spawn(team,i)
            var actor := _make_actor(team,("ALLY_" if team == 0 else "RIVAL_")+str(i+1),where,i)
            roster.append(actor)
    apply_actor_quality(actor_quality)
    score_changed.emit(cyan_score,magenta_score)

func _spawn(team: int, slot: int) -> Vector3:
    var list: Array = spawn_sets[team]
    if list.is_empty():
        return Vector3(-27,0,25) if team == 0 else Vector3(27,0,-25)
    for offset in range(list.size()):
        var point: Array = list[(slot+offset)%list.size()]
        var x := float(point[0])
        var z := float(point[1])
        if not arena._spot_obstructed(x,z,.66):
            return Vector3(x,.12,z)
    return Vector3(float(list[0][0]),.12,float(list[0][1]))

func apply_actor_quality(quality: int) -> void:
    actor_quality = clampi(quality,0,2)
    for entry in roster:
        var p: AnimationPlayer = entry["animation_player"]
        if p != null:
            if actor_quality == 0:
                p.stop()
            else:
                _play(entry,"Idle")

func _best_target(bot: Dictionary) -> Node3D:
    var origin: Node3D = bot["body"]
    var best: Node3D = null
    var closest := 999999.0
    if int(bot["team"]) == 1 and is_instance_valid(hero):
        var distance := origin.global_position.distance_squared_to(hero.global_position)
        if distance < closest:
            closest = distance
            best = hero
    for entry in roster:
        if not bool(entry["alive"]) or int(entry["team"]) == int(bot["team"]):
            continue
        var other: Node3D = entry["body"]
        var distance := origin.global_position.distance_squared_to(other.global_position)
        if distance < closest:
            closest = distance
            best = other
    return best

func _has_sight(from_node: CharacterBody3D,to_node: Node3D) -> bool:
    var start := from_node.global_position + Vector3(0,1.4,0)
    var finish := to_node.global_position + Vector3(0,1.28,0)
    var query := PhysicsRayQueryParameters3D.create(start,finish,1|2|4,[from_node.get_rid()])
    var result := get_world_3d().direct_space_state.intersect_ray(query)
    return not result.is_empty() and result["collider"] == to_node

func _physics_process(delta: float) -> void:
    if roster.is_empty() or round_over:
        return
    time_left = maxf(0,time_left-delta)
    if time_left == 0:
        _end_round(0 if cyan_score >= magenta_score else 1)
        return
    for idx in range(roster.size()):
        var entry := roster[idx]
        var body: CharacterBody3D = entry["body"]
        if not is_instance_valid(body):
            continue
        if not bool(entry["alive"]):
            entry["respawn"] = float(entry["respawn"])-delta
            if float(entry["respawn"]) <= 0:
                entry["alive"] = true
                body.global_position = _spawn(int(entry["team"]),int(entry["index"]))
                body.visible = true
                body.collision_layer = 4
                body.velocity = Vector3.ZERO
                _play(entry,"Idle")
            continue
        entry["cooldown"] = float(entry["cooldown"])-delta
        entry["think"] = float(entry["think"])-delta
        var goal: Vector3 = entry["goal"]
        if float(entry["think"]) <= 0:
            entry["think"] = _rng.randf_range(.48,.82)
            var target := _best_target(entry)
            if target != null:
                goal = target.global_position
                entry["goal"] = goal
        var diff := goal-body.global_position
        diff.y = 0
        var destination := diff.normalized()
        var distance := diff.length()
        var speed: float = entry["speed"]
        if distance > 7.5:
            body.velocity.x = move_toward(body.velocity.x,destination.x*speed,delta*8)
            body.velocity.z = move_toward(body.velocity.z,destination.z*speed,delta*8)
        else:
            body.velocity.x = move_toward(body.velocity.x,0,delta*5)
            body.velocity.z = move_toward(body.velocity.z,0,delta*5)
        if not body.is_on_floor():
            body.velocity.y -= 21*delta
        else:
            body.velocity.y = -.25
        body.move_and_slide()
        if body.is_on_wall():
            body.velocity.y = 5.0 if body.is_on_floor() else body.velocity.y
            entry["think"] = 0.0
        if distance > .3:
            var desired_angle := atan2(destination.x,destination.z)
            body.rotation.y = lerp_angle(body.rotation.y,desired_angle,delta*7.0)
        var walking := body.velocity.length() > 1.5 and distance > 7.5
        _play(entry,"Walking" if walking else "Idle")
        if float(entry["cooldown"]) <= 0 and distance < 22 and distance > .5:
            var target := _best_target(entry)
            if target != null and _has_sight(body,target):
                entry["cooldown"] = _rng.randf_range(1.4,2.6)
                if target == hero:
                    player_tagged.emit()
                else:
                    _tag(target, int(entry["team"]))
    # Opponents are dynamic 3D colliders. Camera ray from player can tag them.

func _tag(body: Node3D, scoring_team: int) -> bool:
    if round_over:
        return false
    for entry in roster:
        if entry["body"] != body or not bool(entry["alive"]):
            continue
        if int(entry["team"]) == scoring_team:
            return false
        entry["alive"] = false
        entry["respawn"] = RESPAWN_DELAY
        var actor: CharacterBody3D = entry["body"]
        actor.visible = false
        actor.collision_layer = 0
        actor.velocity = Vector3.ZERO
        if scoring_team == 0:
            cyan_score += 1
        else:
            magenta_score += 1
        score_changed.emit(cyan_score,magenta_score)
        if cyan_score >= WIN_SCORE or magenta_score >= WIN_SCORE:
            _end_round(scoring_team)
        return true
    return false

func tag_from_player(hit_object: Object) -> bool:
    if not hit_object is Node3D:
        return false
    return _tag(hit_object as Node3D,0)

func _end_round(winner: int) -> void:
    if round_over:
        return
    round_over = true
    round_finished.emit(winner)

func player_lost_shield() -> void:
    if round_over:
        return
    magenta_score += 1
    score_changed.emit(cyan_score,magenta_score)
    if magenta_score >= WIN_SCORE:
        _end_round(1)

func count_bots() -> int:
    return roster.size()

func count_visible_rivals() -> int:
    var n := 0
    for bot in roster:
        if int(bot["team"]) == 1 and bool(bot["alive"]):
            n += 1
    return n
