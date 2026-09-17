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
        DispatchQueue.main.async { [weak self] in self?.installTabBar() }
    }

    private func installTabBar() {
        guard !installed, let vc = bridge?.viewController, let host = vc.view else { return }
        installed = true
        tabBar.delegate = self
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabBar.items = tabs.enumerated().map { (i, t) in
            let item = UITabBarItem(title: t.title, image: UIImage(systemName: t.symbol), selectedImage: UIImage(systemName: t.symbol + ".fill") ?? UIImage(systemName: t.symbol))
            item.tag = i
            return item
        }
        tabBar.selectedItem = tabBar.items?[2]
        let ap = UITabBarAppearance()
        ap.configureWithDefaultBackground()   // 시스템 머티리얼 — 라이트/다크 자동
        let cobalt = UIColor(red: 0.169, green: 0.357, blue: 0.769, alpha: 1)
        ap.stackedLayoutAppearance.selected.iconColor = cobalt
        ap.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: cobalt]
        tabBar.standardAppearance = ap
        if #available(iOS 15.0, *) { tabBar.scrollEdgeAppearance = ap }
        host.addSubview(tabBar)
        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            tabBar.bottomAnchor.constraint(equalTo: host.bottomAnchor)   // 홈 인디케이터 영역은 UITabBar가 내부 처리
        ])
        host.layoutIfNeeded()
        // 웹 하단 여백: 탭바 본체 높이(49)를 세이프에어리어에 가산 → env(safe-area-inset-bottom)로 전달
        let barHeight: CGFloat = 49
        vc.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: barHeight, right: 0)
        bridge?.webView?.scrollView.verticalScrollIndicatorInsets.bottom = barHeight
        // 스모크 테스트용 런치 인자: -smokeTab <key> → 해당 탭으로 전환
        if let i = ProcessInfo.processInfo.arguments.firstIndex(of: "-smokeTab"), i + 1 < ProcessInfo.processInfo.arguments.count {
            let key = ProcessInfo.processInfo.arguments[i + 1]
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in self?.select(key) }
        }
    }

    private func select(_ key: String) {
        guard let i = tabs.firstIndex(where: { $0.key == key }) else { return }
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
