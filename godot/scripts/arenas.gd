extends Node3D
## Eight faithful TeamCS arena layouts, visually differentiated by theme and props.
## Static scenery is batched by material using MultiMesh (one draw per material).
## Distinct collision volumes are kept for buildings/cover while detail remains GPU-side.
const MAP_PATH := "res://maps/arenas.json"

var maps: Array = []
var current_index := 0
var current_map: Dictionary = {}
var world: Node3D
var batches: Dictionary = {}
var materials: Dictionary = {}
var sunshine: DirectionalLight3D
var atmosphere: Environment
var scene_lights: Array[OmniLight3D] = []

func _init() -> void:
    var json_text := FileAccess.get_file_as_string(MAP_PATH)
    var parsed = JSON.parse_string(json_text)
    if parsed is Array:
        maps = parsed

func configure(lamp: DirectionalLight3D, sky: Environment) -> void:
    sunshine = lamp
    atmosphere = sky

func load_arena(index: int) -> void:
    if maps.is_empty():
        push_error("TeamCS 3D: no map JSON")
        return
    current_index = posmod(index, maps.size())
    current_map = maps[current_index]
    if is_instance_valid(world):
        remove_child(world)
        world.queue_free()
    world = Node3D.new()
    world.name = str(current_map.get("id", "Arena"))
    add_child(world)
    batches.clear()
    scene_lights.clear()
    _materials()
    _base()
    for raw in current_map.get("obstacles", []):
        _obstacle(raw)
    match str(current_map.get("id", "port")):
        "port": _port()
        "dunes": _dunes()
        "neon": _neon()
        "foundry": _foundry()
        "metro": _metro()
        "alpine": _alpine()
        "oldtown": _oldtown()
        "skyline": _skyline()
    _lighting()
    _flush()

func _material(color: Color, roughness: float = .76, metallic: float = .0, emissive: bool = false) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness
    mat.metallic = metallic
    if emissive:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 1.7
    return mat

func _material_from_photo(mat: StandardMaterial3D, texture_key: String, size: float) -> void:
    var prefix := "res://assets/" + texture_key
    var diffuse := prefix + "_diff.jpg"
    var normal := prefix + "_normal.jpg"
    if not ResourceLoader.exists(diffuse):
        return
    mat.albedo_texture = load(diffuse)
    mat.uv1_triplanar = true
    mat.uv1_world_triplanar = true
    mat.uv1_scale = Vector3.ONE * size
    if ResourceLoader.exists(normal):
        mat.normal_enabled = true
        mat.normal_texture = load(normal)
        mat.normal_scale = 1.0

func _materials() -> void:
    materials = {
        "road": _material(Color(.58,.60,.61)), "pavers": _material(Color(.93,.90,.84)),
        "sand": _material(Color(.89,.79,.61)), "stone": _material(Color(.88,.82,.75)),
        "plaster": _material(Color(.89,.83,.74)), "brick": _material(Color(.77,.55,.46)),
        "steel": _material(Color(.37,.44,.48),.36,.63), "dark": _material(Color(.12,.18,.23),.45,.3),
        "blue": _material(Color(.15,.38,.58),.4,.45), "orange": _material(Color(.72,.37,.21),.52,.25),
        "glass": _material(Color(.35,.66,.78),.13,.45), "snow": _material(Color(.87,.94,1.0)),
        "roof": _material(Color(.27,.24,.25),.61,.15), "wood": _material(Color(.49,.31,.20)),
        "foliage": _material(Color(.16,.40,.28)), "white": _material(Color(.91,.93,.90)),
        "yellow": _material(Color(1.0,.74,.27),.35,.15,true),
        "cyan": _material(Color(.09,.82,1.0),.15,.2,true),
        "magenta": _material(Color(1.0,.13,.60),.15,.2,true),
        "tarmac": _material(Color(.24,.30,.34)), "rail": _material(Color(.27,.34,.40),.3,.75)
    }
    for spec in [
        ["road","asphalt_01", .61], ["tarmac","asphalt_01", .60],
        ["pavers","cobblestone_pavement", .43], ["stone","painted_plaster_wall", .32],
        ["plaster","painted_plaster_wall", .36], ["brick","red_brick", .53],
        ["sand","painted_plaster_wall", .20], ["wood","red_brick", .43]
    ]:
        _material_from_photo(materials[spec[0]], spec[1], float(spec[2]))

