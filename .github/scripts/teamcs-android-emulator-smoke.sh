#!/usr/bin/env bash
set -euo pipefail
PKG="pl.teamcs.arena4v4human"
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
# Do NOT hot-change emulator resolution after boot: this can hang Quickstep
# on slow software-Vulkan devices and produce a false positive for rendering.
# Hardware AVD profile and Godot's landscape orientation provide the size.
echo "START_ATTEMPT: ordinary Android app launcher alias"
adb shell am start -W -n "$PKG/com.godot.game.GodotAppLauncher" | tee /tmp/teamcs-launch.log
# This QA build deliberately disables immersive mode, avoiding Android's
# system fullscreen tutorial so the first screenshot shows game content.
sleep 45
adb shell dumpsys activity activities | grep -E 'ResumedActivity|mResumed|pl.teamcs' | head -12 || true
adb shell screencap -p /sdcard/teamcs-smoke.png
adb pull /sdcard/teamcs-smoke.png "$GITHUB_WORKSPACE/teamcs-emulator-smoke.png"
adb logcat -d -v brief > "$GITHUB_WORKSPACE/teamcs-emulator-logcat.txt"
mkdir -p "$GITHUB_WORKSPACE/teamcs-android-render"
QA_DATA_DIR=$(sed -n 's/.*TEAMCS_QA_OUTPUT: //p' "$GITHUB_WORKSPACE/teamcs-emulator-logcat.txt" | tr -d '\r' | tail -1)
if test -z "$QA_DATA_DIR"; then
    echo "The emulator QA feature did not start the pixel test" >&2
    exit 33
fi
for image in teamcs-lobby.png teamcs-operators.png teamcs-empty-stage.png teamcs-operator-0.png teamcs-operator-1.png teamcs-match.png; do
    adb exec-out run-as "$PKG" cat "$QA_DATA_DIR/$image" > "$GITHUB_WORKSPACE/teamcs-android-render/$image"
done
python3 - "$GITHUB_WORKSPACE/teamcs-android-render" <<'PY'
from pathlib import Path
from PIL import Image
import sys
for path in Path(sys.argv[1]).glob('*.png'):
    with Image.open(path) as image:
        image.verify()
print('TEAMCS_QA_RENDER_FILES_VALID')
PY
python3 - "$GITHUB_WORKSPACE/teamcs-emulator-smoke.png" <<'PY'
import struct, sys, pathlib
p=pathlib.Path(sys.argv[1])
blob=p.read_bytes()
if blob[:8] != b'\x89PNG\r\n\x1a\n':
    sys.exit("TEAMCS_SCREEN_INVALID: screenshot is not PNG")
w,h=struct.unpack(">II",blob[16:24])
print("TEAMCS_EMULATOR_RENDER_PIXELS:",w,h,"bytes=",len(blob))
if w<=h:
    sys.exit("TEAMCS_SCREEN_PORTRAIT: FPS must start landscape")
from PIL import Image
im=Image.open(p).convert("RGB").resize((160,90))
samples=list(im.getdata())
color_pixels=sum(max(rgb)-min(rgb)>=30 for rgb in samples)
black_pixels=sum(max(rgb)<17 for rgb in samples)
print("TEAMCS_VISUAL_TEST: colorful=", color_pixels," black=",black_pixels," total=",len(samples))
# Android launcher ANR/permission dialogs can hide the game while its activity
# is running. Inspect the center for the characteristic flat, white system modal.
# Do not falsely pass a screenshot just because its edges contain the 3D level.
width,height=im.size
center=im.crop((int(width*.25),int(height*.20),int(width*.75),int(height*.80)))
whites=sum(min(rgb)>=225 and max(rgb)-min(rgb)<24 for rgb in center.getdata())
white_ratio=whites/(center.width*center.height)
print("TEAMCS_ANDROID_MODAL_RATIO:",round(white_ratio,3))
if white_ratio>.22:
    sys.exit("TEAMCS_SCREEN_ANDROID_DIALOG: system app-not-responding modal obscures gameplay")
if color_pixels<400 or black_pixels>len(samples)*.97:
    sys.exit("TEAMCS_SCREEN_NO_GAME_SCENE: black screen or Android overlay, NOT a rendered 3D match")
print("TEAMCS_LANDSCAPE_GAMEPLAY_RENDER_VERIFIED")
PY
adb shell pidof "$PKG" | tee /tmp/teamcs-pid.log || true
if ! test -s /tmp/teamcs-pid.log; then
    echo "TEAMCS_CLOSED: saved screenshot and logcat" >&2
    exit 31
fi
if ! grep -q "TEAMCS_MATCH_READY" "$GITHUB_WORKSPACE/teamcs-emulator-logcat.txt"; then
    echo "No scene-ready signal in Android logcat: game may have failed after launching" >&2
    exit 32
fi
for marker in TEAMCS_PREVIEW_ACTOR TEAMCS_CHARACTER_RENDER_PASS TEAMCS_GAMEPLAY_RENDER_PASS; do
  if ! grep -q "$marker" "$GITHUB_WORKSPACE/teamcs-emulator-logcat.txt"; then
    echo "Missing $marker diagnostic: the live Android lobby preview was not verified" >&2
    exit 33
  fi
done
if grep -E 'SCRIPT ERROR|TEAMCS_RENDER_FAILURE|FATAL EXCEPTION' "$GITHUB_WORKSPACE/teamcs-emulator-logcat.txt"; then
  echo "Android script or rendering failure" >&2
  exit 34
fi
echo "EMULATOR_INSTALL_AND_SCENE_RUNNING_OK"
