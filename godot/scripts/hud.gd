extends CanvasLayer
## Responsive mobile HUD: virtual thumbstick, right-side look swipe and wired / Bluetooth pad support.
signal jump_requested
signal action_requested
signal graphics_changed(profile: int, fps: int, scale: float, shadows: bool, aa: int)
signal map_requested(index: int)
signal graphics_advanced_changed(textures_enabled: bool, world_detail: int, actor_quality: int)
signal network_mode_changed(enabled: bool)
signal pulse_requested
signal recharge_requested
signal restart_requested

var touch_move := Vector2.ZERO
var look_sensitivity := 1.0
var pad_deadzone := .16
var invert_look_y := false
var sprint_enabled := false
var pulse_held := false
var match_label: Label
var shield_label: Label
var power_label: Label
var reticle_label: Label
var reticle_marks: Array[ColorRect] = []
var hit_label: Label
var hit_feedback_time := 0.0
var _rival_target := false
var restart_button: Button
var settings_open := false
var current_fps := 0
var _left_pointer := -1
var _right_pointer := -1
var _left_origin := Vector2.ZERO
var _left_pos := Vector2.ZERO
var _pending_look := Vector2.ZERO
var _message_left := 0.0
var _fps_timer := 0.0
var _last_position := Vector3.ZERO
var _beacons_collected := 0
var _beacons_total := 4

var ui: Control
var status_label: Label
var map_select: OptionButton
var map_title := "NABRZEŻE 17"
var fps_label: Label
var network_label: Label
var ping_label: Label
var hint_label: Label
var touch_base: Panel
var touch_knob: Panel
var settings_panel: PanelContainer
var settings_button: Button
var profile_select: OptionButton
var fps_select: OptionButton
var scale_slider: HSlider
var shadow_toggle: CheckButton
var aa_select: OptionButton
var sensitivity_slider: HSlider
var settings_scale_label: Label
var texture_toggle: CheckButton
var detail_select: OptionButton
var actor_select: OptionButton
var network_toggle: CheckButton
var pad_dead_slider: HSlider
var invert_toggle: CheckButton

var _profile := 1
var _fps := 60
var _scale := .90
var _shadows := true
var _aa := 2
var _setting_up := true

