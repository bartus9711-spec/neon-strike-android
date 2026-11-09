#!/usr/bin/env bash
set -euo pipefail
PKG="pl.teamcs.arena4v4qa"
APK="$GITHUB_WORKSPACE/TeamCS_Godot_GT7_QA.apk"
test -s "$APK"
echo "EMULATOR_OS=$(adb shell getprop ro.build.version.release | tr -d '\r')"
echo "EMULATOR_ABIS=$(adb shell getprop ro.product.cpu.abilist | tr -d '\r')"
echo "APK_SHA256=$(sha256sum "$APK")"
adb shell pm list packages | grep -F "$PKG" || true
echo "INSTALL_ATTEMPT: native Godot Android app"
adb install -r -t "$APK" | tee /tmp/teamcs-install.log
grep -q "Success" /tmp/teamcs-install.log
adb shell pm path "$PKG" | tee /tmp/teamcs-pmpath.log
grep -q package: /tmp/teamcs-pmpath.log
adb logcat -c
echo "START_ATTEMPT: ordinary Android app launcher alias"
adb shell am start -W -n "$PKG/com.godot.game.GodotAppLauncher" | tee /tmp/teamcs-launch.log
# This QA build deliberately disables immersive mode, avoiding Android's
# system fullscreen tutorial so the first screenshot shows game content.
sleep 14
adb shell dumpsys activity activities | grep -E 'ResumedActivity|mResumed|pl.teamcs' | head -12 || true
adb shell screencap -p /sdcard/teamcs-smoke.png
adb pull /sdcard/teamcs-smoke.png "$GITHUB_WORKSPACE/teamcs-emulator-smoke.png"
adb logcat -d -v brief > "$GITHUB_WORKSPACE/teamcs-emulator-logcat.txt"
adb shell pidof "$PKG" | tee /tmp/teamcs-pid.log || true
if ! test -s /tmp/teamcs-pid.log; then
    echo "TEAMCS_CLOSED: saved screenshot and logcat" >&2
    exit 31
fi
if ! grep -q "TEAMCS_MATCH_READY" "$GITHUB_WORKSPACE/teamcs-emulator-logcat.txt"; then
    echo "No scene-ready signal in Android logcat: game may have failed after launching" >&2
    exit 32
fi
echo "EMULATOR_INSTALL_AND_SCENE_RUNNING_OK"
