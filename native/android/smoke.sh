#!/bin/bash
# 에뮬레이터 스모크. 러너가 script 줄을 한 줄씩 따로 실행해 함수가 다음 줄로 안 넘어가므로 파일 1개로 둠(2026-11-20 keycheck 가지에서 확인)
set +e
mkdir -p smoke
adb install -r android/app/build/outputs/apk/debug/app-debug.apk 2>&1 | tail -2
adb shell pm list packages | grep campusdoit > smoke/_installed.txt
P=com.campusdoit.app; A=$P/.MainActivity
adb logcat -c || true
run(){ adb shell am force-stop $P; adb shell am start -n $A $2 >/dev/null 2>&1; sleep $3; adb exec-out screencap -p > smoke/$1.png 2>/dev/null; adb pull /sdcard/Android/data/$P/files/smoke_$4.json smoke/ >/dev/null 2>&1 || true; adb pull /sdcard/Android/data/$P/files/smoke_ads.json smoke/ >/dev/null 2>&1 || true; }
run 01_home "--es smokeTab home" 10 home
run 02_score_gate "--es smokeTab score --es smokeAction runSim" 14 score
run 03_my "--es smokeTab my" 10 my
run 04_ads "--es smokeTab score --es smokeAction adsSmoke" 15 score
ls -la smoke
adb shell ls -la /sdcard/Android/data/$P/files 2>/dev/null > smoke/_filesdir.txt || true
adb logcat -d 2>/dev/null | grep -iE "FATAL|AndroidRuntime|campusdoit|MaterialComponents|BottomNavigation|NoClassDef|ClassNotFound|RuntimeException|InflateException|Capacitor|chromium" | tail -90 > smoke/logcat.txt || true
exit 0