func _ready() -> void:
    ui = Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(ui)
    var bar := ColorRect.new()
    bar.color = Color(0.035, 0.065, 0.100, .81)
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bar.anchor_right = 1
    bar.offset_bottom = 57
    ui.add_child(bar)
    status_label = _label("TEAMCS 3D  |  ARENA MIEJSKA", 17, Color(.92,.96,1))
    status_label.position = Vector2(22, 9)
    status_label.size = Vector2(680, 46)
    ui.add_child(status_label)
    match_label = _label("CYAN  00  :  00  MAGENTA", 20, Color(.82,.98,1))
    match_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
    match_label.anchor_left = .46
    match_label.anchor_right = .46
    match_label.position = Vector2(-105,7)
    match_label.size = Vector2(300,42)
    ui.add_child(match_label)
    var combat_panel := Panel.new()
    combat_panel.name = "CombatVitalsPanel"
    combat_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    combat_panel.anchor_left = .5
    combat_panel.anchor_right = .5
    combat_panel.anchor_top = 1.
    combat_panel.anchor_bottom = 1.
    combat_panel.offset_left = -146
    combat_panel.offset_right = 146
    combat_panel.offset_top = -90
    combat_panel.offset_bottom = -4
    var combat_style := StyleBoxFlat.new()
    combat_style.bg_color = Color(.035,.075,.10,.79)
    combat_style.border_color = Color(.12,.68,.73,.60)
    combat_style.set_border_width_all(1)
    combat_style.set_corner_radius_all(9)
    combat_panel.add_theme_stylebox_override("panel",combat_style)
    ui.add_child(combat_panel)
    shield_label = _label("OSŁONA 100%", 19, Color(.59,.97,1))
    shield_label.anchor_top = 1
    shield_label.anchor_bottom = 1
    shield_label.anchor_left = .5
    shield_label.anchor_right = .5
    shield_label.position = Vector2(-127,-46)
    shield_label.size = Vector2(254,33)
    shield_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    ui.add_child(shield_label)
    power_label = _label("ENERGIA 24 / 24", 18, Color(1,.89,.55))
    power_label.anchor_top = 1
    power_label.anchor_bottom = 1
    power_label.anchor_left = .5
    power_label.anchor_right = .5
    power_label.position = Vector2(-127,-76)
    power_label.size = Vector2(254,32)
    power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    ui.add_child(power_label)
    map_select = OptionButton.new()
    map_select.name = "EightMapPicker"
    map_select.position = Vector2(15, 66)
    map_select.custom_minimum_size = Vector2(266, 38)
    map_select.add_theme_font_size_override("font_size", 16)
    map_select.item_selected.connect(func(index: int): map_requested.emit(index))
    ui.add_child(map_select)
    fps_label = _label("FPS ...", 18, Color(.67,1,.91))
    fps_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    fps_label.position = Vector2(-225, 10)
    fps_label.size = Vector2(95, 40)
    ui.add_child(fps_label)
    var network_panel := Panel.new()
    network_panel.name = "NetworkInformationPanel"
    network_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    network_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    network_panel.position = Vector2(-396,60)
    network_panel.size = Vector2(258,57)
    var network_style := StyleBoxFlat.new()
    network_style.bg_color = Color(.035,.075,.12,.62)
    network_style.set_corner_radius_all(6)
    network_panel.add_theme_stylebox_override("panel",network_style)
    ui.add_child(network_panel)
    network_label = _label("SIEĆ: SYSTEM", 12, Color(.78,.91,.92))
    network_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    network_label.position = Vector2(-392, 62)
    network_label.size = Vector2(253, 26)
    ui.add_child(network_label)
    ping_label = _label("PING: —", 12, Color(.82,.90,.97))
    ping_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    ping_label.position = Vector2(-392, 86)
    ping_label.size = Vector2(253, 26)
    ui.add_child(ping_label)
    settings_button = _button("⚙ GRAFIKA")
    settings_button.anchor_left = 1
    settings_button.anchor_right = 1
    settings_button.offset_left = -126
    settings_button.offset_right = -8
    settings_button.offset_top = 6
    settings_button.offset_bottom = 49
    settings_button.pressed.connect(toggle_settings)
    ui.add_child(settings_button)
    hint_label = _label("", 16, Color(1.0,.91,.65))
    hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint_label.anchor_left = .18
    hint_label.anchor_right = .82
    hint_label.anchor_top = 1
    hint_label.anchor_bottom = 1
    hint_label.offset_top = -137
    hint_label.offset_bottom = -109
    ui.add_child(hint_label)
    _make_controls()
    _make_settings()
    _load_prefs()
    get_viewport().size_changed.connect(_layout_controls)
    _layout_controls()
    _setting_up = false
    _emit_graphics()

func _label(value: String, font: int, tint: Color) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size", font)
    label.add_theme_color_override("font_color", tint)
    label.add_theme_color_override("font_shadow_color", Color(.0,.0,.0,.7))
    label.add_theme_constant_override("shadow_offset_x", 1)
    label.add_theme_constant_override("shadow_offset_y", 2)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return label

func _button(value: String) -> Button:
    var b := Button.new()
    b.text = value
    b.add_theme_font_size_override("font_size", 17)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(.07,.16,.22,.79)
    style.border_color = Color(.36,.75,.78,.75)
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    style.content_margin_left = 10
    style.content_margin_right = 10
    b.add_theme_stylebox_override("normal", style)
    var pressed := style.duplicate()
    pressed.bg_color = Color(.10,.38,.43,.94)
    b.add_theme_stylebox_override("pressed", pressed)
    return b

