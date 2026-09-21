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
        // 결함② 정정(5번방 확정: 반투명 글라스 유지): 시스템 머티리얼 블러 + 톤 오버레이(다크 검정 α0.55 / 라이트 흰 α0.55)로
        // 뒤 콘텐츠 샘플링 영향을 균일화, standard = scrollEdge 동일 고정, 탭바 스타일은 시스템 트레이트에만 명시 종속
        // 5번방 확정(09.21): 시스템 UITabBar 기본 글라스 그대로(오버레이·백드롭 없음), 활성 코발트만 지정
        let ap = UITabBarAppearance()
        ap.configureWithDefaultBackground()
        let cobalt = UIColor(red: 0.169, green: 0.357, blue: 0.769, alpha: 1)
        ap.stackedLayoutAppearance.selected.iconColor = cobalt
        ap.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: cobalt]
        tabBar.standardAppearance = ap
        if #available(iOS 15.0, *) { tabBar.scrollEdgeAppearance = ap }
        tabBar.overrideUserInterfaceStyle = .unspecified   // 시스템 라이트/다크 자동 추종(스모크 실측: 설치 시점 트레이트 고정 시 다크 미반영)
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
        pollDom(); scheduleReveal()
        // 웹 하단 여백: 탭바 본체 49pt를 세이프에어리어에 가산 → env(safe-area-inset-bottom) (5번방 09.21: 앱 라이트 전용 선언, 시스템 글라스 그대로)
        vc.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: 49, right: 0)
        bridge?.webView?.scrollView.verticalScrollIndicatorInsets.bottom = 49
        // 이후 삽입되는 뷰 대비 재전면
        [0.5, 1.5, 3.0, 6.0].forEach { d in
            DispatchQueue.main.asyncAfter(deadline: .now() + d) { [weak self] in
                guard let self = self, let w = self.tabBar.superview else { return }
                w.bringSubviewToFront(self.tabBar)
            }
        }
        // 스모크 런치 인자: -smokeTab <key> [-smokeAction runSim]  → +2.5s 탭 전환, +5s 상태 JSON을 Documents/smoke_<key>.json 에 기록
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-smokeTab"), i + 1 < args.count {
            let key = args[i + 1]
            let action: String? = { if let j = args.firstIndex(of: "-smokeAction"), j + 1 < args.count { return args[j + 1] } ; return nil }()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in   // 첫 진입 면책 팝업 닫기(딤 오버레이가 탭바 톤 측정에 섞이지 않게)
                self?.bridge?.webView?.evaluateJavaScript("(function(){try{var d=document.getElementById('dmAgree'); if(d) d.click();}catch(e){} return 1;})()", completionHandler: nil)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in self?.select(key) }
            if action == "openSignup" {   /* ⑪ Turnstile: 가입 화면 진입 → +6s 토큰·iframe 상태를 JSON에 기록 */
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                    self?.bridge?.webView?.evaluateJavaScript("(function(){try{var d=document.getElementById('dmAgree'); if(d) d.click();}catch(e){} try{goSignup();}catch(e){window.__smokeErr=String(e);} return 1;})()", completionHandler: nil)
                }
            }
            if action == "runSim" {   // 로그인 게이트: 미로그인 보장(토큰 제거) → 점수 입력 후 실행 → loginView 기대. 5s·7s 2회(멱등)
                [5.0, 7.0].forEach { d in
                    DispatchQueue.main.asyncAfter(deadline: .now() + d) { [weak self] in
                        self?.bridge?.webView?.evaluateJavaScript("(function(){try{localStorage.removeItem('doit_token_v1');}catch(e){} try{var d=document.getElementById('dmAgree'); if(d) d.click();}catch(e){} try{ if(typeof _visView==='function'&&_visView()==='loginView') return 2; setScope('KR'); document.getElementById('scoreBigNum').value='88'; runSim(); }catch(e){ window.__smokeErr=String(e); } return 1;})()", completionHandler: nil)
                    }
                }
            }
            // ⑩ 홈 레이아웃 안정: +2s·+8s 주요 요소 위치 기록 → 판정 스텝에서 이동 0 검증
            if key == "home" {
                [2.0, 8.0].forEach { d in
                    DispatchQueue.main.asyncAfter(deadline: .now() + d) { [weak self] in
                        let js = "(function(){try{var q=function(s){var e=document.querySelector(s);return e?Math.round(e.getBoundingClientRect().top+window.scrollY):null};var bn=document.getElementById('homeBn');window.__layout=window.__layout||{};window.__layout[String(\(Int(d)))]={job:q('.job-sec'),cards:q('.home-cards'),bnH:bn?Math.round(bn.getBoundingClientRect().height):null,slides:document.querySelectorAll('#hbnTrack .hbn-s').length};}catch(e){}return 1;})()"
                        self?.bridge?.webView?.evaluateJavaScript(js, completionHandler: nil)
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + (action == nil ? (key == "home" ? 9.0 : 6.0) : 9.0)) { [weak self] in
                let js = "JSON.stringify({view:(typeof _visView==='function'?_visView():''), nav:getComputedStyle(document.getElementById('bottomNav')).display, native:!!(document.body.classList.contains('native-tabs')), err:(window.__smokeErr||''), logged:(typeof isLoggedIn==='function'?isLoggedIn():null), layout:(window.__layout||null), ts:(function(){try{var v=document.querySelector('#signupView [name=cf-turnstile-response]');var f=document.querySelectorAll('#signupView iframe').length;return {token:(v&&v.value?v.value.length:0),iframes:f,origin:location.origin}}catch(e){return {err:String(e)}}})()})"
                self?.bridge?.webView?.evaluateJavaScript(js) { res, _ in
                    guard let self = self, var str = res as? String, let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
                    str = String(str.dropLast()) + String(format: ",\"splashHideAt\":%.3f,\"revealAt\":%.3f}", self.splashHideAt, self.revealAt)
                    try? str.write(to: dir.appendingPathComponent("smoke_\(key).json"), atomically: true, encoding: .utf8)
                }
            }
        }
    }

    // 표시 시점 = 스플래시가 걷히는 프레임과 동시(5번방 09.21): SplashScreen 플러그인의 이미지뷰(webView 서브뷰)가 제거되는 순간 + DOM 준비 → 즉시 표시. 고정 지연 없음(폴링 50ms)
    private var revealed = false
    private var splashSeen = false
    private let t0 = Date()
    private var splashHideAt: Double = -1
    private var revealAt: Double = -1
    private var domReady = false
    private func pollDom() {
        bridge?.webView?.evaluateJavaScript("document.readyState") { [weak self] res, _ in
            guard let self = self else { return }
            if let r = res as? String, r == "interactive" || r == "complete" { self.domReady = true }
            else if !self.revealed { DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self.pollDom() } }
        }
    }
    private func splashVisible() -> Bool {
        guard let wv = bridge?.webView else { return false }
        return wv.subviews.contains { $0 is UIImageView && !$0.isHidden && $0.alpha > 0.05 }
    }
    private func scheduleReveal(attempt: Int = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self, !self.revealed else { return }
            let now = Date().timeIntervalSince(self.t0)
            if self.splashVisible() { self.splashSeen = true }
            let splashGone = self.splashSeen && !self.splashVisible()
            if splashGone && self.splashHideAt < 0 { self.splashHideAt = now }
            let timeout = now > 8.0
            if (splashGone && self.domReady) || timeout {
                self.revealed = true; self.revealAt = now
                self.tabBar.isHidden = false; self.tabBar.alpha = 1
            } else { self.scheduleReveal(attempt: attempt + 1) }
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
