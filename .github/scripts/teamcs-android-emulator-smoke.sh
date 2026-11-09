#!/usr/bin/env bash
set -euo pipefail
PKG="pl.teamcs.nativeqa3"
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
sleep 10
adb shell pidof "$PKG" | tee /tmp/teamcs-pid.log
test -s /tmp/teamcs-pid.log
adb shell screencap -p /sdcard/teamcs-smoke.png
adb pull /sdcard/teamcs-smoke.png "$GITHUB_WORKSPACE/teamcs-emulator-smoke.png"
adb logcat -d -v brief > "$GITHUB_WORKSPACE/teamcs-emulator-logcat.txt"
echo "EMULATOR_INSTALL_AND_PROCESS_LAUNCH_OK"