func _make_controls() -> void:
    touch_base = Panel.new()
    var base_style := StyleBoxFlat.new()
    base_style.bg_color = Color(.10,.23,.32,.26)
    base_style.border_color = Color(.39,.84,.85,.57)
    base_style.set_border_width_all(2)
    base_style.set_corner_radius_all(999)
    touch_base.add_theme_stylebox_override("panel",base_style)
    touch_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(touch_base)
    touch_knob = Panel.new()
    var knob_style := StyleBoxFlat.new()
    knob_style.bg_color = Color(.22,.64,.69,.39)
    knob_style.border_color = Color(.66,.98,.99,.72)
    knob_style.set_border_width_all(2)
    knob_style.set_corner_radius_all(999)
    touch_knob.add_theme_stylebox_override("panel",knob_style)
    touch_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(touch_knob)
    # Crisp, symmetrical four-segment reticle and a central phosphor dot.
    reticle_label = _label("·", 24, Color(.70,1,.98,.95))
    reticle_label.set_anchors_preset(Control.PRESET_CENTER)
    reticle_label.position = Vector2(-5,-17)
    ui.add_child(reticle_label)
    var segments := [
        Rect2(-1,-19,2,10),
        Rect2(-1,9,2,10),
        Rect2(-19,-1,10,2),
        Rect2(9,-1,10,2)
    ]
    for rect in segments:
        var mark := ColorRect.new()
        mark.color = Color(.66,.96,1,.92)
        mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
        mark.anchor_left = .5
        mark.anchor_right = .5
        mark.anchor_top = .5
        mark.anchor_bottom = .5
        mark.offset_left = rect.position.x
        mark.offset_top = rect.position.y
        mark.offset_right = rect.position.x+rect.size.x
        mark.offset_bottom = rect.position.y+rect.size.y
        ui.add_child(mark)
        reticle_marks.append(mark)
    hit_label = _label("TRAFIENIE +1", 17, Color(.45,1,.87))
    hit_label.set_anchors_preset(Control.PRESET_CENTER)
    hit_label.position = Vector2(27,-38)
    hit_label.visible = false
    ui.add_child(hit_label)
    var jump := _button("SKOK  ↑")
    jump.name = "Jump"
    jump.pressed.connect(func(): jump_requested.emit())
    jump.anchor_left = 1
    jump.anchor_right = 1
    jump.anchor_top = 1
    jump.anchor_bottom = 1
    jump.offset_left = -124
    jump.offset_right = -16
    jump.offset_top = -166
    jump.offset_bottom = -111
    ui.add_child(jump)
    var action := _button("SKAN  ◈")
    action.name = "Action"
    action.pressed.connect(func(): action_requested.emit())
    action.anchor_left = 1
    action.anchor_right = 1
    action.anchor_top = 1
    action.anchor_bottom = 1
    action.offset_left = -124
    action.offset_right = -16
    action.offset_top = -100
    action.offset_bottom = -45
    ui.add_child(action)
    var pulse := _button("PULS  ⚡")
    pulse.name = "Pulse"
    pulse.add_theme_font_size_override("font_size",22)
    pulse.button_down.connect(func(): pulse_held = true; pulse_requested.emit())
    pulse.button_up.connect(func(): pulse_held = false)
    pulse.anchor_left = 1
    pulse.anchor_right = 1
    pulse.anchor_top = 1
    pulse.anchor_bottom = 1
    pulse.offset_left = -260
    pulse.offset_right = -136
    pulse.offset_top = -114
    pulse.offset_bottom = -23
    ui.add_child(pulse)
    var recharge := _button("ŁADUJ  ↻")
    recharge.name = "Recharge"
    recharge.pressed.connect(func(): recharge_requested.emit())
    recharge.anchor_left = 1
    recharge.anchor_right = 1
    recharge.anchor_top = 1
    recharge.anchor_bottom = 1
    recharge.offset_left = -260
    recharge.offset_right = -136
    recharge.offset_top = -166
    recharge.offset_bottom = -118
    ui.add_child(recharge)
    var sprint := _button("BIEG")
    sprint.name = "Sprint"
    sprint.toggle_mode = true
    sprint.toggled.connect(func(on: bool): sprint_enabled = on)
    sprint.anchor_left = 0
    sprint.anchor_right = 0
    sprint.anchor_top = 1
    sprint.anchor_bottom = 1
    sprint.offset_left = 177
    sprint.offset_right = 255
    sprint.offset_top = -97
    sprint.offset_bottom = -48
    ui.add_child(sprint)

