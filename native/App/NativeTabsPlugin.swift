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
        // 결함② 정정: iOS 26 글라스 탭바는 뒤 콘텐츠(웹 화면) 색을 샘플링해 다크에서 라이트로 보일 수 있음
        // → 불투명 배경 + 시스템 라이트/다크에만 종속되는 동적 색으로 고정(웹 화면 상태 무관)
        let ap = UITabBarAppearance()
        ap.configureWithOpaqueBackground()
        ap.backgroundColor = UIColor { tc in tc.userInterfaceStyle == .dark ? UIColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 1) : UIColor(red: 0.976, green: 0.976, blue: 0.976, alpha: 1) }
        ap.shadowColor = UIColor { tc in tc.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.15) : UIColor(white: 0, alpha: 0.2) }
        let cobalt = UIColor(red: 0.169, green: 0.357, blue: 0.769, alpha: 1)
        let gray = UIColor { tc in tc.userInterfaceStyle == .dark ? UIColor(white: 0.62, alpha: 1) : UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1) }
        ap.stackedLayoutAppearance.selected.iconColor = cobalt
        ap.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: cobalt]
        ap.stackedLayoutAppearance.normal.iconColor = gray
        ap.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: gray]
        tabBar.standardAppearance = ap
        if #available(iOS 15.0, *) { tabBar.scrollEdgeAppearance = ap }
        tabBar.isTranslucent = false
        // 결함① 정정: 스플래시(SplashScreen 플러그인, 1.2s) 위에 탭바가 겹침 → 웹 첫 로드 완료 + 스플래시 종료 이후 표시
        tabBar.isHidden = true
        // 프레임 기반 배치(오토레이아웃 미사용): 하단 고정 + 홈 인디케이터 영역 포함 높이
        let safeBottom = host.safeAreaInsets.bottom   // host = UIWindow
        let barH: CGFloat = 49 + safeBottom
        tabBar.frame = CGRect(x: 0, y: host.bounds.height - barH, width: host.bounds.width, height: barH)
        tabBar.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        host.addSubview(tabBar)
        host.bringSubviewToFront(tabBar)
        tabBar.selectedItem = tabBar.items?[2]
        tabBar.setNeedsLayout(); tabBar.layoutIfNeeded()
        scheduleReveal()
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

    // 웹뷰 로드 완료(isLoading=false) 확인 + 최소 1.8s(스플래시 1.2s + 페이드) 경과 후 표시
    private var revealed = false
    private func scheduleReveal(attempt: Int = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + (attempt == 0 ? 1.8 : 0.25)) { [weak self] in
            guard let self = self, !self.revealed else { return }
            let loading = self.bridge?.webView?.isLoading ?? true
            if !loading || attempt >= 40 {
                self.revealed = true
                self.tabBar.alpha = 0; self.tabBar.isHidden = false
                UIView.animate(withDuration: 0.2) { self.tabBar.alpha = 1 }
            } else {
                self.scheduleReveal(attempt: attempt + 1)
            }
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
