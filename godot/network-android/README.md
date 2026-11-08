# TeamCS: Android app-only network observer / smart route

This is native source code for a Godot 4 Android plugin v2, separate from the legacy WebView app.

- Detects validated Wi-Fi and cellular networks via Android ConnectivityManager.
- Keeps the system-chosen default route until the player explicitly enables Auto — tylko gra.
- Auto mode may bind only the game process to an already available, validated alternate network if Android's estimated bandwidth suggests a substantial advantage, with hysteresis and cooldown.
- It never toggles the phone's Wi-Fi or mobile-data switches.
- Estimated bandwidth is not server ping. Real ping is shown only once an online game server exists and measures RTT.
- Changing the app's route may disrupt sockets; multiplayer will need session reconnection when built. This feature is experimental.
- Android still makes final decisions about which networks exist and are permitted.
- Build integration requires a compatible Godot Android library and Gradle export; the old WebView APK is not a Godot build.

Sources: Android Developers docs for ConnectivityManager, NetworkCapabilities and bindProcessToNetwork.
