#!/bin/bash
# 에뮬레이터 스모크. 러너가 script 줄을 한 줄씩 따로 실행해 함수가 다음 줄로 안 넘어가므로 파일 1개로 둠(2026-11-20 keycheck 가지에서 확인)
set +e
mkdir -p smoke
adb install -r android/app/build/outputs/apk/debug/app-debug.apk 2>&1 | tail -2
adb shell pm list packages | grep campusdoit > smoke/_installed.txt
P=com.campusdoit.app; A=$P/.MainActivity
adb logcat -c || true
run(){ adb shell am force-stop $P; adb shell am start -n $A $2 >/dev/null 2>&1; sleep $3; adb exec-out screencap -p > smoke/$1.png 2>/dev/null; adb pull /sdcard/Android/data/$P/files/smoke_$4.json smoke/ >/dev/null 2>&1 || true; adb pull /sdcard/Android/data/$P/files/smoke_ads.json smoke/ >/dev/null 2>&1 || true; }
# 5번방 #138: 설치 직후 첫 실행(웹뷰 첫 준비)은 따로 재서 기록만 — 판정은 두 번째 실행으로
run 00_cold "--es smokeTab home" 40 home; [ -f smoke/smoke_home.json ] && mv smoke/smoke_home.json smoke/cold_home.json
run 01_home "--es smokeTab home" 40 home
run 02_score_gate "--es smokeTab score --es smokeAction runSim" 40 score
run 03_my "--es smokeTab my" 36 my
run 04_ads "--es smokeTab score --es smokeAction adsSmoke" 48 score
adb logcat -d 2>/dev/null | grep -E "CDUADS|Ads|DynamiteModule|GmsCore|FirebaseApp" | tail -40 > smoke/ads_log.txt   # 5번방 #138: 광고 실패 원인 줄(뒤 시험이 logcat을 지우기 전에)
# 5번방 #133: 웹 사진 입력(capture=environment)을 누르면 카메라 앱이 뜨는지 — 화면 가운데를 눌러 확인
adb shell am force-stop $P; adb logcat -c; adb shell am start -n $A --es smokeTab home --es smokeAction camSmoke >/dev/null 2>&1
for i in $(seq 1 40); do adb logcat -d 2>/dev/null | grep -q "CDUCAM:ready" && break; sleep 1; done; sleep 1
WH=$(adb shell wm size | grep -o "[0-9]*x[0-9]*" | tail -1); W=${WH%x*}; H=${WH#*x}
for t in 1 2 3; do adb shell input tap $((W/2)) $((H/2)); sleep 5; adb shell dumpsys activity activities 2>/dev/null | grep -E "topResumedActivity" | grep -qi camera && break; done
adb exec-out screencap -p > smoke/05_cam.png 2>/dev/null
adb shell dumpsys activity activities 2>/dev/null | grep -E "topResumedActivity|mResumedActivity|ResumedActivity" | head -3 > smoke/cam.txt
adb logcat -d 2>/dev/null | grep -E "CDUCAM|FileChooser|CDUADS" | tail -8 >> smoke/cam.txt
adb shell am force-stop $P

# 5번방 #138: 설치 직후 수 분은 에뮬이 뒤에서 앱을 최적화해 느림 → 홈 진입은 여러 번 실행 뒤 한 번 더 재서 판정
run 06_home_late "--es smokeTab home" 30 home; [ -f smoke/smoke_home.json ] && cp smoke/smoke_home.json smoke/late_home.json

# ---- #97 앱 자동 갱신 시험(정상 1 + 실패 4) — 5번방 #114 ----
F=/tmp/cdu; python3 tools/cdu_fixture.py android/app/src/main/assets/public $F > smoke/cdu_fixture.txt 2>&1; PUB=$(cat $F/pub.txt)
APK=android/app/build/outputs/apk/debug/app-debug.apk
adb reverse tcp:8099 tcp:8099; adb reverse tcp:8199 tcp:8199
cdu(){ # $1=이름 $2=목록 폴더(없으면 서버 안 켬) $3=drop
  adb uninstall $P >/dev/null 2>&1; adb install -r $APK >/dev/null 2>&1
  SP=""; ORG=http://localhost:8199
  if [ -n "$2" ]; then python3 tools/cdu_server.py 8099 $F/$2 $F/srv $3 & SP=$!; ORG=http://localhost:8099; sleep 1; fi
  adb logcat -c; adb shell am start -n $A --es cduOrigin $ORG --es cduPub "$PUB" >/dev/null 2>&1; sleep 14; adb shell am force-stop $P
  adb logcat -c; adb shell am start -n $A --es cduOrigin $ORG --es cduPub "$PUB" >/dev/null 2>&1; sleep 12
  adb exec-out screencap -p > smoke/cdu_$1.png 2>/dev/null
  M=$(adb logcat -d 2>/dev/null | grep -o "CDUMARK:[a-z0-9]*" | tail -1)
  ST=$(adb shell run-as $P cat files/cdu/cdu_state.json 2>/dev/null | tr -d '\r\n')
  DS=$(adb shell run-as $P ls files/cdu 2>/dev/null | tr '\r\n' '  ')
  printf '{"name":"%s","mark":"%s","state":%s,"dirs":"%s"}\n' "$1" "$M" "${ST:-null}" "$DS" > smoke/cdu_$1.json
  adb shell am force-stop $P; [ -n "$SP" ] && kill $SP 2>/dev/null; }
cdu ok srv_good; cdu badsig srv_badsig; cdu badhash srv_badhash; cdu drop srv_good drop; cdu closed ""
python3 - <<'PY'
import json,os
R=[]
def J(n):
    try: return json.load(open(f'smoke/cdu_{n}.json'))
    except Exception as e: return {'err':str(e)}
o=J('ok'); R.append(('C1','정상: 두 번째 실행에 새 버전(v2)',o.get('mark')=='CDUMARK:v2',o))
for k,nm in [('badsig','갱신 실패(서명 틀림)'),('badhash','갱신 실패(sha256 틀림)'),('drop','받다 끊김'),('closed','서버 안 열림')]:
    j=J(k); st=j.get('state') or {}; R.append(('C-'+k,nm+': 넣어 둔 화면',j.get('mark')=='CDUMARK:bundle' and not st.get('ready'),j))
ok=all(r[2] for r in R)
md='| # | 항목 | 결과 | 상태 |\n|---|---|---|---|\n'+'\n'.join(f'| {a} | {b} | {"✅ PASS" if c else "❌ FAIL"} | {json.dumps(d,ensure_ascii=False)[:300]} |' for a,b,c,d in R)+f'\n\n**{"CDU_OK" if ok else "CDU_FAIL"}**\n'
open(os.environ.get('GITHUB_STEP_SUMMARY','/dev/stdout'),'a').write('## #97 앱 자동 갱신 시험(Android)\n'+md)
for a,b,c,d in R: print(f"::notice title=cdu-android-{a}::{'PASS' if c else 'FAIL'} {b} | {json.dumps(d,ensure_ascii=False)[:900]}")
PY
ls -la smoke
adb shell ls -la /sdcard/Android/data/$P/files 2>/dev/null > smoke/_filesdir.txt || true
adb logcat -d 2>/dev/null | grep -iE " Ads|Ads:|DynamiteModule|GmsCore|CDUADS|CDUSMOKE|FATAL|AndroidRuntime|campusdoit|MaterialComponents|BottomNavigation|NoClassDef|ClassNotFound|RuntimeException|InflateException|Capacitor|chromium" | tail -90 > smoke/logcat.txt || true
exit 0