func _piece(position: Vector3, dims: Vector3, mat: String) -> void:
    if not batches.has(mat):
        batches[mat] = []
    batches[mat].append(Transform3D(Basis.IDENTITY.scaled(dims), position))

func _solid(position: Vector3, dims: Vector3, mat: String, collision: bool = true) -> void:
    _piece(position,dims,mat)
    if collision:
        var body := StaticBody3D.new()
        body.position = position
        var col := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = dims
        col.shape = shape
        body.add_child(col)
        world.add_child(body)

func _flush() -> void:
    for key in batches.keys():
        var transforms: Array = batches[key]
        if transforms.is_empty():
            continue
        var multi := MultiMesh.new()
        multi.transform_format = MultiMesh.TRANSFORM_3D
        var mesh := BoxMesh.new()
        mesh.size = Vector3.ONE
        multi.mesh = mesh
        multi.instance_count = transforms.size()
        for i in range(transforms.size()):
            multi.set_instance_transform(i, transforms[i])
        var holder := MultiMeshInstance3D.new()
        holder.name = "GPU_Batched_%s" % str(key)
        holder.multimesh = multi
        holder.material_override = materials[key]
        world.add_child(holder)
    batches.clear()

func _base() -> void:
    var id := str(current_map.get("id",""))
    var floor_name := "sand" if id in ["dunes","alpine"] else "pavers" if id == "oldtown" else "road"
    _solid(Vector3(0,-.55,0),Vector3(100,1.0,100),floor_name)
    if id in ["port","foundry","neon","skyline"]:
        for i in range(-7,8):
            _piece(Vector3(float(i)*5.5,-.018,0),Vector3(.065,.021,80),"tarmac")
    if id == "alpine":
        for i in range(15):
            var xx := -47.0 + float(i) * 6.0
            _piece(Vector3(xx, -.008, 42),Vector3(4.5,.05,6),"snow")
    if id in ["metro","skyline"]:
        _piece(Vector3(0,-.019,0),Vector3(15,.06,85),"dark")
    if id == "oldtown":
        for z in range(-39,40,6):
            _piece(Vector3(0,-.015,float(z)),Vector3(15,.03,.13),"stone")

func _obstacle(item: Dictionary) -> void:
    var x := float(item.get("x",0))
    var z := float(item.get("z",0))
    var w := float(item.get("w",4))
    var d := float(item.get("d",4))
    var h := float(item.get("h",4))
    var kind := str(item.get("kind","wall"))
    var base := Vector3(x,h*.5,z)
    var dims := Vector3(w,h,d)
    var id := str(current_map.get("id",""))
    var material := "steel" if kind in ["container","power","platform","barrier"] else "wood" if kind in ["crate","market"] else "stone"
    if id == "alpine":
        material = "snow" if kind in ["building","perimeter","tower"] else material
    if id == "oldtown" and kind in ["building","wall","temple"]:
        material = "plaster"
    if id == "neon" and kind in ["building","perimeter"]:
        material = "dark"
    if id == "foundry" and kind in ["warehouse","station","power"]:
        material = "steel"
    if id == "dunes":
        material = "sand" if kind != "crate" else "wood"
    if kind == "perimeter":
        _piece(base,dims,material)
        return
    _solid(base,dims,material)
    if kind == "container":
        _container(x,z,w,d,h)
    elif kind in ["building","warehouse","tower","temple","station","kiosk"]:
        _building(x,z,w,d,h,material,kind)
    elif kind in ["crate","cover"]:
        _crate(x,z,w,d,h)
    elif kind in ["platform","power"]:
        _industrial(x,z,w,d,h)
    elif kind == "market":
        _market(x,z,w,d,h)

func _container(x: float,z: float,w: float,d: float,h: float) -> void:
    var tint := "blue" if x < 0 else "orange"
    _piece(Vector3(x,h+.07,z),Vector3(w+.26,.14,d+.25),"steel")
    if w >= d:
        for i in range(maxi(2,int(w/.85))):
            var xx := x - w*.5 + (float(i)+.5)*w/maxi(2,int(w/.85))
            _piece(Vector3(xx,h*.55,z+d*.5+.025),Vector3(.05,h*.72,.06),tint)
    else:
        for i in range(maxi(2,int(d/.85))):
            var zz := z-d*.5+(float(i)+.5)*d/maxi(2,int(d/.85))
            _piece(Vector3(x+w*.5+.025,h*.55,zz),Vector3(.06,h*.72,.05),tint)
    for side in [-1,1]:
        _piece(Vector3(x+w*.5*float(side),h*.52,z),Vector3(.12,h-.1,d+.16),"steel")

