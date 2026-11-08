extends Node3D
## Native Godot 4 mobile 3D foundation. Distinct from legacy HTML game.
## Goal: fluid movement, touch / gamepad, render settings and real lit 3D level.
const HUD = preload("res://scripts/hud.gd")

var hero: CharacterBody3D
var camera: Camera3D
var sun: DirectionalLight3D
var atmosphere: Environment
var hud
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
    _setup_palette()
    _setup_lighting()
    _make_city()
    _make_hero()
    hud = HUD.new()
    add_child(hud)
    hud.jump_requested.connect(func(): jump_queued = true)
    hud.action_requested.connect(func(): action_queued = true)
    hud.graphics_changed.connect(_apply_graphics)
    _apply_graphics(2, 120, 1.0, true, 2)
    hud.set_message("DOTYK: LEWY DRĄŻEK + PRZECIĄGNIJ PO PRAWEJ  |  PAD: L / R", 6.0)

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
        palette[key] = mat

func _setup_lighting() -> void:
    var world := WorldEnvironment.new()
    atmosphere = Environment.new()
    atmosphere.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var procedural := ProceduralSkyMaterial.new()
    procedural.sky_top_color = Color(0.10, 0.25, 0.47)
    procedural.sky_horizon_color = Color(0.80, 0.57, 0.39)
    procedural.ground_bottom_color = Color(0.23, 0.23, 0.22)
    procedural.ground_horizon_color = Color(0.55, 0.47, 0.37)
    sky.sky_material = procedural
    atmosphere.sky = sky
    atmosphere.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    atmosphere.reflected_light_source = Environment.REFLECTION_SOURCE_BG
    atmosphere.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    atmosphere.fog_enabled = true
    atmosphere.fog_light_color = Color(0.70, 0.59, 0.48)
    atmosphere.fog_density = 0.007
    world.environment = atmosphere
    add_child(world)
    sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-44, -34, -10)
    sun.light_color = Color(1.0, 0.89, 0.72)
    sun.light_energy = 2.4
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
        if stick.length() > .16:
            movement += stick
        var look_stick := Vector2(Input.get_joy_axis(joy, JOY_AXIS_RIGHT_X), Input.get_joy_axis(joy, JOY_AXIS_RIGHT_Y))
        if look_stick.length() > .13 and not hud.settings_open:
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

func _turn(relative: Vector2) -> void:
    if relative == Vector2.ZERO:
        return
    var sensitivity: float = hud.look_sensitivity if is_instance_valid(hud) else 1.0
    heading -= relative.x * .0030 * sensitivity
    elevation = clampf(elevation - relative.y * .0030 * sensitivity, -1.35, 1.26)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not hud.settings_open:
        _turn(event.relative)
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not hud.settings_open:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_ESCAPE:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
            hud.toggle_settings()
        if event.keycode == KEY_SPACE:
            jump_queued = true
        if event.keycode == KEY_E:
            action_queued = true

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

func _apply_graphics(profile: int, fps: int, scale: float, shadows: bool, aa: int) -> void:
    Engine.max_fps = fps
    var viewport := get_viewport()
    viewport.scaling_3d_scale = clampf(scale, .60, 1.0)
    viewport.msaa_3d = Viewport.MSAA_DISABLED if aa == 0 else Viewport.MSAA_2X if aa == 2 else Viewport.MSAA_4X
    sun.shadow_enabled = shadows
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
