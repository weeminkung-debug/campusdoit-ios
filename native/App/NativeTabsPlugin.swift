import Foundation
import UIKit
import Capacitor

/// 캠퍼스두잇 iOS 셸(5번방 방식 교체 09.17): 기존 CAPBridgeViewController 진입 경로 그대로,
/// 플러그인 load()에서 브리지 VC 뷰에 UITabBar를 얹는다. 웹뷰 프레임은 건드리지 않고
/// additionalSafeAreaInsets로 하단 여백을 웹(env(safe-area-inset-bottom))에 전달한다.
@objc(NativeTabsPlugin)
public class NativeTabsPlugin: CAPPlugin, CAPBridgedPlugin, UITabBarDelegate {
    public let identifier = "NativeTabsPlugin"
    public let jsName = "NativeTabs"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "setActive", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isAvailable", returnType: CAPPluginReturnPromise)
    ]
    private let tabBar = UITabBar()
    private let tabs: [(key: String, title: String, symbol: String)] = [
        ("cat",   "카테고리", "square.grid.2x2"),
        ("score", "점수진단", "doc.text"),
        ("home",  "홈",     "house"),
        ("sched", "일정",   "calendar"),
        ("my",    "MY",    "person")
    ]
    private var installed = false

    public override func load() {
        // 브리지 VC 뷰가 윈도우에 올라온 뒤에만 부착(첫 실행 스모크: 부착 시점이 빨라 탭바 미표시) — 0.3s 간격 최대 40회 재시도
        tryInstall(attempt: 0)
    }

    private func tryInstall(attempt: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + (attempt == 0 ? 0 : 0.3)) { [weak self] in
            guard let self = self, !self.installed else { return }
            // Capacitor의 CAPBridgeViewController는 view 자체가 WKWebView라 view.addSubview는 웹뷰 내부에 묻힘(스모크 실측: 탭바 비가시) → 윈도우에 직접 부착
            if let vc = self.bridge?.viewController, let win = vc.view.window, win.bounds.height > 0 {
                self.installTabBar(vc: vc, host: win)
            } else if attempt < 40 {
                self.tryInstall(attempt: attempt + 1)
            }
        }
    }

    private func installTabBar(vc: UIViewController, host: UIView) {
        installed = true
        tabBar.delegate = self
        tabBar.items = tabs.enumerated().map { (i, t) in
            let item = UITabBarItem(title: t.title, image: UIImage(systemName: t.symbol), selectedImage: UIImage(systemName: t.symbol + ".fill") ?? UIImage(systemName: t.symbol))
            item.tag = i
            return item
        }
        let ap = UITabBarAppearance()
        ap.configureWithDefaultBackground()   // 시스템 머티리얼 — 라이트/다크 자동
        let cobalt = UIColor(red: 0.169, green: 0.357, blue: 0.769, alpha: 1)
        ap.stackedLayoutAppearance.selected.iconColor = cobalt
        ap.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: cobalt]
        tabBar.standardAppearance = ap
        if #available(iOS 15.0, *) { tabBar.scrollEdgeAppearance = ap }
        // 프레임 기반 배치(오토레이아웃 미사용): 하단 고정 + 홈 인디케이터 영역 포함 높이
        let safeBottom = host.safeAreaInsets.bottom   // host = UIWindow
        let barH: CGFloat = 49 + safeBottom
        tabBar.frame = CGRect(x: 0, y: host.bounds.height - barH, width: host.bounds.width, height: barH)
        tabBar.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        host.addSubview(tabBar)
        host.bringSubviewToFront(tabBar)
        tabBar.selectedItem = tabBar.items?[2]
        tabBar.setNeedsLayout(); tabBar.layoutIfNeeded()
        // 웹 하단 여백: 탭바 본체 49pt를 세이프에어리어에 가산 → env(safe-area-inset-bottom)
        vc.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: 49, right: 0)
        bridge?.webView?.scrollView.verticalScrollIndicatorInsets.bottom = 49
        // 이후 삽입되는 뷰 대비 재전면
        [0.5, 1.5, 3.0, 6.0].forEach { d in
            DispatchQueue.main.asyncAfter(deadline: .now() + d) { [weak self] in
                guard let self = self, let w = self.tabBar.superview else { return }
                w.bringSubviewToFront(self.tabBar)
            }
        }
        // 스모크 런치 인자: -smokeTab <key>
        if let i = ProcessInfo.processInfo.arguments.firstIndex(of: "-smokeTab"), i + 1 < ProcessInfo.processInfo.arguments.count {
            let key = ProcessInfo.processInfo.arguments[i + 1]
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in self?.select(key) }
        }
    }

    private func select(_ key: String) {
        guard let i = tabs.firstIndex(where: { $0.key == key }) else { return }
        tabBar.superview?.bringSubviewToFront(tabBar)
        tabBar.selectedItem = tabBar.items?[i]
        bridge?.webView?.evaluateJavaScript("window.__nativeTab && window.__nativeTab('\(key)')", completionHandler: nil)
    }

    // 탭 선택 → 웹 라우트
    public func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let key = tabs[item.tag].key
        bridge?.webView?.evaluateJavaScript("window.__nativeTab && window.__nativeTab('\(key)')", completionHandler: nil)
    }

    // 웹 → 네이티브 동기
    @objc func setActive(_ call: CAPPluginCall) {
        let key = call.getString("key") ?? "home"
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let i = self.tabs.firstIndex(where: { $0.key == key }) else { return }
            self.tabBar.selectedItem = self.tabBar.items?[i]
        }
        call.resolve()
    }
    @objc func isAvailable(_ call: CAPPluginCall) {
        call.resolve(["available": installed])
    }
}
