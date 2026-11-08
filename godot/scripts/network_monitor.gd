extends Node
## Android-native network advisory + optional app-only smart routing.
## Never toggles Wi-Fi or cellular service for the whole device.
## Ping is only shown after a real game server measurement.
signal status_changed(description: String)

var smart_enabled := false
var current_description := "SYSTEM / brak danych"
var network_type := "unknown"
var validated := false
var wifi_available := false
var cellular_available := false
var game_server_rtt_ms := -1
var _plugin: Object = null
var _poll_timer := 0.0

func _ready() -> void:
    if Engine.has_singleton("TeamCSNetwork"):
        _plugin = Engine.get_singleton("TeamCSNetwork")
        _plugin.setSmartMode(smart_enabled)
    else:
        current_description = "ANDROID: brak wtyczki sieci" if OS.has_feature("android") else "PC: sieć systemowa"

func set_smart_mode(enabled: bool) -> void:
    smart_enabled = enabled
    if _plugin != null:
        _plugin.setSmartMode(enabled)
    _poll_now()

func set_game_server_latency(ms: int) -> void:
    game_server_rtt_ms = clampi(ms, -1, 60000)

func get_ping_text() -> String:
    return str(game_server_rtt_ms) + " ms" if game_server_rtt_ms >= 0 else "— (brak serwera)"

func get_network_text() -> String:
    return current_description

func _process(delta: float) -> void:
    _poll_timer += delta
    if _poll_timer >= 1.5:
        _poll_timer = 0.0
        _poll_now()

func _poll_now() -> void:
    if _plugin == null:
        return
    var parsed = JSON.parse_string(str(_plugin.getStateJson()))
    if not parsed is Dictionary:
        return
    var data: Dictionary = parsed
    network_type = str(data.get("type","unknown"))
    validated = bool(data.get("validated",false))
    wifi_available = bool(data.get("wifiAvailable",false))
    cellular_available = bool(data.get("mobileAvailable",false))
    var label := str(data.get("label","BRAK SIECI"))
    if not validated:
        label += " / brak weryfikacji"
    if bool(data.get("smart",false)):
        label += " / AUTO-GRA"
    if label != current_description:
        current_description = label
        status_changed.emit(label)
