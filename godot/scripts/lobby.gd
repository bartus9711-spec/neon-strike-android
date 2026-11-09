extends CanvasLayer
## Responsive native Godot front-end inspired by the approved tactical UI reference.
## Every working button has an actual action; offline features are clearly labelled.
signal play_requested(index: int)
signal settings_requested()

const OPERATOR = preload("res://scripts/operative.gd")
const PROFILE_PATH := "user://teamcs_career.cfg"
var active := true
var root: Control
var map_picker: OptionButton
var status_text: Label
var balance_text: Label
var performance_text: Label
var profile_text: Label
var preview: SubViewport
var previews: Array[Node3D] = []
var preview_clock := 0.0
var credits := 650
var victories := 0
var matches := 0
var gear_variant := 0
var unlocked_variant := false

func _place(node: Control, x0: float, y0: float, x1: float, y1: float) -> void:
    node.anchor_left = x0
    node.anchor_top = y0
    node.anchor_right = x1
    node.anchor_bottom = y1
    node.offset_left = 0
    node.offset_top = 0
    node.offset_right = 0
    node.offset_bottom = 0

func _panel(parent: Control, x0: float, y0: float, x1: float, y1: float, tint: Color) -> Panel:
    var p := Panel.new()
    var style := StyleBoxFlat.new()
    style.bg_color = tint
    style.border_color = Color(.21,.27,.30,.9)
    style.set_border_width_all(1)
    style.set_corner_radius_all(6)
    p.add_theme_stylebox_override("panel",style)
    _place(p,x0,y0,x1,y1)
    parent.add_child(p)
    return p

func _text(parent: Control, value: String, size: int, tint: Color, x0: float, y0: float, x1: float, y1: float) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size",size)
    label.add_theme_color_override("font_color",tint)
    label.clip_text = true
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _place(label,x0,y0,x1,y1)
    parent.add_child(label)
    return label

func _button(parent: Control, value: String, x0: float, y0: float, x1: float, y1: float, highlight: bool = false) -> Button:
    var b := Button.new()
    b.text = value
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_font_size_override("font_size",19 if highlight else 15)
    b.add_theme_color_override("font_color",Color(.98,.98,.96))
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color(.60,.25,.19,.96) if highlight else Color(.12,.16,.19,.97)
    skin.border_color = Color(.85,.46,.33) if highlight else Color(.28,.35,.39)
    skin.set_border_width_all(1)
    skin.set_corner_radius_all(3)
    skin.content_margin_left = 10
    skin.content_margin_right = 10
    b.add_theme_stylebox_override("normal",skin)
    var hover := skin.duplicate() as StyleBoxFlat
    hover.bg_color = Color(.77,.33,.24) if highlight else Color(.20,.28,.32)
    b.add_theme_stylebox_override("hover",hover)
    b.add_theme_stylebox_override("pressed",hover)
    _place(b,x0,y0,x1,y1)
    parent.add_child(b)
    return b

func _ready() -> void:
    _load_career()
    root = Control.new()
    root.name = "MainMenu"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(root)
    var background := ColorRect.new()
    background.color = Color(.035,.052,.064,.98)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(background)
    _panel(root,0,0,1,.105,Color(.07,.095,.11))
    _text(root,"TEAM",33,Color(.93,.94,.95),.026,.006,.14,.099)
    _text(root,"CS",33,Color(.84,.23,.19),.137,.006,.20,.099)
    _text(root,"TAKTYCZNA GRA 4v4  /  ANDROID",13,Color(.64,.70,.72),.22,.03,.68,.08)
    profile_text = _text(root,"PROFIL  •  POZIOM 1",15,Color(.87,.90,.86),.71,.026,.89,.075)
    balance_text = _text(root,"",16,Color(.95,.76,.37),.87,.026,.99,.075)
    _panel(root,.012,.125,.245,.97,Color(.07,.094,.108,.98))
    _text(root,"CENTRUM OPERACJI",15,Color(.70,.75,.76),.032,.15,.23,.20)
    var navs := ["GRAJ","RANKINGOWA","TURNIEJE","EKWIPUNEK","SKRZYNKI","SKLEP","USTAWIENIA"]
    for idx in range(navs.size()):
        var item: String = navs[idx]
        var y := .225+float(idx)*.097
        var nav := _button(root,item,.029,y,.228,y+.075,idx==0)
        nav.pressed.connect(func(): _navigate(item))
    _panel(root,.253,.125,.744,.97,Color(.085,.105,.112,.97))
    _text(root,"WYJDŹ NA ARENĘ",25,Color(.98,.98,.95),.27,.145,.60,.21)
    _text(root,"DWA ZESPOŁY  •  BOTY  •  AUTORSKIE MAPY",13,Color(.72,.79,.77),.27,.21,.72,.26)
    _stage()
    _text(root,"OPERATOR CT",15,Color(.67,.83,.88),.29,.82,.47,.865)
    _text(root,"OPERATOR T",15,Color(.89,.73,.58),.53,.82,.70,.865)
    _text(root,"ŻYWE MODELE GODOT 3D  •  PODGLĄD",12,Color(.71,.72,.74),.28,.905,.71,.945)
    _panel(root,.75,.125,.986,.97,Color(.07,.094,.108,.98))
    _text(root,"WYBIERZ MAPĘ",17,Color(.96,.95,.90),.765,.148,.98,.20)
    map_picker = OptionButton.new()
    _place(map_picker,.77,.218,.974,.294)
    root.add_child(map_picker)
    _text(root,"SZYBKA GRA",18,Color(.94,.96,.92),.765,.32,.97,.38)
    _text(root,"OFFLINE  •  4v4\nSiedmiu botów  •  8 map",14,Color(.64,.77,.78),.765,.38,.975,.48)
    _button(root,"▶  ROZPOCZNIJ",.766,.50,.973,.61,true).pressed.connect(_play)
    _text(root,"KARIERA / WYPOSAŻENIE",14,Color(.82,.86,.82),.766,.65,.975,.70)
    status_text = _text(root,"",13,Color(.84,.83,.73),.765,.71,.973,.80)
    status_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _button(root,"ODKRYJ STRÓJ  ·  300",.766,.84,.973,.92).pressed.connect(_purchase_gear)
    _refresh_header()
    _show_message("Wybierz arenę i rozpocznij mecz.")

