extends Node3D
## Native Godot 4 mobile 3D foundation. Distinct from legacy HTML game.
## Goal: fluid movement, touch / gamepad, render settings and real lit 3D level.
const HUD = preload("res://scripts/hud.gd")
const ARENAS = preload("res://scripts/arenas.gd")
const NETWORK = preload("res://scripts/network_monitor.gd")
const BOTS = preload("res://scripts/bots.gd")
const AUDIO = preload("res://scripts/audio_fx.gd")

var hero: CharacterBody3D
var camera: Camera3D
var sun: DirectionalLight3D
var atmosphere: Environment
var hud
var arena
var net
var bots
var audio_fx
var scanner: Node3D
var pulse_requested := false
var recharge_requested := false
var pulse_cooldown := 0.0
var recharge_remaining := 0.0
var shield := 100
var energy := 24
const ENERGY_MAX := 24
var next_round := -1.0
var actor_quality := 1
var map_index := 0
var heading := 0.0
var elevation := 0.0
var jump_queued := false
var action_queued := false
var last_jump := false
var elapsed := 0.0
var collected := 0
var beacons: Array[Node3D] = []
var batches := {}
var palette := {}
var ground_level := 0.0

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if OS.has_feature("android"):
        DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
    print("TEAMCS_RENDER_DRIVER: ", RenderingServer.get_current_rendering_driver_name(), " / ", RenderingServer.get_current_rendering_method())
    _setup_palette()
    _setup_lighting()
    arena = ARENAS.new()
    add_child(arena)
    arena.configure(sun, atmosphere)
    arena.load_arena(0)
    _make_hero()
    audio_fx = AUDIO.new()
    add_child(audio_fx)
    net = NETWORK.new()
    add_child(net)
    bots = BOTS.new()
    add_child(bots)
    bots.score_changed.connect(func(_blue: int,_red: int): _update_match_hud())
    bots.player_tagged.connect(_on_player_tagged)
    bots.round_finished.connect(_on_round_finished)
    _make_scanner()
    hud = HUD.new()
    add_child(hud)
    hud.jump_requested.connect(func(): jump_queued = true)
    hud.action_requested.connect(func(): action_queued = true)
    hud.pulse_requested.connect(func(): pulse_requested = true)
    hud.recharge_requested.connect(func(): recharge_requested = true)
    hud.graphics_changed.connect(_apply_graphics)
    hud.graphics_advanced_changed.connect(_apply_advanced_graphics)
    hud.network_mode_changed.connect(net.set_smart_mode)
    net.status_changed.connect(func(_desc: String): hud.set_network_info(net.get_network_text(), net.get_ping_text()))
    hud.map_requested.connect(switch_map)
    hud.configure_maps(arena.maps)
    switch_map(0)
    # Restore saved Low / High / Ultra and network preferences, not hardcoded Ultra.
    hud._emit_graphics()
    hud.set_network_info(net.get_network_text(), net.get_ping_text())
    hud.set_message("MECZ 4 × 4: PULS ⚡ / ŁADUJ ↻   •   RUCH: LEWY DRĄŻEK   •   CELOWANIE: PRAWY", 6.0)
    print("TEAMCS_MATCH_READY: native Godot 4v4 actor_count=",bots.count_bots()," map_count=",arena.maps.size())

