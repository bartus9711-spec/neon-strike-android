extends Node3D
## Original game-art: modular HUMAN sci-fi arena operator, not a robot.
## Performance-aware geometry; rigged pivots are animated every physics tick.
## Uniforms, padded vest, boots, helmet, visor, neck, gloves and optional utility
## pouches. No external model licence / network download needed.
var phase := 0.0
const RIGGED_HUMAN := "res://assets/models/soldier.glb"
const DETAILED_HUMAN := "res://assets/models/soldier_tac.glb"
var prefer_detail_lod := false
var imported_model: Node3D
var imported_anim: AnimationPlayer
var anim_idle: StringName = &""
var anim_run: StringName = &""
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
var left_forearm: Node3D
var right_forearm: Node3D
var left_shin: Node3D
var right_shin: Node3D
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
    mesh.radial_segments = 18 if quality >= 2 else 12
    mesh.rings = 7 if quality >= 2 else 4
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
    mesh.radial_segments = 20 if quality >= 2 else 16
    mesh.rings = 12 if quality >= 2 else 8
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

# Smooth low-poly fabric shell, built once per operator.
# Unlike a scaled ball, the collar, waist and shoulder widths are independently
# controlled so the figure reads as a clothed person from all camera angles.
func _garment(parent: Node3D, rings: Array, mat: Material, label: String) -> MeshInstance3D:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var segments := 16 if quality >= 2 else 12
    for index in range(rings.size() - 1):
        var lo: Vector4 = rings[index]
        var hi: Vector4 = rings[index + 1]
        for sector in range(segments):
            var a := TAU * float(sector) / float(segments)
            var b := TAU * float(sector + 1) / float(segments)
            var p00 := Vector3(cos(a) * lo.y, lo.x, sin(a) * lo.z + lo.w)
            var p01 := Vector3(cos(b) * lo.y, lo.x, sin(b) * lo.z + lo.w)
            var p10 := Vector3(cos(a) * hi.y, hi.x, sin(a) * hi.z + hi.w)
            var p11 := Vector3(cos(b) * hi.y, hi.x, sin(b) * hi.z + hi.w)
            surface.add_vertex(p00)
            surface.add_vertex(p10)
            surface.add_vertex(p11)
            surface.add_vertex(p00)
            surface.add_vertex(p11)
            surface.add_vertex(p01)
    # Merge shared ring edges before calculating normals; reduces the faceted look.
    surface.index()
    surface.generate_normals()
    var result := MeshInstance3D.new()
    result.name = label
    result.mesh = surface.commit()
    result.material_override = mat
    parent.add_child(result)
    return result

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

func _import_real_human(team: int) -> bool:
    var model_path: String = DETAILED_HUMAN if prefer_detail_lod else RIGGED_HUMAN
    if not ResourceLoader.exists(model_path):
        return false
    var packed := load(model_path) as PackedScene
    if packed == null:
        return false
    var node := packed.instantiate() as Node3D
    if node == null:
        return false
    var shell := Node3D.new()
    shell.name = "Licensed3DHuman"
    add_child(shell)
    shell.add_child(node)
    var bounds_min := Vector3(INF,INF,INF)
    var bounds_max := Vector3(-INF,-INF,-INF)
    var meshes := node.find_children("*","MeshInstance3D",true,false)
    if node is MeshInstance3D:
        meshes.append(node)
    for mesh in meshes:
        var mi := mesh as MeshInstance3D
        var transform_to_shell: Transform3D = shell.global_transform.affine_inverse() * mi.global_transform
        var bounds := mi.get_aabb()
        for corner in range(8):
            var vertex := transform_to_shell * bounds.get_endpoint(corner)
            bounds_min = bounds_min.min(vertex)
            bounds_max = bounds_max.max(vertex)
    if meshes.is_empty() or bounds_max.y - bounds_min.y < .005:
        shell.queue_free()
        return false
    var factor := clampf(1.75/(bounds_max.y-bounds_min.y),.025,25.0)
    var mid := (bounds_min+bounds_max)*.5
    node.scale *= factor
    node.position = Vector3(-mid.x*factor,-bounds_min.y*factor,-mid.z*factor)
    node.rotation.y += PI
    # Soft woven team patches aid identification without the old neon rings.
    var patch := MeshInstance3D.new()
    patch.name = "UniformIdentificationPatch"
    var patch_mesh := BoxMesh.new()
    patch_mesh.size = Vector3(.13,.095,.032)
    patch.mesh = patch_mesh
    patch.position = Vector3(.28,1.31,-.13)
    var patch_mat := StandardMaterial3D.new()
    patch_mat.albedo_color = Color(.29,.43,.48) if team == 0 else Color(.55,.34,.24)
    patch_mat.roughness = .94
    patch.material_override = patch_mat
    shell.add_child(patch)
    root = shell
    imported_model = node
    var animation_players := node.find_children("*","AnimationPlayer",true,false)
    if node is AnimationPlayer:
        animation_players.append(node)
    if not animation_players.is_empty():
        imported_anim = animation_players[0] as AnimationPlayer
        for track_name in imported_anim.get_animation_list():
            var key := str(track_name).to_lower()
            if anim_idle == &"" and key.contains("idle"):
                anim_idle = track_name
            if anim_run == &"" and (key.contains("walk") or key.contains("jog") or key.contains("run")):
                anim_run = track_name
        if anim_idle != &"":
            imported_anim.play(anim_idle)
    print("TEAMCS_IMPORTED_HUMAN: ",model_path," meshes=",meshes.size()," anim_idle=",anim_idle," anim_run=",anim_run)
    return true

