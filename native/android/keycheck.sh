#!/bin/bash
# 기기 열쇠 확인(시험 가지 전용): 1회차 만듦 → 강제 종료 → 2회차 남아 있는지
set +e
mkdir -p smoke
adb install -r android/app/build/outputs/apk/debug/app-debug.apk 2>&1 | tail -2 > smoke/_install.txt
P=com.campusdoit.app; A=$P/.MainActivity
adb shell pm list packages | grep campusdoit > smoke/_installed.txt
adb logcat -c || true
run(){ adb shell am force-stop $P; adb shell am start -n $A $2 >/dev/null 2>&1; sleep $3; adb exec-out screencap -p > smoke/$1.png 2>/dev/null; adb pull /sdcard/Android/data/$P/files/smoke_$4.json smoke/ >/dev/null 2>&1 || adb shell cat /sdcard/Android/data/$P/files/smoke_$4.json > smoke/smoke_$4.json 2>/dev/null; }
run 05_key1 "--es smokeTab home --es smokeAction keySmoke" 22 key_home
run 06_key2 "--es smokeTab my --es smokeAction keySmoke" 22 key_my
adb shell ls -la /sdcard/Android/data/$P/files > smoke/_filesdir.txt 2>&1
adb shell dumpsys package com.google.android.webview | grep -m1 versionName > smoke/_webview.txt 2>&1
adb logcat -d 2>/dev/null | grep -iE "FATAL|AndroidRuntime|campusdoit|Capacitor|chromium" | tail -60 > smoke/logcat.txt
exit 0