func _stage() -> void:
    var frame := SubViewportContainer.new()
    frame.name = "Operator3DPreview"
    frame.stretch = true
    frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _place(frame,.268,.27,.732,.825)
    root.add_child(frame)
    preview = SubViewport.new()
    preview.size = Vector2i(700,540)
    preview.transparent_bg = true
    preview.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
    preview.own_world_3d = true
    frame.add_child(preview)
    var world := Node3D.new()
    preview.add_child(world)
    var ambient := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_CLEAR_COLOR
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(.50,.61,.68)
    env.ambient_light_energy = .65
    ambient.environment = env
    world.add_child(ambient)
    var lamp := DirectionalLight3D.new()
    lamp.rotation_degrees = Vector3(-39,-30,-20)
    lamp.light_color = Color(.99,.86,.66)
    lamp.light_energy = 2.0
    world.add_child(lamp)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-18,140,0)
    fill.light_color = Color(.55,.75,.96)
    fill.light_energy = 1.1
    world.add_child(fill)
    var camera := Camera3D.new()
    camera.position = Vector3(0,1.29,-3.50)
    camera.fov = 47.0
    camera.current = true
    world.add_child(camera)
    camera.look_at(Vector3(0,1.03,0),Vector3.UP)
    # A muted urban set, placed behind the live 3D operators. No neon effects.
    _stage_block(world,Vector3(0,-.19,1.25),Vector3(8.0,.23,7.0),Color(.22,.23,.22))
    _stage_block(world,Vector3(-2.85,2.25,2.75),Vector3(2.5,4.5,1.0),Color(.48,.44,.37))
    _stage_block(world,Vector3(2.88,2.1,3.2),Vector3(2.45,4.2,1.25),Color(.43,.41,.38))
    _stage_block(world,Vector3(0,2.7,4.5),Vector3(5.0,5.4,.6),Color(.34,.33,.31))
    _stage_block(world,Vector3(-2.73,.74,2.15),Vector3(.16,1.8,.7),Color(.28,.29,.28))
    _stage_block(world,Vector3(2.67,.72,2.50),Vector3(.16,1.8,.7),Color(.24,.26,.27))
    for tower in range(4):
        var bx := -2.30+float(tower)*1.5
        _stage_block(world,Vector3(bx,1.86,3.85),Vector3(.54,1.26,.09),Color(.16,.22,.25))
        _stage_block(world,Vector3(bx,2.56,3.82),Vector3(.65,.08,.13),Color(.74,.68,.59))
    for team in range(2):
        var actor = OPERATOR.new()
        # Camera looks in +Z, so world X is horizontally mirrored on screen.
        actor.position = Vector3(.76 if team==0 else -.76,-.10,0.12)
        actor.rotation.y = -.17 if team==0 else .21
        world.add_child(actor)
        actor.build(team,1+gear_variant if team==0 else 2,2)
        previews.append(actor)

