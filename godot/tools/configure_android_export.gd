extends SceneTree
## CI-only: set the Godot editor Android and JDK paths without committing local SDK paths.
func _initialize() -> void:
    var cfg = EditorInterface.get_editor_settings()
    var sdk := OS.get_environment("ANDROID_HOME")
    var java := OS.get_environment("JAVA_HOME")
    if sdk.is_empty() or java.is_empty():
        push_error("Android CI: SDK or JAVA_HOME unset")
        quit(2)
        return
    cfg.set_setting("export/android/android_sdk_path",sdk)
    cfg.set_setting("export/android/java_sdk_path",java)
    cfg.set_setting("export/android/debug_keystore",OS.get_environment("HOME")+"/.android/debug.keystore")
    cfg.set_setting("export/android/debug_keystore_user","androiddebugkey")
    cfg.set_setting("export/android/debug_keystore_pass","android")
    print("ANDROID_EXPORT_CONFIGURED: ",sdk,"  JAVA:",java)
    quit(0)
