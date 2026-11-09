extends Node3D
## One-draw-call, camera-local weather: subtle snow, neon rain and drifting leaves.
## Deliberately original procedural visuals; no downloaded assets or per-flake nodes.
## Weather only changes scenery. Collisions, combat and other game systems are untouched.

var tracked: Node3D
var effect_name := "none"
var quality := 1
var batch: MultiMeshInstance3D
var multi: MultiMesh
var particle_positions: Array[Vector3] = []
var particle_velocity: Array[float] = []
var particle_seed: Array[float] = []
var active_count := 0
var animation_clock := 0.0
var local_rng := RandomNumberGenerator.new()

func _ready() -> void:
    local_rng.seed = 17942018
    batch = MultiMeshInstance3D.new()
    batch.name = "SingleBatchWeather"
    # MultiMesh keeps the complete rain/snow/leaves layer to a single GPU draw.
    multi = MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.instance_count = 0
    batch.multimesh = multi
    batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    batch.visible = false
    add_child(batch)

func setup_for_map(map_id: String, target: Node3D, detail: int) -> void:
    tracked = target
    quality = clampi(detail,0,2)
    if map_id == "alpine":
        effect_name = "snow"
    elif map_id in ["neon","skyline"]:
        effect_name = "rain"
    elif map_id in ["port","oldtown"]:
        effect_name = "leaves"
    elif map_id == "dunes":
        effect_name = "dust"
    else:
        effect_name = "none"
    _rebuild()

func set_detail(detail: int) -> void:
    quality = clampi(detail,0,2)
    _rebuild()

func _rebuild() -> void:
    if not is_instance_valid(batch):
        return
    particle_positions.clear()
    particle_velocity.clear()
    particle_seed.clear()
    var amount := 0
    if effect_name != "none" and quality > 0:
        amount = 28 if quality == 1 else 74
    active_count = amount
    multi.instance_count = 0
    batch.visible = amount > 0
    if amount == 0:
        return
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    if effect_name == "snow":
        mat.albedo_color = Color(.91,.97,1.0,.72)
    elif effect_name == "rain":
        mat.albedo_color = Color(.50,.78,.92,.32)
    elif effect_name == "leaves":
        mat.albedo_color = Color(.89,.53,.24,.70)
    else:
        mat.albedo_color = Color(.93,.75,.43,.29)
    var mesh := BoxMesh.new()
    if effect_name == "rain":
        mesh.size = Vector3(.016,.43,.014)
    elif effect_name == "snow":
        mesh.size = Vector3(.069,.067,.065)
    elif effect_name == "leaves":
        mesh.size = Vector3(.12,.024,.068)
    else:
        mesh.size = Vector3(.045,.045,.047)
    mesh.material = mat
    multi.mesh = mesh
    multi.instance_count = amount
    for i in range(amount):
        particle_positions.append(Vector3(local_rng.randf_range(-13.,13.),local_rng.randf_range(-1.5,10.5),local_rng.randf_range(-13.,13.)))
        particle_velocity.append(local_rng.randf_range(.78,1.36))
        particle_seed.append(local_rng.randf_range(0.,TAU))
        multi.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(0,-100,0)))

func _process(delta: float) -> void:
    if active_count <= 0 or not is_instance_valid(tracked):
        return
    animation_clock += delta
    var center := tracked.global_position
    for i in range(active_count):
        var p: Vector3 = particle_positions[i]
        var seed: float = particle_seed[i]
        var speed: float = particle_velocity[i]
        if effect_name == "rain":
            p.y -= delta * (9.0+speed*3.0)
            p.x += delta * 1.1
        elif effect_name == "snow":
            p.y -= delta * (1.0+speed*.65)
            p.x += sin(animation_clock*.85+seed)*delta*.45
        elif effect_name == "leaves":
            p.y -= delta * (.27+speed*.2)
            p.x += sin(animation_clock*.7+seed)*delta*.88
            p.z += cos(animation_clock*.55+seed)*delta*.35
        else:
            p.y -= delta * (.15+speed*.16)
            p.x += delta*(.28+sin(seed)*.19)
        if p.y < -1.3:
            p.y = local_rng.randf_range(8.0,11.8)
            p.x = local_rng.randf_range(-13.,13.)
            p.z = local_rng.randf_range(-13.,13.)
        if p.x > 15:
            p.x -= 30.
        particle_positions[i] = p
        var spin := 0.0 if effect_name == "rain" else animation_clock*(.7+speed*.3)+seed
        var transform_basis := Basis(Vector3.UP,spin)
        var position := center + p
        # Avoid precipitation covering the first-person camera at close range.
        if p.length_squared() < .45:
            position.y = -100.
        multi.set_instance_transform(i,Transform3D(transform_basis,position))