func _layout_controls() -> void:
    var size := get_viewport().get_visible_rect().size
    if not is_instance_valid(touch_base):
        return
    var radius := clampf(size.y * .117, 45.0, 88.0)
    _left_origin = Vector2(radius + 42, size.y - radius - 32)
    touch_base.position = _left_origin - Vector2.ONE * radius
    touch_base.size = Vector2.ONE * radius * 2
    touch_knob.size = Vector2.ONE * radius * .81
    touch_knob.position = _left_origin - touch_knob.size / 2
    if is_instance_valid(settings_panel):
        # 390px-tall landscape screens need a compact scrolling dialog.
        var half_width: float = minf(260.0,size.x * .455)
        var half_height: float = minf(290.0,size.y * .465)
        settings_panel.offset_left = -half_width
        settings_panel.offset_right = half_width
        settings_panel.offset_top = -half_height
        settings_panel.offset_bottom = half_height
    var portrait := size.x < size.y
    if portrait:
        hint_label.visible = false
    else:
        hint_label.visible = true

func _input(event: InputEvent) -> void:
    if settings_open:
        return
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            if touch.position.x < get_viewport().get_visible_rect().size.x * .41 and _left_pointer == -1:
                _left_pointer = touch.index
                _left_pos = touch.position
                _refresh_stick()
            elif _right_pointer == -1:
                _right_pointer = touch.index
        else:
            if touch.index == _left_pointer:
                _left_pointer = -1
                touch_move = Vector2.ZERO
                _refresh_stick()
            elif touch.index == _right_pointer:
                _right_pointer = -1
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == _left_pointer:
            _left_pos = drag.position
            _refresh_stick()
        elif drag.index == _right_pointer:
            _pending_look += drag.relative

func _refresh_stick() -> void:
    var radius := touch_base.size.x * .46
    var displacement := (_left_pos - _left_origin).limit_length(radius) if _left_pointer >= 0 else Vector2.ZERO
    touch_move = displacement / radius
    touch_knob.position = _left_origin + displacement - touch_knob.size / 2

func consume_look() -> Vector2:
    var answer := _pending_look
    _pending_look = Vector2.ZERO
    return answer

