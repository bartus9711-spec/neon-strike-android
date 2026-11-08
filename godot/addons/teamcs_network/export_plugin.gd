@tool
extends EditorPlugin
var exporter: EditorExportPlugin

func _enter_tree() -> void:
    exporter = NetworkExport.new()
    add_export_plugin(exporter)

func _exit_tree() -> void:
    remove_export_plugin(exporter)
    exporter = null

class NetworkExport extends EditorExportPlugin:
    func _get_name() -> String:
        return "TeamCSNetwork"

    func _supports_platform(platform: EditorExportPlatform) -> bool:
        return platform is EditorExportPlatformAndroid

    func _get_android_libraries(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
        var suffix := "debug" if debug else "release"
        var aar := "res://addons/teamcs_network/bin/teamcs-network-%s.aar" % suffix
        if not FileAccess.file_exists(aar):
            push_warning("TeamCSNetwork AAR missing; build native plugin before Godot Android export.")
            return PackedStringArray()
        return PackedStringArray([aar])
