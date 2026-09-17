import UIKit
import Capacitor

/// 캠퍼스두잇 iOS 셸 — 단일 WKWebView + 네이티브 UITabBar(시안 A). AppDelegate에서 rootViewController로 직접 인스턴스화.
class NativeTabsViewController: CAPBridgeViewController, UITabBarDelegate {
    static weak var shared: NativeTabsViewController?
    let tabBar = UITabBar()
    let tabs: [(key: String, title: String, symbol: String)] = [
        ("cat",   "카테고리", "square.grid.2x2"),
        ("score", "점수진단", "doc.text"),
        ("home",  "홈",     "house"),
        ("sched", "일정",   "calendar"),
        ("my",    "MY",    "person")
    ]

    // 앱 내 로컬 플러그인 등록(Capacitor 6 공식 경로)
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(NativeTabsPlugin())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NativeTabsViewController.shared = self
        tabBar.delegate = self
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabBar.items = tabs.enumerated().map { (i, t) in
            let item = UITabBarItem(title: t.title, image: UIImage(systemName: t.symbol), selectedImage: UIImage(systemName: t.symbol + ".fill") ?? UIImage(systemName: t.symbol))
            item.tag = i
            return item
        }
        tabBar.selectedItem = tabBar.items?[2]
        let ap = UITabBarAppearance()
        ap.configureWithDefaultBackground()
        let cobalt = UIColor(red: 0.169, green: 0.357, blue: 0.769, alpha: 1)
        ap.stackedLayoutAppearance.selected.iconColor = cobalt
        ap.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: cobalt]
        tabBar.standardAppearance = ap
        if #available(iOS 15.0, *) { tabBar.scrollEdgeAppearance = ap }
        view.addSubview(tabBar)
        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        view.bringSubviewToFront(tabBar)
    }

    // 빌드20 크래시(0x8BADF00D) 원인: 매 레이아웃마다 webView.frame 무조건 대입 → setFrame→layoutSubviews 무한 루프(워치독 5s).
    // 정정: 프레임 값이 실제로 바뀔 때만 대입(루프 차단) + 탭바 높이는 additionalSafeAreaInsets로 웹에 전달.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let h = tabBar.frame.height
        let target = CGRect(x: 0, y: 0, width: view.bounds.width, height: max(0, view.bounds.height - h))
        if let wv = webView, wv.frame != target {
            wv.frame = target
        }
        if additionalSafeAreaInsets.bottom != 0 { additionalSafeAreaInsets.bottom = 0 }
        if view.subviews.last !== tabBar { view.bringSubviewToFront(tabBar) }
    }

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let key = tabs[item.tag].key
        webView?.evaluateJavaScript("window.__nativeTab && window.__nativeTab('\(key)')", completionHandler: nil)
    }

    func setActive(_ key: String) {
        guard let i = tabs.firstIndex(where: { $0.key == key }) else { return }
        DispatchQueue.main.async { self.tabBar.selectedItem = self.tabBar.items?[i] }
    }
}