func _make_settings() -> void:
    settings_panel = PanelContainer.new()
    settings_panel.name = "GraphicsSettings"
    settings_panel.anchor_left = .5
    settings_panel.anchor_right = .5
    settings_panel.anchor_top = .5
    settings_panel.anchor_bottom = .5
    settings_panel.offset_left = -260
    settings_panel.offset_right = 260
    settings_panel.offset_top = -290
    settings_panel.offset_bottom = 290
    var frame := StyleBoxFlat.new()
    frame.bg_color = Color(.055,.105,.148,.98)
    frame.border_color = Color(.31,.71,.71,.8)
    frame.set_border_width_all(2)
    frame.set_corner_radius_all(13)
    settings_panel.add_theme_stylebox_override("panel", frame)
    ui.add_child(settings_panel)
    var scroll := ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    settings_panel.add_child(scroll)
    var v := VBoxContainer.new()
    v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    v.add_theme_constant_override("separation", 9)
    scroll.add_child(v)
    var title := _label("TEAMCS 3D  ·  GRAFIKA I STEROWANIE", 23, Color(.95,.99,.98))
    v.add_child(title)
    v.add_child(_label("Jakość obrazu", 15, Color(.58,.79,.83)))
    profile_select = OptionButton.new()
    for label in ["PŁYNNOŚĆ", "WYSOKA", "ULTRA"]:
        profile_select.add_item(label)
    profile_select.selected = 1
    v.add_child(profile_select)
    v.add_child(_label("Docelowe FPS", 15, Color(.58,.79,.83)))
    fps_select = OptionButton.new()
    for option in [30, 60, 90, 120]:
        fps_select.add_item("%d FPS" % option, option)
    fps_select.select(1)
    v.add_child(fps_select)
    settings_scale_label = _label("Rozdzielczość 3D: 100%", 15, Color(.58,.79,.83))
    v.add_child(settings_scale_label)
    scale_slider = HSlider.new()
    scale_slider.min_value = .60
    scale_slider.max_value = 1.00
    scale_slider.step = .05
    scale_slider.value = .90
    v.add_child(scale_slider)
    shadow_toggle = CheckButton.new()
    shadow_toggle.text = "Cienie dynamiczne"
    shadow_toggle.button_pressed = true
    v.add_child(shadow_toggle)
    v.add_child(_label("Wygładzanie krawędzi", 15, Color(.58,.79,.83)))
    aa_select = OptionButton.new()
    for item in ["WYŁ.", "MSAA 2×", "MSAA 4×"]:
        aa_select.add_item(item)
    aa_select.select(1)
    v.add_child(aa_select)
    texture_toggle = CheckButton.new()
    texture_toggle.text = "Tekstury PBR — wyłącz na słabym telefonie"
    texture_toggle.button_pressed = true
    v.add_child(texture_toggle)
    v.add_child(_label("Detale otoczenia",15,Color(.58,.79,.83)))
    detail_select = OptionButton.new()
    for item in ["LOW — bez dodatków i świateł punktowych","HIGH — dodatki, mniej świateł","ULTRA — pełne efekty"]:
        detail_select.add_item(item)
    detail_select.select(1)
    v.add_child(detail_select)
    v.add_child(_label("Jakość postaci (dla przyszłych modeli 3D)",15,Color(.58,.79,.83)))
    actor_select = OptionButton.new()
    for item in ["LOW — oszczędna geometria","HIGH — normalna","ULTRA — pełna"]:
        actor_select.add_item(item)
    actor_select.select(1)
    v.add_child(actor_select)
    v.add_child(_label("Czułość kamery", 15, Color(.58,.79,.83)))
    sensitivity_slider = HSlider.new()
    sensitivity_slider.min_value = .40
    sensitivity_slider.max_value = 2.40
    sensitivity_slider.step = .10
    sensitivity_slider.value = 1.0
    v.add_child(sensitivity_slider)
    v.add_child(_label("Martwa strefa gałek pada",15,Color(.58,.79,.83)))
    pad_dead_slider = HSlider.new()
    pad_dead_slider.min_value = .06
    pad_dead_slider.max_value = .35
    pad_dead_slider.step = .01
    pad_dead_slider.value = .16
    v.add_child(pad_dead_slider)
    invert_toggle = CheckButton.new()
    invert_toggle.text = "Odwróć oś Y rozglądania"
    v.add_child(invert_toggle)
    v.add_child(_label("INTERNET / WI-FI / DANE",18,Color(.92,.96,1)))
    network_toggle = CheckButton.new()
    network_toggle.text = "Auto — wybierz lepsze łącze DLA GRY (eksperymentalne)"
    v.add_child(network_toggle)
    v.add_child(_label("Wymaga wtyczki Android. Dane komórkowe mogą kosztować; nie zmienia ustawień całego telefonu.",12,Color(.76,.80,.81)))
    v.add_child(_label("PING to serwer gry jest dostępny dopiero po uruchomieniu multiplayera.",12,Color(.76,.80,.81)))
    v.add_child(_label("120 FPS to cel: zależy od GPU, ekranu i limitów systemu.", 12, Color(.77,.81,.78)))
    var close := _button("ZAPISZ I WRÓĆ")
    close.pressed.connect(toggle_settings)
    v.add_child(close)
    for control in [fps_select, scale_slider, shadow_toggle, aa_select, sensitivity_slider, pad_dead_slider, texture_toggle, detail_select, actor_select, invert_toggle, network_toggle]:
        if control is Range:
            control.value_changed.connect(func(_new: float): _emit_graphics())
        elif control is BaseButton and not control is OptionButton:
            control.toggled.connect(func(_on: bool): _emit_graphics())
        else:
            control.item_selected.connect(func(_idx: int): _emit_graphics())
    profile_select.item_selected.connect(_on_profile_selected)
    settings_panel.visible = false

