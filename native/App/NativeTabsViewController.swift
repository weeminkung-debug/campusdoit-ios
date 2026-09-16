import UIKit
import Capacitor

/// 캠퍼스두잇 iOS 셸 — 단일 WKWebView + 네이티브 UITabBar(iOS 표준 머티리얼, 시안 A)
/// 탭 선택 → 웹 라우트 호출(__nativeTab) / 웹 라우트 변경 → NativeTabs.setActive 로 선택 동기
class NativeTabsViewController: CAPBridgeViewController, UITabBarDelegate {
    static weak var shared: NativeTabsViewController?
    let tabBar = UITabBar()
    // 웹 하단 5탭 1:1 (탭 tag = index)
    let tabs: [(key: String, title: String, symbol: String)] = [
        ("cat",   "카테고리", "square.grid.2x2"),
        ("score", "점수진단", "doc.text"),
        ("home",  "홈",     "house"),
        ("sched", "일정",   "calendar"),
        ("my",    "MY",    "person")
    ]

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
        tabBar.selectedItem = tabBar.items?[2]   // 홈

        // 시안 A: 시스템 머티리얼(라이트/다크 자동) + 활성 코발트
        let ap = UITabBarAppearance()
        ap.configureWithDefaultBackground()
        ap.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.169, green: 0.357, blue: 0.769, alpha: 1)   // #2B5BC4
        ap.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 0.169, green: 0.357, blue: 0.769, alpha: 1)]
        tabBar.standardAppearance = ap
        if #available(iOS 15.0, *) { tabBar.scrollEdgeAppearance = ap }

        view.addSubview(tabBar)
        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)   // 세이프에어리어는 UITabBar가 내부 처리
        ])
        view.bringSubviewToFront(tabBar)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 웹뷰 하단을 탭바 위로 (콘텐츠 가림 방지)
        let h = tabBar.frame.height
        webView?.scrollView.contentInset.bottom = h
        webView?.scrollView.verticalScrollIndicatorInsets.bottom = h
        if let wv = webView, wv.frame.height == view.bounds.height {
            wv.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height - h)
        }
    }

    // 탭 선택 → 웹 라우트
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let key = tabs[item.tag].key
        webView?.evaluateJavaScript("window.__nativeTab && window.__nativeTab('\(key)')", completionHandler: nil)
    }

    // 웹 → 네이티브 동기
    func setActive(_ key: String) {
        guard let i = tabs.firstIndex(where: { $0.key == key }) else { return }
        DispatchQueue.main.async { self.tabBar.selectedItem = self.tabBar.items?[i] }
    }
}
