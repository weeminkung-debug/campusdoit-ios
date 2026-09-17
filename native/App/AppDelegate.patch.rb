# AppDelegate.swift: 앱 기동 시 rootViewController = NativeTabsViewController (스토리보드 의존 제거)
p = "ios/App/App/AppDelegate.swift"
s = File.read(p)
unless s.include?("NativeTabsViewController")
  s.sub!(/func application\(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: \[UIApplication\.LaunchOptionsKey: Any\]\?\) -> Bool \{\n/) { |m|
    m + "        // 캠퍼스두잇 셸: 네이티브 탭바 VC를 루트로\n        let win = UIWindow(frame: UIScreen.main.bounds)\n        win.rootViewController = NativeTabsViewController()\n        win.makeKeyAndVisible()\n        self.window = win\n"
  }
  File.write(p, s)
end
puts(File.read(p).include?("NativeTabsViewController") ? "AppDelegate patched" : "AppDelegate NOT patched")
exit 1 unless File.read(p).include?("NativeTabsViewController")