func _on_profile_selected(idx: int) -> void:
    # Profiles set practical defaults; every option remains individually editable.
    _setting_up = true
    if idx == 0:
        scale_slider.value = .70
        aa_select.select(0)
        shadow_toggle.button_pressed = false
        texture_toggle.button_pressed = false
        detail_select.select(0)
        actor_select.select(0)
        fps_select.select(1)
    elif idx == 1:
        scale_slider.value = .90
        aa_select.select(1)
        shadow_toggle.button_pressed = true
        texture_toggle.button_pressed = true
        detail_select.select(1)
        actor_select.select(1)
        fps_select.select(1)
    else:
        scale_slider.value = 1.0
        aa_select.select(2)
        shadow_toggle.button_pressed = true
        texture_toggle.button_pressed = true
        detail_select.select(2)
        actor_select.select(2)
        fps_select.select(3)
    _setting_up = false
    _emit_graphics()

func set_network_info(network_text: String, ping_text: String) -> void:
    if is_instance_valid(network_label):
        network_label.text = "SIEĆ: " + network_text
    if is_instance_valid(ping_label):
        ping_label.text = "PING: " + ping_text

func _emit_graphics() -> void:
    if _setting_up:
        return
    _profile = profile_select.selected
    _fps = fps_select.get_selected_id()
    _scale = scale_slider.value
    _shadows = shadow_toggle.button_pressed
    _aa = 0 if aa_select.selected == 0 else 2 if aa_select.selected == 1 else 4
    look_sensitivity = sensitivity_slider.value
    pad_deadzone = pad_dead_slider.value
    invert_look_y = invert_toggle.button_pressed
    settings_scale_label.text = "Rozdzielczość 3D: %d%%" % roundi(_scale * 100)
    _save_prefs()
    graphics_changed.emit(_profile, _fps, _scale, _shadows, _aa)
    graphics_advanced_changed.emit(texture_toggle.button_pressed, detail_select.selected, actor_select.selected)
    network_mode_changed.emit(network_toggle.button_pressed)

func _save_prefs() -> void:
    var save := ConfigFile.new()
    save.set_value("render", "profile", _profile)
    save.set_value("render", "fps", _fps)
    save.set_value("render", "scale", _scale)
    save.set_value("render", "shadows", _shadows)
    save.set_value("render", "aa", aa_select.selected)
    save.set_value("render", "textures", texture_toggle.button_pressed)
    save.set_value("render", "detail", detail_select.selected)
    save.set_value("render", "actors", actor_select.selected)
    save.set_value("network", "app_auto_switch", network_toggle.button_pressed)
    save.set_value("input", "sensitivity", look_sensitivity)
    save.set_value("input", "deadzone", pad_deadzone)
    save.set_value("input", "invert_y", invert_look_y)
    save.save("user://teamcs-graphics.cfg")