func build(team: int, character_variant: int, actor_quality: int) -> void:
    side = team
    variant = character_variant
    quality = actor_quality
    if _import_real_human(team):
        set_quality(actor_quality)
        return
    var blue := team == 0
    # CT in graphite/navy and T in dusty olive/brown, both matte fabrics.
    var dark_olive := Color(.18,.235,.255) if blue else Color(.39,.335,.245)
    var palette := [Color(.20,.245,.25),Color(.24,.28,.25),Color(.34,.30,.26),Color(.29,.32,.29)]
    dark_olive = dark_olive.lerp(palette[posmod(variant + team*2,palette.size())],.26)
    uniform = _material(dark_olive,.95)
    uniform_secondary = _material(dark_olive.darkened(.15),.96)
    armor = _material(Color(.105,.12,.13) if blue else Color(.27,.24,.205),.89,.02)
    armor_edge = _material(Color(.19,.22,.23) if blue else Color(.35,.30,.24),.91,.01)
    skin = _material([Color(.61,.43,.32),Color(.85,.67,.51),Color(.40,.30,.24),Color(.71,.54,.39)][posmod(variant,4)],.92)
    glove = _material(Color(.10,.12,.13),.74,.13)
    visor = _material(Color(.07,.11,.13),.37,.08)
    # Team identification is dyed fabric rather than bright glowing armour.
    accent = _material(Color(.30,.47,.53) if blue else Color(.55,.35,.30),.84,.02)
    root = Node3D.new()
    root.name = "FullHumanoidFigure"
    add_child(root)
    # Body accessories are children of the animated torso, not static world
    # decorations: straps and pouches now follow leaning/breathing poses.
    torso = Node3D.new()
    torso.name = "UpperBodyRig"
    torso.position = Vector3(0,1.13,0)
    root.add_child(torso)
    detail = Node3D.new()
    detail.name = "HighGeometryAccessories"
    detail.position = Vector3(0,-1.13,0)
    torso.add_child(detail)
    _garment(torso, [
        Vector4(-.36,.20,.16,.02),
        Vector4(-.28,.25,.18,.02),
        Vector4(-.12,.28,.18,.00),
        Vector4(.12,.34,.205,.00),
        Vector4(.30,.33,.20,.01),
        Vector4(.43,.22,.145,.015)
    ],uniform,"TailoredUniformBody")
    _sphere(torso,Vector3(0,-.32,0),Vector3(.47,.31,.33),uniform_secondary,"BeltHip")
    # Rounded overlapping panels hug the body; no flat cardboard/box torso.
    _garment(torso, [
        Vector4(-.17,.226,.178,-.068),
        Vector4(-.08,.263,.198,-.054),
        Vector4(.14,.296,.218,-.045),
        Vector4(.33,.286,.198,-.043),
        Vector4(.36,.23,.17,-.04)
    ],armor,"ContouredProtectiveVest")
    _sphere(torso,Vector3(0,.28,-.302),Vector3(.43,.23,.072),armor_edge,"UpperVestPlate")
    _sphere(torso,Vector3(0,-.08,-.295),Vector3(.43,.17,.075),armor_edge,"LowerVestPlate")
    _sphere(torso,Vector3(0,.36,-.11),Vector3(.54,.11,.32),uniform_secondary,"ClothShoulderSeam")
    _sphere(torso,Vector3(0,-.25,-.20),Vector3(.48,.13,.18),glove,"CurvedUtilityBelt")
    _capsule(torso,Vector3(0,.54,0),.105,.23,skin,"Neck")
    helmet = Node3D.new()
    helmet.name = "HeadRig"
    helmet.position = Vector3(0,.63,0)
    torso.add_child(helmet)
    _sphere(helmet,Vector3(0,.015,0),Vector3(.36,.43,.34),skin,"FaceAndHead")
    if blue:
        _sphere(helmet,Vector3(0,.17,.012),Vector3(.39,.245,.365),armor,"TacticalHelmet")
        _sphere(helmet,Vector3(-.105,.052,-.174),Vector3(.155,.09,.075),visor,"LeftGoggleLens")
        _sphere(helmet,Vector3(.105,.052,-.174),Vector3(.155,.09,.075),visor,"RightGoggleLens")
        _sphere(helmet,Vector3(0,.16,-.22),Vector3(.34,.054,.078),armor_edge,"CurvedVisorRim")
        _sphere(helmet,Vector3(-.195,.035,0),Vector3(.075,.14,.155),armor_edge,"EarProtectionLeft")
        _sphere(helmet,Vector3(.195,.035,0),Vector3(.075,.14,.155),armor_edge,"EarProtectionRight")
    else:
        _sphere(helmet,Vector3(0,.045,.02),Vector3(.385,.43,.355),uniform_secondary,"FabricBalaclavaHood")
        _sphere(helmet,Vector3(0,.032,-.173),Vector3(.295,.083,.072),skin,"VisibleEyeBand")
        _sphere(helmet,Vector3(0,-.08,-.218),Vector3(.30,.16,.095),uniform_secondary,"WrappedFaceScarf")
        _sphere(helmet,Vector3(0,-.235,-.065),Vector3(.37,.15,.32),uniform,"ClothNeckWrap")
    _sphere(helmet,Vector3(0,-.13,-.18),Vector3(.30,.105,.070),glove,"FabricFaceCover")
    for flank in [-1,1]:
        var left: bool = int(flank) == -1
        var arm := Node3D.new()
        arm.name = "LeftShoulderRig" if left else "RightShoulderRig"
        arm.position = Vector3(.395*flank,.37,0)
        torso.add_child(arm)
        _garment(arm, [
            Vector4(.075,.125,.12,.0),
            Vector4(-.07,.153,.145,-.005),
            Vector4(-.23,.14,.125,.0),
            Vector4(-.38,.113,.105,.005)
        ], uniform, "TailoredUniformSleeve")
        _capsule(arm,Vector3(0,-.365,-.008),.115,.23,uniform_secondary,"FabricElbowConnector")
        _sphere(arm,Vector3(0,-.075,-.01),Vector3(.25,.21,.245),uniform_secondary,"ClothShoulderOverlay")
        if blue:
            _sphere(arm,Vector3(0,-.082,-.012),Vector3(.24,.12,.235),armor_edge,"CurvedArmourPauldron")
        var forearm := Node3D.new()
        forearm.name = "ElbowJoint"
        forearm.position = Vector3(0,-.385,-.04)
        arm.add_child(forearm)
        _garment(forearm, [
            Vector4(.045,.118,.110,.0),
            Vector4(-.12,.118,.115,-.005),
            Vector4(-.28,.105,.105,-.012),
            Vector4(-.35,.086,.09,-.025)
        ], uniform_secondary, "ArticulatedFabricForearm")
        _sphere(forearm,Vector3(0,-.365,-.035),Vector3(.20,.20,.18),glove,"Glove")
        _sphere(arm,Vector3(0,-.40,-.125),Vector3(.20,.17,.09),armor,"ElbowGuard")
        if left:
            left_forearm = forearm
        else:
            right_forearm = forearm
        if left:
            left_arm = arm
        else:
            right_arm = arm
        var leg := Node3D.new()
        leg.name = "LeftLegRig" if left else "RightLegRig"
        leg.position = Vector3(flank*.17,1.06,0)
        root.add_child(leg)
        _garment(leg, [
            Vector4(.105,.183,.186,.005),
            Vector4(-.06,.186,.178,.0),
            Vector4(-.24,.168,.168,-.006),
            Vector4(-.46,.133,.137,0.0)
        ], uniform, "TaperedTrouserThigh")
        _capsule(leg,Vector3(0,-.50,0),.145,.22,uniform_secondary,"FabricKneeConnector")
        _sphere(leg,Vector3(flank*.12,-.24,-.015),Vector3(.15,.27,.175),uniform_secondary,"ThighFabricCargoPocket")
        _sphere(leg,Vector3(0,-.53,-.075),Vector3(.30,.24,.21),armor_edge,"KneeGuard")
        var shin := Node3D.new()
        shin.name = "KneeJoint"
        shin.position = Vector3(0,-.56,.015)
        leg.add_child(shin)
        _garment(shin, [
            Vector4(.065,.144,.138,.005),
            Vector4(-.09,.136,.13,.0),
            Vector4(-.24,.13,.118,.008),
            Vector4(-.355,.113,.11,-.015)
        ], uniform_secondary, "TailoredTrouserShin")
        _sphere(shin,Vector3(0,-.43,-.115),Vector3(.27,.165,.40),glove,"Boot")
        _sphere(shin,Vector3(0,-.29,-.015),Vector3(.25,.145,.24),armor_edge,"SoftBootCuff")
        # Moulded but flexible kneecap and boot collar, both following knee movement.
        _sphere(shin,Vector3(0,-.02,-.16),Vector3(.205,.105,.08),armor_edge,"LowerKneePad")
        if left:
            left_shin = shin
        else:
            right_shin = shin
        if left:
            left_leg = leg
        else:
            right_leg = leg
        # Compact team-identification patches on both shoulders: no cartoon halo.
        _block(arm,Vector3(flank*.11,-.19,-.06),Vector3(.044,.17,.18),accent,"TeamPatch")
    # High quality extras: straps, garment folds, pouches and visor reflection.
    _capsule(detail,Vector3(-.24,1.24,-.255),.043,.51,glove,"LeftRoundedVestStrap")
    _capsule(detail,Vector3(.24,1.24,-.255),.043,.51,glove,"RightRoundedVestStrap")
    _block(detail,Vector3(0,1.25,.25),Vector3(.48,.51,.21),armor,"BackPadding")
    for ix in range(3):
        _sphere(detail,Vector3((float(ix)-1.)*.155,1.10,-.34),Vector3(.145,.19,.11),armor_edge,"RoundedUtilityPouch"+str(ix))
        _block(detail,Vector3((float(ix)-1.)*.155,1.175,-.386),Vector3(.13,.026,.015),glove,"PouchFastener"+str(ix))
    _sphere(detail,Vector3(-.27,.86,-.13),Vector3(.15,.21,.22),armor_edge,"SoftUtilityPackLeft")
    _sphere(detail,Vector3(.27,.86,-.13),Vector3(.15,.21,.22),armor_edge,"SoftUtilityPackRight")
    _block(detail,Vector3(0,1.50,-.245),Vector3(.11,.038,.028),accent,"ChestStatusLED")
    _sphere(detail,Vector3(-.08,1.76,-.24),Vector3(.09,.032,.02),accent,"OpticalGlassReflection")
    # Ultra apparel: soft padded back radio, ribbing, knee fabric stitching and shoulder fasteners.
    if blue:
        _sphere(detail,Vector3(.21,1.23,.29),Vector3(.19,.31,.13),glove,"CompactRadioPack")
        _sphere(detail,Vector3(.21,1.35,.367),Vector3(.10,.09,.05),accent,"CommsIndicator")
    for flank in [-1.0,1.0]:
        _sphere(detail,Vector3(flank*.265,1.48,-.16),Vector3(.16,.075,.13),armor_edge,"CollarSeam")
        for n in range(3):
            _sphere(detail,Vector3(flank*.155,.73-float(n)*.075,-.14),Vector3(.13,.029,.075),uniform_secondary,"FabricKneeStitch")
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
        var medium_only := ["CurvedVisorRim","FabricFaceCover","BeltHip","ShoulderArmorBridge"]
        for mesh_node in root.find_children("*","MeshInstance3D",true,false):
            if str(mesh_node.name) in high_only:
                mesh_node.visible = quality >= 2
            elif str(mesh_node.name) in medium_only:
                mesh_node.visible = quality >= 1

