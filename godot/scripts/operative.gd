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
var imported_source_path: String = ""
var imported_mesh_count := 0
var imported_model_height := 0.0
var imported_model_visible := false
var imported_anim: AnimationPlayer
var anim_idle: StringName = &""
var anim_walk: StringName = &""
var anim_run: StringName = &""
var anim_sprint: StringName = &""
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
    var human := packed.instantiate() as Node3D
    if human == null:
        return false
    # Some source GLBs carry editor visibility flags on an intermediate
    # Node3D/Skeleton3D, not just on the mesh itself. The game owns visibility
    # and must not silently ship an invisible operator after import.
    human.visible = true
    for spatial_node in human.find_children("*","Node3D",true,false):
        var spatial := spatial_node as Node3D
        if is_instance_valid(spatial):
            spatial.visible = true
    # Keep the original glTF root and armature transforms untouched. Imported
    # assets use wildly different units and a Z-up authoring convention.
    var shell := Node3D.new()
    shell.name = "Fitted3DHuman"
    add_child(shell)
    var axis_pivot := Node3D.new()
    axis_pivot.name = "UprightOrientation"
    shell.add_child(axis_pivot)
    var fit := Node3D.new()
    fit.name = "ScaledModel"
    axis_pivot.add_child(fit)
    var center_offset := Node3D.new()
    center_offset.name = "OriginalModelOffset"
    fit.add_child(center_offset)
    center_offset.add_child(human)
    var meshes: Array[Node] = human.find_children("*","MeshInstance3D",true,false)
    if human is MeshInstance3D:
        meshes.append(human)
    var smallest := Vector3(INF,INF,INF)
    var largest := Vector3(-INF,-INF,-INF)
    imported_mesh_count = 0
    for mesh in meshes:
        var instance := mesh as MeshInstance3D
        if not is_instance_valid(instance):
            continue
        instance.visible = true
        instance.layers = 1
        instance.visibility_range_begin = 0.0
        instance.visibility_range_end = 120.0
        imported_mesh_count += 1
        var into_fit: Transform3D = fit.global_transform.affine_inverse() * instance.global_transform
        var bounds := instance.get_aabb()
        for vertex in range(8):
            var point: Vector3 = into_fit * bounds.get_endpoint(vertex)
            smallest = smallest.min(point)
            largest = largest.max(point)
    if meshes.is_empty():
        shell.queue_free()
        return false
    var extent: Vector3 = largest-smallest
    var is_z_up: bool = extent.z > extent.y*1.45
    var raw_height: float = extent.z if is_z_up else extent.y
    if raw_height <= .000001:
        shell.queue_free()
        return false
    # No artificial min/max scaling clamp. A GLB authored in centimetres
    # or micrometres must still become a 1.75 m character, not a tiny dot.
    var factor: float = 1.75 / raw_height
    imported_source_path = model_path
    imported_model_height = 1.75
    var middle: Vector3 = (smallest+largest)*.5
    center_offset.position = Vector3(-middle.x,-middle.y,-smallest.z) if is_z_up else Vector3(-middle.x,-smallest.y,-middle.z)
    fit.scale = Vector3.ONE*factor
    axis_pivot.rotation.x = -PI/2.0 if is_z_up else 0.0
    axis_pivot.rotation.y = PI
    # Cloth-coloured identification patch, not emissive neon head rings.
    var patch := MeshInstance3D.new()
    patch.name = "FabricUniformPatch"
    var patch_mesh := BoxMesh.new()
    patch_mesh.size = Vector3(.12,.09,.027)
    patch.mesh = patch_mesh
    patch.position = Vector3(.28,1.32,-.13)
    var patch_mat := StandardMaterial3D.new()
    patch_mat.albedo_color = Color(.30,.43,.48) if team == 0 else Color(.51,.33,.25)
    patch_mat.roughness = .94
    patch.material_override = patch_mat
    shell.add_child(patch)
    root = shell
    shell.visible = true
    imported_model = human
    imported_model_visible = true
    var animation_players := human.find_children("*","AnimationPlayer",true,false)
    if not animation_players.is_empty():
        imported_anim = animation_players[0] as AnimationPlayer
        var clips := imported_anim.get_animation_list()
        for preferred in ["ready_idle","aim_idle","idle","crouch_idle"]:
            if clips.has(preferred):
                anim_idle = StringName(preferred)
                break
        for preferred in ["ready_walk","aim_walk","walk"]:
            if clips.has(preferred):
                anim_walk = StringName(preferred)
                break
        for preferred in ["ready_run","aim_run","run"]:
            if clips.has(preferred):
                anim_run = StringName(preferred)
                break
        for preferred in ["ready_sprint","aim_sprint","sprint"]:
            if clips.has(preferred):
                anim_sprint = StringName(preferred)
                break
        if anim_walk == &"":
            anim_walk = anim_run
        if anim_run == &"":
            anim_run = anim_walk
        if anim_idle == &"" and not clips.is_empty():
            anim_idle = StringName(clips[0])
        if anim_idle != &"":
            imported_anim.play(anim_idle)
    print("TEAMCS_HUMAN_FITTED: ",model_path," dimensions=",extent,
        " upZ=",is_z_up," units=",factor," meshes=",imported_mesh_count,
        " visible=",imported_model_visible," idle=",anim_idle," locomotion=",anim_run)
    return true

func force_render_visibility() -> void:
    # Re-assert visibility after GLB import and after quality changes. This is
    # intentionally limited to imported geometry; it never replaces materials
    # or the licensed source mesh with a procedural placeholder.
    if is_instance_valid(root):
        root.visible = true
    if is_instance_valid(imported_model):
        imported_model.visible = true
        for spatial_node in imported_model.find_children("*","Node3D",true,false):
            var spatial := spatial_node as Node3D
            if is_instance_valid(spatial):
                spatial.visible = true
        for mesh_node in imported_model.find_children("*","MeshInstance3D",true,false):
            var mesh_instance := mesh_node as MeshInstance3D
            if is_instance_valid(mesh_instance):
                mesh_instance.visible = true
                mesh_instance.layers = 1
                mesh_instance.visibility_range_begin = 0.0
                mesh_instance.visibility_range_end = 120.0
        imported_model_visible = true

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
        force_render_visibility()
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
            # Use actual imported locomotion, not the walking clip at running speed.
            # Smooth transitions and cadence reduce the visual foot-sliding effect.
            var chosen: StringName = anim_idle
            var reference_speed := 1.0
            if speed >= 4.7 and anim_sprint != &"":
                chosen = anim_sprint
                reference_speed = 5.2
            elif speed >= 2.25 and anim_run != &"":
                chosen = anim_run
                reference_speed = 3.2
            elif speed > .45 and anim_walk != &"":
                chosen = anim_walk
                reference_speed = 1.65
            if chosen != &"":
                if not imported_anim.is_playing() or imported_anim.current_animation != chosen:
                    imported_anim.play(chosen,.18)
                var desired_rate := clampf(speed / reference_speed,.75,1.35) if speed > .45 else 1.0
                imported_anim.speed_scale = lerpf(imported_anim.speed_scale,desired_rate,clampf(delta*5.0,0.0,1.0))
        else:
            # Detailed, unanimated mesh in the lobby: subtle breathing only.
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