func _load_prefs() -> void:
    var save := ConfigFile.new()
    if save.load("user://teamcs-graphics.cfg") != OK:
        return
    profile_select.select(clampi(int(save.get_value("render","profile",1)),0,2))
    var fps := int(save.get_value("render","fps",60))
    fps_select.select([30,60,90,120].find(fps) if [30,60,90,120].has(fps) else 3)
    scale_slider.value = clampf(float(save.get_value("render","scale",.90)),.6,1.0)
    shadow_toggle.button_pressed = bool(save.get_value("render","shadows",true))
    aa_select.select(clampi(int(save.get_value("render","aa",1)),0,2))
    texture_toggle.button_pressed = bool(save.get_value("render","textures",true))
    detail_select.select(clampi(int(save.get_value("render","detail",1)),0,2))
    actor_select.select(clampi(int(save.get_value("render","actors",1)),0,2))
    network_toggle.button_pressed = bool(save.get_value("network","app_auto_switch",false))
    pad_dead_slider.value = clampf(float(save.get_value("input","deadzone",.16)),.06,.35)
    invert_toggle.button_pressed = bool(save.get_value("input","invert_y",false))
    sensitivity_slider.value = clampf(float(save.get_value("input","sensitivity",1)),.4,2.4)

func toggle_settings() -> void:
    settings_open = not settings_open
    settings_panel.visible = settings_open
    touch_move = Vector2.ZERO
    _left_pointer = -1
    _right_pointer = -1
    _pending_look = Vector2.ZERO
    pulse_held = false
    _refresh_stick()
    if settings_open:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    else:
        _emit_graphics()

func set_target_state(rival: bool) -> void:
    _rival_target = rival
    var tint := Color(1.0,.56,.58,.97) if rival else Color(.66,.96,1.0,.92)
    if hit_feedback_time > 0.0:
        tint = Color(.46,1.0,.78)
    if is_instance_valid(reticle_label):
        reticle_label.add_theme_color_override("font_color",tint)
    for mark in reticle_marks:
        if is_instance_valid(mark):
            mark.color = tint

func flash_hit() -> void:
    hit_feedback_time = .46
    if is_instance_valid(hit_label):
        hit_label.visible = true
    set_target_state(_rival_target)

func set_combat_state(cyan: int, magenta: int, shield: int, power: int, capacity: int, time_left: float) -> void:
    if is_instance_valid(match_label):
        var minutes := int(time_left) / 60
        var seconds := int(time_left) % 60
        match_label.text = "CYAN %02d : %02d RÓŻ  •  %d:%02d" % [cyan,magenta,minutes,seconds]
    if is_instance_valid(shield_label):
        shield_label.text = "OSŁONA %d%%" % maxi(0,shield)
        shield_label.add_theme_color_override("font_color", Color(.92,.43,.41) if shield <= 25 else Color(.59,.97,1))
    if is_instance_valid(power_label):
        power_label.text = "ENERGIA %d / %d" % [power,capacity]

func set_status(done: int, total: int, where: Vector3) -> void:
    _beacons_collected = done
    _beacons_total = total
    _last_position = where

func set_message(value: String, seconds: float) -> void:
    hint_label.text = value
    hint_label.visible = true
    _message_left = seconds

func configure_maps(options: Array) -> void:
    map_select.clear()
    for entry in options:
        map_select.add_item(str(entry.get("name", "ARENA")))
    if map_select.item_count > 0:
        map_select.select(0)

func set_map(index: int, name: String) -> void:
    map_title = name
    if map_select.item_count > index and index >= 0:
        map_select.select(index)
    set_message("ARENA %d / 8  ·  %s" % [index+1, name], 2.4)

func _process(delta: float) -> void:
    if hit_feedback_time > 0.0:
        hit_feedback_time = maxf(0.0,hit_feedback_time-delta)
        if hit_feedback_time == 0.0:
            if is_instance_valid(hit_label):
                hit_label.visible = false
            set_target_state(_rival_target)
    _fps_timer += delta
    if _fps_timer >= .4:
        current_fps = roundi(Engine.get_frames_per_second())
        fps_label.text = "%d FPS" % current_fps
        fps_label.add_theme_color_override("font_color", Color(.67,1,.91) if current_fps >= _fps * .80 else Color(1,.77,.49))
        status_label.text = "TEAMCS 3D   |   %s   |   ◈ %d/%d" % [map_title, _beacons_collected, _beacons_total]
        _fps_timer = 0
    if _message_left > 0:
        _message_left -= delta
        if _message_left <= 0:
            hint_label.text = ""
            hint_label.visible = false