func update_pose(speed: float, delta: float, aim: float = 0.0) -> void:
    if is_instance_valid(imported_model):
        if is_instance_valid(imported_anim):
            var chosen: StringName = anim_run if speed > .65 and anim_run != &"" else anim_idle
            if chosen != &"" and (not imported_anim.is_playing() or imported_anim.current_animation != chosen):
                imported_anim.play(chosen,.22)
        else:
            # Static detailed suit fallback in the lobby: understated idle motion.
            phase += delta * .9
            root.position.y = sin(phase)*.006
        return
    # Procedural clothed character stays as an offline importer fallback.
    # 2-3 sec/s gait; smoothly returns to idle when stopped.
    phase += delta * (2.6+minf(speed,8.0)*1.8)
    var moving := clampf(speed/3.0,0.0,1.0)
    var swing := sin(phase) * .56 * moving
    if is_instance_valid(left_leg):
        left_leg.rotation.x = lerpf(left_leg.rotation.x,swing,clampf(delta*9.,0.,1.))
    if is_instance_valid(right_leg):
        right_leg.rotation.x = lerpf(right_leg.rotation.x,-swing,clampf(delta*9.,0.,1.))
    # A second joint bends elbows and knees naturally instead of rigid windmill limbs.
    if is_instance_valid(left_shin):
        left_shin.rotation.x = lerpf(left_shin.rotation.x,-maxf(0.,swing)*.8,clampf(delta*11.,0.,1.))
    if is_instance_valid(right_shin):
        right_shin.rotation.x = lerpf(right_shin.rotation.x,-maxf(0.,-swing)*.8,clampf(delta*11.,0.,1.))
    if is_instance_valid(left_forearm):
        left_forearm.rotation.x = lerpf(left_forearm.rotation.x,-.22-maxf(0.,-swing)*.38,clampf(delta*9.,0.,1.))
    if is_instance_valid(right_forearm):
        right_forearm.rotation.x = lerpf(right_forearm.rotation.x,-.22-maxf(0.,swing)*.38,clampf(delta*9.,0.,1.))
    if is_instance_valid(left_arm):
        left_arm.rotation.x = lerpf(left_arm.rotation.x,-swing*.7-.18,clampf(delta*9.,0.,1.))
    if is_instance_valid(right_arm):
        right_arm.rotation.x = lerpf(right_arm.rotation.x,swing*.7-.18,clampf(delta*9.,0.,1.))
    if is_instance_valid(torso):
        var smooth := clampf(delta * 7.0,0.0,1.0)
        torso.rotation.z = lerpf(torso.rotation.z, sin(phase*.5)*.022*moving, smooth)
        torso.rotation.y = lerpf(torso.rotation.y, sin(phase)*.045*moving, smooth)
        torso.rotation.x = lerpf(torso.rotation.x,-.05*moving,smooth)
        # Subtle idle breathing; no full-body size changes or collision changes.
        torso.scale.y = lerpf(torso.scale.y,1.0+sin(phase*.65)*.0035,smooth)
    if is_instance_valid(root):
        # A restrained vertical gait prevents the robotic sliding appearance.
        root.position.y = lerpf(root.position.y,absf(sin(phase))*.016*moving,clampf(delta*8.,0.,1.))
    if is_instance_valid(helmet):
        helmet.rotation.y = sin(phase*.38+variant)*.09
        helmet.rotation.x = lerpf(helmet.rotation.x,clampf(aim,-.12,.12),clampf(delta*5.,0.,1.))
