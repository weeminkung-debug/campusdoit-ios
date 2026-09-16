# 셸 적용 절차(워크플로 자동)
1. ios/App/App/ 에 NativeTabsViewController.swift · NativeTabsPlugin.swift 복사
2. Main.storyboard의 CAPBridgeViewController → customClass="NativeTabsViewController" 로 치환(sed)
3. AppDelegate.swift 변경 없음 (Capacitor 6 플러그인 자동 등록: CAPBridgedPlugin)