func _building(x: float,z: float,w: float,d: float,h: float,mat: String,kind: String) -> void:
    var id := str(current_map.get("id",""))
    _piece(Vector3(x,h+.18,z),Vector3(w+.50,.36,d+.50),"roof")
    var windows := mini(7,maxi(2,int(w/2.1)))
    var levels := mini(5,maxi(1,int(h/2.35)))
    for level in range(levels):
        for col in range(windows):
            var wx := x - w*.5 + (float(col)+.5)*w/windows
            var wy := .95 + float(level)*2.0
            for side in [-1,1]:
                var zz := z+float(side)*(d*.5+.027)
                if wy < h-.45:
                    _piece(Vector3(wx,wy,zz),Vector3(.72,1.25,.075),"dark")
                    _piece(Vector3(wx,wy,zz+float(side)*.052),Vector3(.57,1.05,.042),"glass")
                    _piece(Vector3(wx,wy,zz+float(side)*.09),Vector3(.050,1.12,.07),"stone")
                    _piece(Vector3(wx,wy-.62,zz+float(side)*.1),Vector3(1,.13,.19),"plaster")
    if kind in ["tower","temple"]:
        for i in range(6):
            var p := float(i)*TAU/6
            _piece(Vector3(x+cos(p)*w*.46,h+.75,z+sin(p)*d*.46),Vector3(.60,1.2,.60),"stone")
    if id == "neon" or id == "skyline":
        var light_key := "cyan" if int(x+z) % 2 == 0 else "magenta"
        _piece(Vector3(x,h+.41,z),Vector3(w+.2,.08,d+.2),light_key)

func _crate(x: float,z: float,w: float,d: float,h: float) -> void:
    _piece(Vector3(x,h-.16,z),Vector3(w+.17,.17,d+.18),"wood")
    _piece(Vector3(x,h*.5,z+d*.5+.06),Vector3(w+.1,.085,.12),"steel")
    _piece(Vector3(x,h*.5,z-d*.5-.06),Vector3(w+.1,.085,.12),"steel")
    _piece(Vector3(x+w*.5+.06,h*.52,z),Vector3(.12,.09,d+.1),"steel")

func _industrial(x: float,z: float,w: float,d: float,h: float) -> void:
    for side in [-1,1]:
        _piece(Vector3(x+w*.39*float(side),h+.30,z),Vector3(.26,.6,d+.3),"rail")
    for i in range(3):
        var xx := x-w*.5 + (float(i)+.5)*w/3
        _piece(Vector3(xx,h+.65,z),Vector3(.18,.34,d+.22),"steel")

func _market(x: float,z: float,w: float,d: float,h: float) -> void:
    var canopy := "orange" if x > 0 else "blue"
    _piece(Vector3(x,h+.28,z),Vector3(w+.5,.27,d+.5),canopy)
    for xx in [-1,1]:
        for zz in [-1,1]:
            _piece(Vector3(x+float(xx)*w*.45,h*.6,z+float(zz)*d*.45),Vector3(.12,h*.8,.12),"wood")

func _lamp(p: Vector3,tint: Color,range_radius: float = 9.0, strength: float = 1.25) -> void:
    var light := OmniLight3D.new()
    light.position = p
    light.light_color = tint
    light.omni_range = range_radius
    light.light_energy = strength
    light.shadow_enabled = false
    light.distance_fade_enabled = true
    light.distance_fade_begin = 25
    light.distance_fade_length = 28
    world.add_child(light)
    scene_lights.append(light)

func _tower_light(x: float,z: float,mat: String = "yellow") -> void:
    _piece(Vector3(x,3.2,z),Vector3(.15,6.3,.15),"steel")
    _piece(Vector3(x,6.4,z),Vector3(.7,.21,.5),"white")
    _piece(Vector3(x,6.25,z),Vector3(.48,.06,.45),mat)
    _lamp(Vector3(x,6.45,z),Color(1,.76,.41) if mat == "yellow" else Color(.23,.81,1), 10,1.0)

