# Capacitor 6: 앱 타깃 안 로컬 플러그인은 CAPBridgeViewController 서브클래스 없이도
# packageClassList(capacitor.config → Info) 없이 자동 인식되지 않으므로, AppDelegate 진입 직후 브리지가 로드되는
# CAPBridgeViewController의 capacitorDidLoad 훅을 쓰지 않고, viewController에서 registerPluginInstance 호출이 필요.
# → 최소 침습: Main.storyboard 유지, AppDelegate.swift에 'didFinishLaunching' 후 첫 rootViewController에 플러그인 등록.
p = "ios/App/App/AppDelegate.swift"
s = File.read(p)
unless s.include?("NativeTabsPlugin")
  s.sub!(/(func application\(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: \[UIApplication\.LaunchOptionsKey: Any\]\?\) -> Bool \{\n)/) { |m|
    m + "        DispatchQueue.main.async {\n            if let vc = self.window?.rootViewController as? CAPBridgeViewController { vc.bridge?.registerPluginInstance(NativeTabsPlugin()) }\n        }\n"
  }
  File.write(p, s)
end
abort("AppDelegate not patched") unless File.read(p).include?("NativeTabsPlugin")
puts "AppDelegate: plugin registration inserted"