func _setup_palette() -> void:
    var colors := {
        "asphalt": Color(0.12, 0.19, 0.24), "paving": Color(0.43, 0.44, 0.40),
        "stone": Color(0.66, 0.58, 0.44), "sand": Color(0.78, 0.68, 0.49),
        "ochre": Color(0.62, 0.37, 0.24), "cream": Color(0.84, 0.76, 0.62),
        "roof": Color(0.25, 0.27, 0.30), "iron": Color(0.12, 0.17, 0.23),
        "glass": Color(0.25, 0.51, 0.61), "teal": Color(0.08, 0.54, 0.55),
        "gold": Color(1.00, 0.69, 0.30), "copper": Color(0.49, 0.27, 0.16),
        "foliage": Color(0.12, 0.31, 0.23), "dirt": Color(0.32, 0.30, 0.25),
        "white": Color(0.91, 0.88, 0.74)
    }
    for key in colors:
        var mat := StandardMaterial3D.new()
        mat.albedo_color = colors[key]
        mat.roughness = 0.77 if key != "glass" else 0.23
        mat.metallic = 0.72 if key == "iron" else 0.2 if key == "copper" else 0.0
        if key == "gold" or key == "teal":
            mat.emission_enabled = true
            mat.emission = colors[key]
            mat.emission_energy_multiplier = 0.35
        # Tile real CC0 photogrammetric PBR materials over world-space objects.
        var material_ids := {
            "asphalt": ["asphalt_01", .55],
            "paving": ["cobblestone_pavement", .32],
            "stone": ["painted_plaster_wall", .27],
            "cream": ["painted_plaster_wall", .29],
            "sand": ["painted_plaster_wall", .32],
            "ochre": ["red_brick", .24],
            "copper": ["red_brick", .41],
        }
        if material_ids.has(key):
            var meta: Array = material_ids[key]
            var prefix: String = "res://assets/" + str(meta[0])
            var diffuse := prefix + "_diff.jpg"
            var normal := prefix + "_normal.jpg"
            if ResourceLoader.exists(diffuse):
                mat.albedo_texture = load(diffuse)
                mat.albedo_color = Color(1, 1, 1, 1) if key in ["asphalt","paving"] else colors[key].lightened(.25)
                mat.uv1_triplanar = true
                mat.uv1_world_triplanar = true
                var scale: float = meta[1]
                mat.uv1_scale = Vector3(scale, scale, scale)
                if ResourceLoader.exists(normal):
                    mat.normal_enabled = true
                    mat.normal_texture = load(normal)
                    mat.normal_scale = 1.2
        palette[key] = mat

func _setup_lighting() -> void:
    var world := WorldEnvironment.new()
    atmosphere = Environment.new()
    atmosphere.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var procedural := ProceduralSkyMaterial.new()
    procedural.sky_top_color = Color(0.10, 0.25, 0.47)
    procedural.sky_horizon_color = Color(0.48, 0.60, 0.69)
    procedural.ground_bottom_color = Color(0.23, 0.23, 0.22)
    procedural.ground_horizon_color = Color(0.55, 0.47, 0.37)
    sky.sky_material = procedural
    atmosphere.sky = sky
    atmosphere.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    atmosphere.reflected_light_source = Environment.REFLECTION_SOURCE_BG
    atmosphere.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    atmosphere.ambient_light_energy = .67
    atmosphere.fog_enabled = true
    atmosphere.fog_light_color = Color(0.70, 0.59, 0.48)
    atmosphere.fog_density = 0.0027
    world.environment = atmosphere
    add_child(world)
    sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-44, -34, -10)
    sun.light_color = Color(1.0, 0.89, 0.72)
    sun.light_energy = 1.38
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 65.0
    add_child(sun)

func _box(p: Vector3, size: Vector3, material: String, solid := false) -> void:
    if not batches.has(material):
        batches[material] = []
    batches[material].append(Transform3D(Basis.IDENTITY.scaled(size), p))
    if solid:
        var body := StaticBody3D.new()
        body.position = p
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        body.add_child(collision)
        add_child(body)

func _flush_batches() -> void:
    for key in batches:
        var transforms: Array = batches[key]
        if transforms.is_empty():
            continue
        var multi := MultiMesh.new()
        multi.transform_format = MultiMesh.TRANSFORM_3D
        var unit := BoxMesh.new()
        unit.size = Vector3.ONE
        multi.mesh = unit
        multi.instance_count = transforms.size()
        for i in range(transforms.size()):
            multi.set_instance_transform(i, transforms[i])
        var instance := MultiMeshInstance3D.new()
        instance.multimesh = multi
        instance.material_override = palette[key]
        add_child(instance)
    batches.clear()