func _stage_block(world: Node3D, p: Vector3, dimensions: Vector3, color: Color) -> void:
    var node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    node.mesh = mesh
    node.position = p
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = .96
    # Reuse the same CC0 wall and paving textures as the actual arenas.
    var image_path := "res://assets/painted_plaster_wall_diff.jpg" if dimensions.y >= 2.0 else "res://assets/asphalt_01_diff.jpg" if dimensions.x > 6.0 else ""
    if image_path != "" and ResourceLoader.exists(image_path):
        material.albedo_texture = load(image_path)
        material.albedo_color = color.lightened(.28)
        material.uv1_triplanar = true
        material.uv1_world_triplanar = true
        material.uv1_scale = Vector3(.43,.43,.43)
    node.material_override = material
    world.add_child(node)

func configure(maps: Array) -> void:
    if not is_instance_valid(map_picker):
        return
    map_picker.clear()
    for entry in maps:
        map_picker.add_item(str(entry.get("name","ARENA")))
    if map_picker.item_count>0:
        map_picker.select(0)

func _navigate(item: String) -> void:
    match item:
        "GRAJ":
            _show_message("Wybierz mapę i kliknij ROZPOCZNIJ.")
        "RANKINGOWA":
            _show_message("Ranking online: wymaga serwera. Nie jest aktywny.")
        "TURNIEJE":
            _show_message("Turnieje online: wymagany serwer.")
        "EKWIPUNEK":
            _show_message("Strój: %s  |  mecze %d, wygrane %d" % ["TAKTYCZNY" if gear_variant == 0 else "WARIANT 2",matches,victories])
        "SKRZYNKI":
            _show_message("Kosmetyczne odblokowanie za punkty z gry: 300.")
        "SKLEP":
            _show_message("Punkty zdobywasz w meczach z botami. Bez mikropłatności.")
        "USTAWIENIA":
            settings_requested.emit()

func _play() -> void:
    if map_picker.item_count == 0:
        _show_message("Nie znaleziono żadnej mapy.")
        return
    active = false
    root.hide()
    play_requested.emit(map_picker.selected)

func show_lobby() -> void:
    active = true
    root.show()
    _refresh_header()

func hide_lobby() -> void:
    active = false
    root.hide()

func _show_message(value: String) -> void:
    if is_instance_valid(status_text):
        status_text.text = value

func _refresh_header() -> void:
    if not is_instance_valid(balance_text):
        return
    balance_text.text = "%d PKT" % credits
    profile_text.text = "PROFIL  •  %d MECZÓW" % matches

func _purchase_gear() -> void:
    if not unlocked_variant:
        if credits < 300:
            _show_message("Za mało punktów. Graj mecze offline.")
            return
        credits -= 300
        unlocked_variant = true
    gear_variant = 0 if gear_variant != 0 else 1
    if previews.size() > 0 and is_instance_valid(previews[0]):
        var prior: Node3D = previews[0]
        var host: Node = prior.get_parent()
        var new_operator = OPERATOR.new()
        new_operator.position = prior.position
        new_operator.rotation = prior.rotation
        host.add_child(new_operator)
        new_operator.build(0,1+gear_variant,2)
        prior.queue_free()
        previews[0] = new_operator
    _show_message("Wybrany strój: %s" % ("TAKTYCZNY" if gear_variant==0 else "WARIANT 2"))
    _save_career()
    _refresh_header()

func award_match(won: bool) -> void:
    matches += 1
    if won:
        victories += 1
    credits += 120 if won else 45
    _save_career()
    _refresh_header()

func refresh_stats() -> void:
    _refresh_header()
    _show_message("MECZE %d  •  WYGRANE %d  •  %d PKT" % [matches,victories,credits])

func _save_career() -> void:
    var file := ConfigFile.new()
    file.set_value("career","credits",credits)
    file.set_value("career","matches",matches)
    file.set_value("career","victories",victories)
    file.set_value("career","gear",gear_variant)
    file.set_value("career","gear_unlocked",unlocked_variant)
    file.save(PROFILE_PATH)

func _load_career() -> void:
    var file := ConfigFile.new()
    if file.load(PROFILE_PATH) != OK:
        return
    credits = maxi(0,int(file.get_value("career","credits",650)))
    matches = maxi(0,int(file.get_value("career","matches",0)))
    victories = clampi(int(file.get_value("career","victories",0)),0,matches)
    unlocked_variant = bool(file.get_value("career","gear_unlocked",false))
    gear_variant = clampi(int(file.get_value("career","gear",0)),0,1) if unlocked_variant else 0

func _process(delta: float) -> void:
    if not active:
        return
    preview_clock += delta
    for i in range(previews.size()):
        if is_instance_valid(previews[i]):
            previews[i].update_pose(.25+absf(sin(preview_clock*.6+float(i)))*.15,delta,0.0)