func _port() -> void:
    # Stacked freight containers, quay markings, cranes and waterfront floodlights.
    for x in [-34.0,34.0]:
        for z in [-31.0,0.0,31.0]:
            _piece(Vector3(x,.065,z),Vector3(8,.11,.19),"yellow")
    for i in range(5):
        var x := -34.0+float(i)*15.2
        _piece(Vector3(x,5.4,-39.0),Vector3(.48,10.8,.48),"rail")
        _piece(Vector3(x+4.6,10.8,-39.0),Vector3(9.7,.42,.65),"yellow")
        _piece(Vector3(x+8.9,7.2,-39.0),Vector3(.07,7.0,.09),"steel")
    for x in [-38.0,38.0]:
        for z in [-27.0,27.0]:
            _tower_light(x,z,"yellow")
    _piece(Vector3(0,.04,-39),Vector3(70,.09,.42),"cyan")

func _dunes() -> void:
    # Sand-colored courtyards, crenellated parapets, arcade colonnades and bazaars.
    for x in [-34.0,34.0]:
        for z in range(-35,36,5):
            _piece(Vector3(x,5.8,float(z)),Vector3(1.35,1.4,1.2),"stone")
    for i in range(18):
        var x := -32.0 + float(i%6)*12.1
        var z := -33.0 + float(i/6)*26.0
        _piece(Vector3(x,.37,z),Vector3(.82,.74,.82),"stone")
        _piece(Vector3(x,1.2,z),Vector3(1.03,.13,1.04),"plaster")
    for x in [-19.0,19.0]:
        for z in [-29.0,29.0]:
            _piece(Vector3(x,4.2,z),Vector3(.68,8.4,.68),"stone")
            _piece(Vector3(x,8.5,z),Vector3(1.8,.35,1.8),"sand")
    for x in [-37.0,37.0]:
        _tower_light(x,-2,"yellow")

func _neon() -> void:
    # Dense night market: emissive signs, vertical light strips, kiosks.
    for i in range(12):
        var x := -36.0+float(i%6)*14.2
        var z := -31.0+float(i/6)*63.0
        _piece(Vector3(x,4.5,z),Vector3(1.1,3.8,.14),"cyan" if i%2==0 else "magenta")
        _piece(Vector3(x,2.4,z),Vector3(3.4,.24,.17),"steel")
        if i%3==0:
            _lamp(Vector3(x,4.7,z),Color(.10,.86,1) if i%2==0 else Color(1,.14,.61),7.4,.85)
    for z in [-28.0,-14.0,0.0,14.0,28.0]:
        _piece(Vector3(0,.05,z),Vector3(5,.10,.15),"cyan")
    for x in [-38.0,38.0]:
        _tower_light(x,0,"cyan")

func _foundry() -> void:
    # Steelwork: furnace pipes, gantries, overhead rails and hazard patterns.
    for x in [-32.0,-18.0,18.0,32.0]:
        for z in [-23.0,0.0,23.0]:
            _piece(Vector3(x,7.5,z),Vector3(1.2,15,1.2),"rail")
            _piece(Vector3(x,14.4,z),Vector3(3.0,.4,3.0),"orange")
        _piece(Vector3(x,12.2,0),Vector3(.40,.40,78),"steel")
    for z in [-35.0,-18.0,3.0,20.0,35.0]:
        _piece(Vector3(0,.08,z),Vector3(26,.1,.35),"yellow")
        _piece(Vector3(0,10.4,z),Vector3(78,.35,.32),"steel")
    for x in [-39.0,39.0]:
        for z in [-24.0,24.0]:
            _tower_light(x,z,"yellow")

func _metro() -> void:
    # Two tracks, third rail, tiled platforms and a roofed station with signal lighting.
    for x in [-12.0,-6.0,6.0,12.0]:
        _piece(Vector3(x,-.012,0),Vector3(.24,.09,79),"steel")
    for z in range(-38,40,2):
        _piece(Vector3(0,-.013,float(z)),Vector3(28,.075,.25),"wood")
    for x in [-16.0,16.0]:
        _piece(Vector3(x,.28,0),Vector3(3.5,.55,77),"pavers")
        for z in range(-35,35,7):
            _piece(Vector3(x,4.6,float(z)),Vector3(.35,9,.40),"steel")
            _piece(Vector3(x,8.8,float(z)),Vector3(24,.32,.52),"steel")
    for z in [-30.0,-12.0,7.0,27.0]:
        _piece(Vector3(0,8.75,z),Vector3(33,.12,.43),"cyan")
        _lamp(Vector3(0,8.4,z),Color(.65,.84,1),10,.9)