func _facade(side: int, block: int, seed: int) -> void:
    var z := -52.0 + block * 18.0
    var x := side * 16.5
    var height := 8.0 + float((seed * 3) % 5)
    var width := 13.7
    var finish: String = ["stone", "cream", "ochre", "sand"][seed % 4]
    _box(Vector3(x, height * 0.5, z), Vector3(6, height, width), finish, true)
    # Cornice, roof band, masonry courses and windows.
    _box(Vector3(x - side * 0.1, height + 0.25, z), Vector3(7, 0.48, width + 0.6), "roof")
    for level in range(1, int(height / 2.5)):
        var yy := float(level) * 2.25
        _box(Vector3(x - side * 3.07, yy + 0.95, z), Vector3(0.22, 0.12, width + 0.35), "cream")
        for bay in range(4):
            var zz := z - 4.8 + bay * 3.1
            var wx := x - side * 3.08
            _box(Vector3(wx, yy, zz), Vector3(0.14, 1.45, 1.35), "iron")
            _box(Vector3(wx - side * .09, yy, zz), Vector3(0.08, 1.10, 1.08), "glass")
            _box(Vector3(wx - side * .15, yy, zz), Vector3(.10, 1.2, .085), "cream")
            _box(Vector3(wx - side * .15, yy, zz), Vector3(.10, .09, 1.18), "cream")
            _box(Vector3(wx - side * .15, yy - .78, zz), Vector3(.3, .18, 1.6), "stone")
        if level == 2:
            _box(Vector3(x - side * 3.9, yy - 1.00, z), Vector3(1.45, .19, width - .85), "iron")
            _box(Vector3(x - side * 4.58, yy - .40, z), Vector3(.09, 1.04, width - 1.15), "iron")
    # Ground-level arcades with trim and signage.
    for bay in range(3):
        var zz := z - 4.35 + bay * 4.4
        _box(Vector3(x - side * 3.10, 1.75, zz), Vector3(.15, 3.35, 2.80), "iron")
        _box(Vector3(x - side * 3.21, 1.85, zz), Vector3(.09, 2.80, 2.25), "glass")
        _box(Vector3(x - side * 3.30, 3.6, zz), Vector3(.17, .21, 3.18), "sand")
    _box(Vector3(x - side * 3.9, 3.93, z), Vector3(1.5, .18, width - 1.0), "roof")

func _street_lamp(x: float, z: float) -> void:
    _box(Vector3(x, 2.9, z), Vector3(.14, 5.8, .14), "iron")
    _box(Vector3(x + signf(-x) * .45, 5.6, z), Vector3(1, .13, .18), "iron")
    var light := OmniLight3D.new()
    light.position = Vector3(x + signf(-x) * .90, 5.55, z)
    light.light_color = Color(1.0, .80, .51)
    light.light_energy = 1.6
    light.omni_range = 7.5
    light.shadow_enabled = false
    add_child(light)
    _box(Vector3(x + signf(-x) * .93, 5.55, z), Vector3(.29, .18, .32), "gold")

func _make_city() -> void:
    _box(Vector3(0, -0.50, -8), Vector3(130, 1, 150), "dirt", true)
    _box(Vector3(0, -.020, -9), Vector3(17, .065, 105), "asphalt")
    for side in [-1, 1]:
        var sx := float(side)
        _box(Vector3(sx * 10.25, 0.025, -9), Vector3(3.6, .14, 107), "paving")
        _box(Vector3(sx * 8.50, .090, -9), Vector3(.20, .19, 107), "stone")
        for block in range(5):
            _facade(side, block, block * 7 + (0 if side == 1 else 2))
        for z in [-50.0, -30.0, -10.0, 10.0, 30.0]:
            _street_lamp(sx * 9.4, z)
            _box(Vector3(sx * 8.9, .24, z + 3.1), Vector3(.95, .46, 2.2), "stone", true)
            _box(Vector3(sx * 8.9, .55, z + 3.1), Vector3(.84, .24, 1.94), "foliage")
    # Inlaid pavement, median, obstacles, street props.
    for i in range(44):
        var z := -59.0 + i * 2.3
        _box(Vector3(-.20, -.007, z), Vector3(.14, .005, .80), "cream")
        if i % 6 == 0:
            _box(Vector3(-7.0, .010, z), Vector3(.21, .025, 2.4), "paving")
            _box(Vector3(7.0, .010, z), Vector3(.21, .025, 2.4), "paving")
    for i in range(5):
        var zz := -45.0 + float(i * 15)
        var xx := -3.7 if i % 2 == 0 else 3.7
        _box(Vector3(xx, .52, zz), Vector3(1.8, 1.05, 2.2), "copper", true)
        _box(Vector3(xx, 1.12, zz), Vector3(2.1, .16, 2.5), "roof")
        _box(Vector3(xx, .55, zz + 1.13), Vector3(.15, .4, 1.9), "iron")
    _flush_batches()
    for location in [Vector3(-4, 0.9, -12), Vector3(4, .9, -30), Vector3(-3, .9, -47), Vector3(6, .9, 10)]:
        _make_beacon(location)

