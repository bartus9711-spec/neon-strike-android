extends CanvasLayer
## Responsive mobile HUD: virtual thumbstick, right-side look swipe and wired / Bluetooth pad support.
signal jump_requested
signal action_requested
signal graphics_changed(profile: int, fps: int, scale: float, shadows: bool, aa: int)
signal map_requested(index: int)
signal graphics_advanced_changed(textures_enabled: bool, world_detail: int, actor_quality: int)
signal network_mode_changed(enabled: bool)

var touch_move := Vector2.ZERO
var look_sensitivity := 1.0
var pad_deadzone := .16
var invert_look_y := false
var sprint_enabled := false
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

var _profile := 2
var _fps := 120
var _scale := 1.0
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
    hint_label.offset_top = -88
    hint_label.offset_bottom = -52
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
    var cross := _label("+", 24, Color(.78,1,.95,.75))
    cross.set_anchors_preset(Control.PRESET_CENTER)
    cross.position = Vector2(-9,-17)
    ui.add_child(cross)
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
    var action := _button("ZBIERZ  ◈")
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
    profile_select.selected = 2
    v.add_child(profile_select)
    v.add_child(_label("Docelowe FPS", 15, Color(.58,.79,.83)))
    fps_select = OptionButton.new()
    for option in [30, 60, 90, 120]:
        fps_select.add_item("%d FPS" % option, option)
    fps_select.select(3)
    v.add_child(fps_select)
    settings_scale_label = _label("Rozdzielczość 3D: 100%", 15, Color(.58,.79,.83))
    v.add_child(settings_scale_label)
    scale_slider = HSlider.new()
    scale_slider.min_value = .60
    scale_slider.max_value = 1.00
    scale_slider.step = .05
    scale_slider.value = 1.00
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
    detail_select.select(2)
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
    profile_select.select(clampi(int(save.get_value("render","profile",2)),0,2))
    var fps := int(save.get_value("render","fps",120))
    fps_select.select([30,60,90,120].find(fps) if [30,60,90,120].has(fps) else 3)
    scale_slider.value = clampf(float(save.get_value("render","scale",1.0)),.6,1.0)
    shadow_toggle.button_pressed = bool(save.get_value("render","shadows",true))
    aa_select.select(clampi(int(save.get_value("render","aa",1)),0,2))
    texture_toggle.button_pressed = bool(save.get_value("render","textures",true))
    detail_select.select(clampi(int(save.get_value("render","detail",2)),0,2))
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
    _refresh_stick()
    if settings_open:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    else:
        _emit_graphics()

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
            hint_label.text = "◈  ODKRYJ ZNACZNIKI   •   DOTYK / PAD / KLAWIATURA"
