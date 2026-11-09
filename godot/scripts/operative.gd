extends Node3D
## Original game-art: modular HUMAN sci-fi arena operator, not a robot.
## Performance-aware geometry; rigged pivots are animated every physics tick.
## Uniforms, padded vest, boots, helmet, visor, neck, gloves and optional utility
## pouches. No external model licence / network download needed.
var phase := 0.0
var quality := 1
var variant := 0
var side := 0
var root: Node3D
var detail: Node3D
var torso: Node3D
var helmet: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var accent: StandardMaterial3D
var uniform: StandardMaterial3D
var uniform_secondary: StandardMaterial3D
var armor: StandardMaterial3D
var armor_edge: StandardMaterial3D
var glove: StandardMaterial3D
var skin: StandardMaterial3D
var visor: StandardMaterial3D

func _material(color: Color, roughness: float, metallic: float = 0.0, emit := false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    m.metallic = metallic
    if emit:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = 0.7
    return m

func _capsule(parent: Node3D, p: Vector3, radius: float, height: float, mat: Material, label: String) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = label
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = maxf(height, radius*2.01)
    mesh.radial_segments = 12
    mesh.rings = 4
    n.mesh = mesh
    n.position = p
    n.material_override = mat
    parent.add_child(n)
    return n

func _sphere(parent: Node3D, p: Vector3, dims: Vector3, mat: Material, label: String) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = label
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    mesh.radial_segments = 16
    mesh.rings = 8
    n.mesh = mesh
    n.position = p
    n.scale = dims
    n.material_override = mat
    parent.add_child(n)
    return n

func _block(parent: Node3D, p: Vector3, dims: Vector3, mat: Material, label: String) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = label
    var mesh := BoxMesh.new()
    mesh.size = dims
    n.mesh = mesh
    n.position = p
    n.material_override = mat
    parent.add_child(n)
    return n

func _ring(parent: Node3D,p: Vector3,radius: float, tube: float,mat: Material,label: String) -> void:
    var mesh := TorusMesh.new()
    mesh.inner_radius = radius
    mesh.outer_radius = radius+tube
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.position = p
    node.material_override = mat
    parent.add_child(node)

func build(team: int, character_variant: int, actor_quality: int) -> void:
    side = team
    variant = character_variant
    quality = actor_quality
    var blue := team == 0
    var dark_olive := Color(.25,.30,.30) if blue else Color(.31,.29,.23)
    var palette := [Color(.21,.28,.30),Color(.32,.34,.30),Color(.30,.28,.31),Color(.26,.31,.33)]
    dark_olive = palette[posmod(variant + team*2,palette.size())].lerp(dark_olive,.55)
    uniform = _material(dark_olive,.95)
    uniform_secondary = _material(dark_olive.darkened(.15),.96)
    armor = _material(Color(.125,.155,.18) if blue else Color(.20,.175,.165),.62,.08)
    armor_edge = _material(Color(.19,.23,.25) if blue else Color(.29,.24,.19),.56,.20)
    skin = _material([Color(.61,.43,.32),Color(.85,.67,.51),Color(.40,.30,.24),Color(.71,.54,.39)][posmod(variant,4)],.92)
    glove = _material(Color(.10,.12,.13),.74,.13)
    visor = _material(Color(.07,.16,.20),.17,.32)
    accent = _material(Color(.20,.80,.91) if blue else Color(.98,.35,.37),.26,.35,true)
    root = Node3D.new()
    root.name = "FullHumanoidFigure"
    add_child(root)
    detail = Node3D.new()
    detail.name = "HighGeometryAccessories"
    root.add_child(detail)
    # Athletic but not exaggerated human proportions: ~1.79m.
    torso = Node3D.new()
    torso.name = "UpperBodyRig"
    torso.position = Vector3(0,1.13,0)
    root.add_child(torso)
    _sphere(torso,Vector3(0,.09,0),Vector3(.66,.77,.35),uniform,"TexturedTorso")
    _sphere(torso,Vector3(0,-.32,0),Vector3(.52,.35,.35),uniform_secondary,"BeltHip")
    _block(torso,Vector3(0,.10,-.23),Vector3(.50,.56,.17),armor,"ContouredArmourVest")
    _sphere(torso,Vector3(0,.36,-.14),Vector3(.63,.17,.43),armor_edge,"ShoulderArmorBridge")
    _block(torso,Vector3(0,-.25,-.22),Vector3(.43,.11,.14),glove,"UtilityBelt")
    _capsule(torso,Vector3(0,.54,0),.105,.23,skin,"Neck")
    helmet = Node3D.new()
    helmet.name = "HeadRig"
    helmet.position = Vector3(0,.63,0)
    torso.add_child(helmet)
    _sphere(helmet,Vector3(0,.015,0),Vector3(.36,.43,.34),skin,"FaceAndHead")
    _sphere(helmet,Vector3(0,.16,0),Vector3(.415,.25,.37),armor,"TacticalHelmet")
    _sphere(helmet,Vector3(0,.025,-.175),Vector3(.35,.145,.09),visor,"TintedGoggles")
    _block(helmet,Vector3(0,.16,-.24),Vector3(.32,.042,.08),armor_edge,"VisorRim")
    _sphere(helmet,Vector3(0,-.10,-.165),Vector3(.31,.11,.075),glove,"FabricFaceCover")
    _sphere(helmet,Vector3(-.19,.03,0),Vector3(.075,.15,.16),armor_edge,"EarProtectionLeft")
    _sphere(helmet,Vector3(.19,.03,0),Vector3(.075,.15,.16),armor_edge,"EarProtectionRight")
    for flank in [-1,1]:
        var left: bool = int(flank) == -1
        var arm := Node3D.new()
        arm.name = "LeftShoulderRig" if left else "RightShoulderRig"
        arm.position = Vector3(.395*flank,.37,0)
        torso.add_child(arm)
        _capsule(arm,Vector3(0,-.19,0),.128,.48,uniform,"Sleeve")
        _sphere(arm,Vector3(0,-.075,-.01),Vector3(.265,.22,.275),armor_edge,"ArmourPauldron")
        _capsule(arm,Vector3(0,-.53,-.055),.105,.41,uniform_secondary,"Forearm")
        _sphere(arm,Vector3(0,-.77,-.075),Vector3(.20,.20,.18),glove,"Glove")
        _sphere(arm,Vector3(0,-.43,-.14),Vector3(.20,.17,.09),armor,"ElbowGuard")
        if left:
            left_arm = arm
        else:
            right_arm = arm
        var leg := Node3D.new()
        leg.name = "LeftLegRig" if left else "RightLegRig"
        leg.position = Vector3(flank*.17,1.06,0)
        root.add_child(leg)
        _capsule(leg,Vector3(0,-.22,0),.161,.58,uniform,"UniformThigh")
        _sphere(leg,Vector3(0,-.53,-.075),Vector3(.30,.24,.21),armor_edge,"KneeGuard")
        _capsule(leg,Vector3(0,-.71,.015),.129,.40,uniform_secondary,"UniformShin")
        _sphere(leg,Vector3(0,-.99,-.10),Vector3(.30,.205,.45),glove,"Boot")
        if left:
            left_leg = leg
        else:
            right_leg = leg
        # Compact team-identification patches on both shoulders: no cartoon halo.
        _block(arm,Vector3(flank*.11,-.19,-.06),Vector3(.044,.17,.18),accent,"TeamPatch")
    # High quality extras: straps, garment folds, pouches and visor reflection.
    _block(detail,Vector3(-.24,1.24,-.255),Vector3(.07,.49,.085),glove,"LeftVestStrap")
    _block(detail,Vector3(.24,1.24,-.255),Vector3(.07,.49,.085),glove,"RightVestStrap")
    _block(detail,Vector3(0,1.25,.25),Vector3(.48,.51,.21),armor,"BackPadding")
    for ix in range(3):
        _block(detail,Vector3((float(ix)-1.)*.155,1.10,-.34),Vector3(.13,.18,.085),armor_edge,"UtilityPouch"+str(ix))
        _block(detail,Vector3((float(ix)-1.)*.155,1.175,-.386),Vector3(.13,.026,.015),glove,"PouchFastener"+str(ix))
    _block(detail,Vector3(-.27,.86,-.13),Vector3(.13,.19,.21),armor_edge,"SidePackLeft")
    _block(detail,Vector3(.27,.86,-.13),Vector3(.13,.19,.21),armor_edge,"SidePackRight")
    _block(detail,Vector3(0,1.50,-.245),Vector3(.11,.038,.028),accent,"ChestStatusLED")
    _sphere(detail,Vector3(-.08,1.76,-.24),Vector3(.09,.032,.02),accent,"OpticalGlassReflection")
    set_quality(actor_quality)

func set_quality(level: int) -> void:
    quality = clampi(level,0,2)
    if is_instance_valid(detail):
        detail.visible = quality >= 2
    if is_instance_valid(root):
        root.visible = true
        # Medium keeps a recognisable clothed human; Ultra adds all protective
        # details. Reduce separate GPU draw calls on mobile without losing the rig.
        var high_only := ["EarProtectionLeft","EarProtectionRight","ElbowGuard","KneeGuard","PouchFastener0","PouchFastener1","PouchFastener2"]
        var medium_only := ["VisorRim","FabricFaceCover","BeltHip","ShoulderArmorBridge"]
        for mesh_node in root.find_children("*","MeshInstance3D",true,false):
            if str(mesh_node.name) in high_only:
                mesh_node.visible = quality >= 2
            elif str(mesh_node.name) in medium_only:
                mesh_node.visible = quality >= 1

func update_pose(speed: float, delta: float, aim: float = 0.0) -> void:
    # 2-3 sec/s gait; smoothly returns to idle when stopped.
    phase += delta * (2.6+minf(speed,8.0)*1.8)
    var moving := clampf(speed/3.0,0.0,1.0)
    var swing := sin(phase) * .56 * moving
    if is_instance_valid(left_leg):
        left_leg.rotation.x = lerpf(left_leg.rotation.x,swing,clampf(delta*9.,0.,1.))
    if is_instance_valid(right_leg):
        right_leg.rotation.x = lerpf(right_leg.rotation.x,-swing,clampf(delta*9.,0.,1.))
    if is_instance_valid(left_arm):
        left_arm.rotation.x = lerpf(left_arm.rotation.x,-swing*.7-.18,clampf(delta*9.,0.,1.))
    if is_instance_valid(right_arm):
        right_arm.rotation.x = lerpf(right_arm.rotation.x,swing*.7-.18,clampf(delta*9.,0.,1.))
    if is_instance_valid(torso):
        torso.rotation.z = sin(phase*.5)*.018*moving
        torso.rotation.x = lerpf(torso.rotation.x,-.05*moving,clampf(delta*7.,0.,1.))
    if is_instance_valid(helmet):
        helmet.rotation.y = sin(phase*.38+variant)*.09
        helmet.rotation.x = lerpf(helmet.rotation.x,clampf(aim,-.12,.12),clampf(delta*5.,0.,1.))