func _make_beacon(p: Vector3) -> void:
    var anchor := Node3D.new()
    anchor.position = p
    add_child(anchor)
    var ring := MeshInstance3D.new()
    var shape := TorusMesh.new()
    shape.inner_radius = .45
    shape.outer_radius = .57
    ring.mesh = shape
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(.10, .88, 1.0)
    material.metallic = .35
    material.roughness = .22
    material.emission_enabled = true
    material.emission = Color(.08, .75, 1.0)
    material.emission_energy_multiplier = 3.0
    ring.material_override = material
    ring.rotation_degrees.x = 90
    anchor.add_child(ring)
    var orb := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = .22
    sphere.height = .44
    orb.mesh = sphere
    orb.material_override = material
    anchor.add_child(orb)
    var lamp := OmniLight3D.new()
    lamp.light_color = Color(.1, .79, 1.0)
    lamp.omni_range = 3.0
    lamp.light_energy = 1.5
    anchor.add_child(lamp)
    beacons.append(anchor)

func switch_map(index: int) -> void:
    map_index = posmod(index, arena.maps.size())
    arena.load_arena(map_index)
    for item in beacons:
        if is_instance_valid(item):
            item.queue_free()
    beacons.clear()
    collected = 0
    shield = 100
    energy = ENERGY_MAX
    pulse_cooldown = 0.0
    recharge_remaining = 0.0
    next_round = -1.0
    for pos in [Vector3(-15,.95,-12),Vector3(15,.95,-12),Vector3(-12,.95,14),Vector3(14,.95,13)]:
        _make_beacon(pos)
    if is_instance_valid(hero):
        hero.velocity = Vector3.ZERO
        var authored_spawn: Vector3 = arena.spawn_position()
        hero.global_position = authored_spawn
        hero.rotation = Vector3.ZERO
        # Aim across the level from the faction spawn, not into nearby cover.
        heading = atan2(authored_spawn.x, authored_spawn.z)
    else:
        heading = 0.0
    elevation = -.10
    if is_instance_valid(bots):
        bots.new_round(arena.current_map,arena,hero)
    if is_instance_valid(hud):
        arena.apply_advanced(hud.texture_toggle.button_pressed,hud.detail_select.selected)
        bots.apply_actor_quality(hud.actor_select.selected)
        hud.set_map(map_index, str(arena.current_map.get("name", "ARENA")))
        _update_match_hud()

func _make_hero() -> void:
    hero = CharacterBody3D.new()
    hero.position = Vector3(0, 1.8, 21)
    var capsule := CapsuleShape3D.new()
    capsule.radius = .42
    capsule.height = 1.80
    var shape := CollisionShape3D.new()
    shape.shape = capsule
    shape.position.y = .92
    hero.add_child(shape)
    camera = Camera3D.new()
    camera.position = Vector3(0, 1.54, 0)
    camera.current = true
    camera.fov = 76.0
    camera.far = 190.0
    hero.add_child(camera)
    add_child(hero)