func _alpine() -> void:
    # Snow radar base with mountain silhouettes, floodlights and signal masts.
    for i in range(36):
        var angle := float(i)*TAU/36.0
        var x := cos(angle)*46
        var z := sin(angle)*46
        var peak := 11.0+float((i*17)%13)
        _piece(Vector3(x,peak*.5-1,z),Vector3(4.5,peak,4.5),"stone")
        _piece(Vector3(x,peak-.6,z),Vector3(4.8,1.3,4.8),"snow")
    for i in range(18):
        var x := -38.0+float(i%9)*9.2
        var z := 31.0 if i<9 else -30.0
        _piece(Vector3(x,1.4,z),Vector3(.38,2.8,.38),"wood")
        _piece(Vector3(x,3.3,z),Vector3(2.3,2.4,2.3),"foliage")
        _piece(Vector3(x,4.6,z),Vector3(1.25,.45,1.25),"snow")
    for x in [-29.0,29.0]:
        _piece(Vector3(x,5.7,0),Vector3(.19,11.4,.19),"steel")
        _piece(Vector3(x,11.5,0),Vector3(3.5,.19,3.5),"cyan")
    _tower_light(-36,23,"cyan")
    _tower_light(36,-23,"cyan")

func _oldtown() -> void:
    # Old quarter with narrow alley details, arcades, timber stalls and warm lights.
    for x in [-33.0,33.0]:
        for z in range(-35,36,9):
            _piece(Vector3(x,4.2,float(z)),Vector3(.70,8.4,.65),"stone")
            _piece(Vector3(x+signf(x)*1.2,7.0,float(z)),Vector3(2.8,.42,3.1),"roof")
    for z in [-31.0,-9.0,13.0,31.0]:
        for x in [-27.0,27.0]:
            _piece(Vector3(x,3.0,z),Vector3(.20,6.0,.20),"wood")
            _piece(Vector3(x,5.85,z),Vector3(4.4,.16,3.4),"orange")
            _lamp(Vector3(x,5.65,z),Color(1,.71,.38),8.0,.9)
    for i in range(12):
        _piece(Vector3(-7.5+float(i)*1.35,.02,0),Vector3(.09,.026,72),"stone")

func _skyline() -> void:
    # High-rise glazing, edge rails, rooftop HVAC units and vertical beacons.
    for i in range(14):
        var x := -40.0+float(i%7)*13.2
        var z := -37.0 if i<7 else 37.0
        var height := 11.0+float(i*11%19)
        _piece(Vector3(x,height*.5,z),Vector3(8,height,6),"dark")
        for floor in range(maxi(3,int(height/2.0))):
            _piece(Vector3(x,float(floor)*2+.8,z+3.08*signf(z)),Vector3(7.2,1.10,.10),"glass")
            _piece(Vector3(x,float(floor)*2+1.35,z+3.15*signf(z)),Vector3(7.2,.09,.09),"steel")
        _piece(Vector3(x,height+.24,z),Vector3(9,.35,7),"roof")
        _piece(Vector3(x,height+2,z),Vector3(.12,3.7,.12),"cyan" if i%2==0 else "magenta")
    for z in [-32.0,-12.0,8.0,28.0]:
        _piece(Vector3(0,.09,z),Vector3(67,.15,.13),"cyan")
    for x in [-39.0,39.0]:
        _tower_light(x,0,"cyan")

func _lighting() -> void:
    var id := str(current_map.get("id",""))
    var night := id in ["neon","metro","skyline"]
    var desert := id in ["dunes","oldtown"]
    var snow := id == "alpine"
    if is_instance_valid(sunshine):
        sunshine.light_color = Color(.65,.80,1) if night else Color(1,.94,.85) if snow else Color(1,.79,.59) if desert else Color(1,.88,.71)
        sunshine.light_energy = .25 if night else 1.5 if snow else 1.18
        sunshine.rotation_degrees = Vector3(-56,-34,-9) if snow else Vector3(-30,-34,-9)
    if atmosphere != null:
        atmosphere.fog_enabled = not night
        atmosphere.fog_density = .002 if snow else .0018 if desert else .0034
        atmosphere.fog_light_color = Color(.71,.79,.87) if snow else Color(.78,.68,.50) if desert else Color(.31,.46,.62)
        atmosphere.ambient_light_energy = .47 if night else .9 if snow else .71
