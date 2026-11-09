extends CanvasLayer
## Landscape mobile buy menu; button state reflects real credits and ownership.
const CATALOG = preload("res://scripts/arsenal.gd")
signal purchase_requested(item_id: String)
signal continue_requested()
var panel: Control
var wallet: Label
var title: Label
var feedback: Label
var items: Dictionary = {}
var economy
var round_no := 1

func _box(fill: Color, outline: Color) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = fill
    s.border_color = outline
    s.set_border_width_all(1)
    s.set_corner_radius_all(5)
    s.content_margin_left = 9
    s.content_margin_right = 9
    s.content_margin_top = 5
    s.content_margin_bottom = 5
    return s

func _ready() -> void:
    layer = 16
    panel = Control.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(panel)
    var dark := ColorRect.new()
    dark.color = Color(.024,.035,.043,.97)
    dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.add_child(dark)
    var frame := PanelContainer.new()
    frame.anchor_left = .1
    frame.anchor_right = .9
    frame.anchor_top = .04
    frame.anchor_bottom = .96
    frame.add_theme_stylebox_override("panel",_box(Color(.065,.084,.10),Color(.39,.46,.47)))
    panel.add_child(frame)
    var vertical := VBoxContainer.new()
    vertical.add_theme_constant_override("separation",6)
    frame.add_child(vertical)
    var header := HBoxContainer.new()
    vertical.add_child(header)
    title = Label.new()
    title.add_theme_font_size_override("font_size",24)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)
    wallet = Label.new()
    wallet.add_theme_font_size_override("font_size",22)
    wallet.add_theme_color_override("font_color",Color(.48,.90,.60))
    header.add_child(wallet)
    var helper := Label.new()
    helper.text = "Punkty meczu • Zakupy offline • Przygotuj wyposażenie przed rundą"
    helper.add_theme_font_size_override("font_size",13)
    vertical.add_child(helper)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    vertical.add_child(scroll)
    var listing := VBoxContainer.new()
    listing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    listing.add_theme_constant_override("separation",4)
    scroll.add_child(listing)
    for category in ["PISTOLETY","PM","KARABINY","PRECYZYJNE","WYPOSAŻENIE"]:
        var label := Label.new()
        label.text = category
        label.add_theme_font_size_override("font_size",14)
        label.add_theme_color_override("font_color",Color(.93,.74,.52))
        listing.add_child(label)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation",7)
        listing.add_child(row)
        for raw in CATALOG.CATALOG:
            var item: Dictionary = raw
            if str(item["category"]) != category:
                continue
            var b := Button.new()
            b.custom_minimum_size = Vector2(134,46)
            b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            b.focus_mode = Control.FOCUS_NONE
            b.add_theme_font_size_override("font_size",14)
            b.add_theme_stylebox_override("normal",_box(Color(.12,.17,.20),Color(.35,.45,.47)))
            b.add_theme_stylebox_override("hover",_box(Color(.19,.26,.29),Color(.72,.75,.71)))
            var id: String = str(item["id"])
            b.pressed.connect(func(): purchase_requested.emit(id))
            row.add_child(b)
            items[id] = b
    feedback = Label.new()
    feedback.add_theme_font_size_override("font_size",14)
    vertical.add_child(feedback)
    var go := Button.new()
    go.text = "▶  GOTOWY — ROZPOCZNIJ RUNDĘ"
    go.custom_minimum_size = Vector2(260,52)
    go.add_theme_font_size_override("font_size",18)
    go.add_theme_stylebox_override("normal",_box(Color(.56,.25,.20),Color(.85,.49,.35)))
    go.pressed.connect(func(): continue_requested.emit())
    vertical.add_child(go)
    visible = false

func open(economy_state,round_index: int) -> void:
    economy = economy_state
    round_no = round_index
    visible = true
    refresh("FAZA ZAKUPÓW — RUNDA %d" % round_no)

func refresh(message: String = "") -> void:
    if economy == null:
        return
    title.text = "MENU ZAKUPÓW • RUNDA %d" % round_no
    wallet.text = "%d $" % economy.credits
    if message != "":
        feedback.text = message
    for id in items:
        var button: Button = items[id]
        var entry: Dictionary = economy.item_by_id(str(id))
        button.text = "%s\n%d $" % [str(entry["name"]),int(entry["cost"])]
        button.disabled = not economy.can_buy(str(id))

func close() -> void:
    visible = false