func _physics_process(delta: float) -> void:
    elapsed += delta
    pulse_cooldown = maxf(0.0,pulse_cooldown-delta)
    if recharge_remaining > 0.0:
        recharge_remaining = maxf(0.0,recharge_remaining-delta)
        if recharge_remaining == 0.0:
            energy = ENERGY_MAX
            hud.set_message("ENERGIA UZUPEŁNIONA  •  GOTOWOŚĆ",1.1)
    if next_round > 0.0:
        next_round -= delta
        if next_round <= 0.0:
            switch_map(map_index)
    if recharge_requested or Input.is_physical_key_pressed(KEY_R):
        _recharge()
    recharge_requested = false
    var pulse_held: bool = bool(hud.pulse_held) or Input.is_physical_key_pressed(KEY_F)
    if not Input.get_connected_joypads().is_empty():
        var current_pad := Input.get_connected_joypads()[0]
        pulse_held = pulse_held or Input.get_joy_axis(current_pad,JOY_AXIS_TRIGGER_RIGHT) > .75
    if (pulse_requested or pulse_held) and not hud.settings_open:
        _emit_pulse()
    pulse_requested = false
    if not is_instance_valid(hero):
        return
    var movement := Vector2.ZERO
    if Input.is_physical_key_pressed(KEY_A):
        movement.x -= 1
    if Input.is_physical_key_pressed(KEY_D):
        movement.x += 1
    if Input.is_physical_key_pressed(KEY_W):
        movement.y -= 1
    if Input.is_physical_key_pressed(KEY_S):
        movement.y += 1
    movement += hud.touch_move
    var pad_connected := not Input.get_connected_joypads().is_empty()
    if pad_connected:
        var joy := Input.get_connected_joypads()[0]
        var stick := Vector2(Input.get_joy_axis(joy, JOY_AXIS_LEFT_X), Input.get_joy_axis(joy, JOY_AXIS_LEFT_Y))
        if stick.length() > hud.pad_deadzone:
            movement += stick
        var look_stick := Vector2(Input.get_joy_axis(joy, JOY_AXIS_RIGHT_X), Input.get_joy_axis(joy, JOY_AXIS_RIGHT_Y))
        if look_stick.length() > hud.pad_deadzone and not hud.settings_open:
            _turn(look_stick * 850.0 * delta)
        var jumping := Input.is_joy_button_pressed(joy, JOY_BUTTON_A)
        if jumping and not last_jump:
            jump_queued = true
        last_jump = jumping
        if Input.is_joy_button_pressed(joy, JOY_BUTTON_X):
            action_queued = true
    var touch_look: Vector2 = hud.consume_look()
    if not hud.settings_open:
        _turn(touch_look)
    movement = movement.limit_length(1)
    var forward := Vector3(-sin(heading), 0, -cos(heading))
    var right := Vector3(cos(heading), 0, -sin(heading))
    var desired := (right * movement.x - forward * movement.y) * (8.7 if hud.sprint_enabled else 5.4)
    hero.velocity.x = move_toward(hero.velocity.x, desired.x, 18.0 * delta)
    hero.velocity.z = move_toward(hero.velocity.z, desired.z, 18.0 * delta)
    if not hero.is_on_floor():
        hero.velocity.y -= 24.0 * delta
    elif jump_queued:
        hero.velocity.y = 8.5
    jump_queued = false
    hero.move_and_slide()
    camera.rotation.x = elevation
    hero.rotation.y = heading
    for i in range(beacons.size()):
        var b := beacons[i]
        if not is_instance_valid(b):
            continue
        b.rotation.y += delta * .72
        b.position.y = .92 + sin(elapsed * 2.8 + float(i)) * .14
    if action_queued:
        _collect_beacon()
    action_queued = false
    hud.set_status(collected, beacons.size(), hero.global_position)
    if is_instance_valid(scanner):
        scanner.position.y = -.45 + sin(elapsed * 9) * .008 * minf(hero.velocity.length()/5.,1.)
    _update_match_hud()

func _turn(relative: Vector2) -> void:
    if relative == Vector2.ZERO:
        return
    var sensitivity: float = hud.look_sensitivity if is_instance_valid(hud) else 1.0
    heading -= relative.x * .0030 * sensitivity
    elevation = clampf(elevation + relative.y * .0030 * sensitivity * (1.0 if hud.invert_look_y else -1.0), -1.35, 1.26)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not hud.settings_open:
        _turn(event.relative)
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not hud.settings_open and not OS.has_feature("mobile"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        pulse_requested = true
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_ESCAPE:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
            hud.toggle_settings()
        if event.keycode == KEY_SPACE:
            jump_queued = true
        if event.keycode == KEY_E:
            action_queued = true
        if event.keycode == KEY_F:
            pulse_requested = true
        if event.keycode == KEY_R:
            recharge_requested = true

func _make_scanner() -> void:
    # Camera-space wearable future-energy wrist device.
    # Reads like a polished game HUD prop, not a giant floating blob.
    scanner = Node3D.new()
    scanner.name = "WristEnergyEmitter"
    scanner.position = Vector3(.55,-.49,-.92)
    scanner.rotation_degrees = Vector3(4,-10,-7)
    camera.add_child(scanner)

    var armour := StandardMaterial3D.new()
    armour.albedo_color = Color(.13,.18,.22)
    armour.metallic = .55
    armour.roughness = .42
    var dark := StandardMaterial3D.new()
    dark.albedo_color = Color(.025,.036,.049)
    dark.metallic = .72
    dark.roughness = .25
    var glove := StandardMaterial3D.new()
    glove.albedo_color = Color(.20,.24,.29)
    glove.roughness = .87
    var cyan := StandardMaterial3D.new()
    cyan.albedo_color = Color(.16,.83,.93)
    cyan.metallic = .35
    cyan.roughness = .24
    cyan.emission_enabled = true
    cyan.emission = Color(.07,.67,.97)
    cyan.emission_energy_multiplier = 1.2

    # Device floats with the glove/forearm, partially cropped by screen edge.
    for spec in [
        [Vector3(.07,-.26,.23),Vector3(.28,.35,.50),glove],
        [Vector3(.045,-.145,.03),Vector3(.25,.20,.42),armour],
        [Vector3(-.01,-.01,-.20),Vector3(.28,.18,.53),dark],
        [Vector3(-.015,.068,-.18),Vector3(.23,.045,.42),armour],
        [Vector3(-.015,.10,-.18),Vector3(.17,.015,.29),cyan],
        [Vector3(-.19,-.035,-.27),Vector3(.056,.115,.38),armour],
        [Vector3(.19,-.035,-.27),Vector3(.056,.115,.38),armour],
        [Vector3(-.19,.04,-.38),Vector3(.08,.033,.10),cyan],
        [Vector3(.19,.04,-.38),Vector3(.08,.033,.10),cyan],
    ]:
        var piece := MeshInstance3D.new()
        var cube := BoxMesh.new()
        cube.size = spec[1]
        piece.mesh = cube
        piece.position = spec[0]
        piece.material_override = spec[2]
        scanner.add_child(piece)
    var aperture := MeshInstance3D.new()
    var ring := TorusMesh.new()
    ring.inner_radius = .105
    ring.outer_radius = .128
    ring.rings = 9
    ring.ring_segments = 18
    aperture.mesh = ring
    aperture.position = Vector3(0,.012,-.53)
    aperture.rotation.x = PI * .5
    aperture.material_override = cyan
    scanner.add_child(aperture)
    var face := MeshInstance3D.new()
    var glass := SphereMesh.new()
    glass.radius = .086
    glass.height = .17
    face.mesh = glass
    face.scale = Vector3(.94,.94,.32)
    face.position = Vector3(0,.012,-.55)
    face.material_override = dark
    scanner.add_child(face)


func _recharge() -> void:
    if energy == ENERGY_MAX or recharge_remaining > 0.0:
        return
    recharge_remaining = 1.55
    if is_instance_valid(audio_fx):
        audio_fx.play_effect("recharge")
    hud.set_message("UZUPEŁNIANIE ENERGII…",1.5)

func _emit_pulse() -> void:
    if pulse_cooldown > 0.0 or recharge_remaining > 0.0 or bots.round_over:
        return
    if energy <= 0:
        _recharge()
        return
    pulse_cooldown = .19
    energy -= 1
    if is_instance_valid(audio_fx):
        audio_fx.play_effect("pulse")
    if is_instance_valid(scanner):
        var swing := create_tween()
        swing.tween_property(scanner,"rotation_degrees:x",-3.0,.045)
        swing.tween_property(scanner,"rotation_degrees:x",4.0,.125)
    var start := camera.global_position
    var end := start - camera.global_transform.basis.z * 74.0
    var query := PhysicsRayQueryParameters3D.create(start,end,1|4,[hero.get_rid()])
    var result := get_world_3d().direct_space_state.intersect_ray(query)
    if not result.is_empty():
        end = result["position"]
        if bots.tag_from_player(result["collider"]):
            if is_instance_valid(audio_fx):
                audio_fx.play_effect("tag")
            hud.set_message("PUNKT DLA CYAN!  +1",1.2)
    _pulse_visual(start+(-camera.global_transform.basis.z)*.42,end)
    if energy == 0:
        _recharge()

func _pulse_visual(start: Vector3, finish: Vector3) -> void:
    var segment := finish-start
    if segment.length() < .1:
        return
    var light_mat := StandardMaterial3D.new()
    light_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    light_mat.albedo_color = Color(.34,.96,1.,.95)
    light_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    var beam := MeshInstance3D.new()
    var tube := CylinderMesh.new()
    tube.bottom_radius = .018
    tube.top_radius = .018
    tube.height = segment.length()
    tube.radial_segments = 7
    beam.mesh = tube
    beam.material_override = light_mat
    add_child(beam)
    beam.global_position = (start+finish)*.5
    beam.quaternion = Quaternion(Vector3.UP,segment.normalized())
    var tween := create_tween()
    tween.tween_interval(.085)
    tween.tween_callback(beam.queue_free)

func _on_player_tagged() -> void:
    shield = maxi(0,shield-24)
    if is_instance_valid(audio_fx):
        audio_fx.play_effect("shield")
    if shield <= 0:
        bots.player_lost_shield()
        hero.global_position = arena.spawn_position()
        hero.velocity = Vector3.ZERO
        shield = 100
        energy = ENERGY_MAX
        hud.set_message("OSŁONA ODNOWIONA  •  POWRÓT DO MECZU",2.)

func _on_round_finished(winner: int) -> void:
    var result_text := "CYAN WYGRYWA  •  RUNDA ZAKOŃCZONA" if winner == 0 else "MAGENTA WYGRYWA  •  RUNDA ZAKOŃCZONA"
    hud.set_message(result_text,5.)
    next_round = 5.0

func _update_match_hud() -> void:
    if is_instance_valid(hud) and is_instance_valid(bots):
        hud.set_combat_state(bots.cyan_score,bots.magenta_score,shield,energy,ENERGY_MAX,bots.time_left)

func _collect_beacon() -> void:
    var closest: Node3D = null
    var dist := 2.4
    for b in beacons:
        if not is_instance_valid(b):
            continue
        var d := b.global_position.distance_to(hero.global_position + Vector3(0, 1, 0))
        if d < dist:
            closest = b
            dist = d
    if closest != null:
        beacons.erase(closest)
        closest.queue_free()
        collected += 1
        hud.set_message("ZNACZNIK ZDOBYTY!  %d / 4" % collected, 2.5)
    else:
        hud.set_message("PODEJDŹ BLIŻEJ ŚWIECĄCEGO ZNACZNIKA", 2.0)

func _apply_advanced_graphics(textured: bool, detail: int, actor_lod: int) -> void:
    actor_quality = actor_lod
    arena.apply_advanced(textured, detail)
    if is_instance_valid(bots):
        bots.apply_actor_quality(actor_lod)

func _apply_graphics(profile: int, fps: int, scale: float, shadows: bool, aa: int) -> void:
    Engine.max_fps = fps
    var viewport := get_viewport()
    viewport.scaling_3d_scale = clampf(scale, .60, 1.0)
    viewport.msaa_3d = Viewport.MSAA_DISABLED if aa == 0 else Viewport.MSAA_2X if aa == 2 else Viewport.MSAA_4X
    sun.shadow_enabled = shadows
    atmosphere.glow_enabled = profile == 2
    if profile == 0: # Fast
        viewport.scaling_3d_scale = minf(scale, .75)
        sun.shadow_enabled = false
        atmosphere.fog_enabled = false
    elif profile == 1: # Balanced
        atmosphere.fog_enabled = true
    else: # Ultra
        atmosphere.fog_enabled = true
    if is_instance_valid(hud):
        hud.set_message("GRAFIKA: %s  •  CEL: %d FPS" % [["PŁYNNOŚĆ", "WYSOKA", "ULTRA"][profile], fps], 2.3)
