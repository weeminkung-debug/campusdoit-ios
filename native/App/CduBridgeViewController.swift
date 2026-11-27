import UIKit
import Capacitor

/// 앱 자동 최신: 웹뷰가 첫 페이지를 열기 전(capacitorDidLoad → viewDidLoad의 loadWebView 앞)에 검증된 폴더로 갈아탐.
/// Capacitor의 폴더 저장(persist)은 쓰지 않으므로, 이 코드가 틀려도 다음 실행은 넣어 둔 화면으로 열림.
class CduBridgeViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(AppUpdatePlugin())
        if let dir = AppUpdate.shared.pickFolderAtLaunch() {
            bridge?.setServerBasePath(dir)   // 폴더가 없으면 Capacitor가 무시 → 넣어 둔 화면
            AppUpdate.shared.armReadyTimeout { [weak self] in
                guard let self = self, let pub = Bundle.main.url(forResource: "public", withExtension: nil) else { return }
                self.bridge?.setServerBasePath(pub.path)
                self.webView?.reload()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if DEBUG
        CduSmoke.run(self)
        #endif
    }
}

/// 화면 → 기기: 준비됨 신호. 화면이 처음 그려지자마자 부름
@objc(AppUpdatePlugin)
public class AppUpdatePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "AppUpdatePlugin"
    public let jsName = "AppUpdate"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "ready", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "info", returnType: CAPPluginReturnPromise)
    ]
    @objc func ready(_ call: CAPPluginCall) {
        AppUpdate.shared.markReady()
        call.resolve(["ver": AppUpdate.shared.activeVer ?? "bundle"])
        AppUpdate.shared.runUpdateInBackground()   // 다음 실행용으로 조용히 받아 둠
    }
    @objc func info(_ call: CAPPluginCall) {
        call.resolve(["ver": AppUpdate.shared.activeVer ?? "bundle", "build": AppUpdate.shared.currentBuild])
    }
}

#if DEBUG
/// 시험 전용(Debug): -cduReport <이름> 이면 8초 뒤 화면 표시·상태를 Documents/smoke_cdu_<이름>.json 에 기록
enum CduSmoke {
    static func run(_ vc: CAPBridgeViewController) {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-cduReport"), i + 1 < a.count else { return }
        let label = a[i + 1]
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            vc.webView?.evaluateJavaScript("JSON.stringify({mark:(window.__CDUMARK||null),href:location.href,body:(document.body?document.body.innerText.length:-1)})") { res, _ in
                let fm = FileManager.default
                let up = AppUpdate.shared
                let st = up.loadState()
                var o: [String: Any] = ["label": label, "web": (res as? String) ?? "", "active": up.activeVer ?? "bundle",
                                        "ready": st.ready ?? "", "trying": st.trying ?? "", "blocked": st.blocked, "off": st.off, "build": up.currentBuild]
                o["dirs"] = (try? fm.contentsOfDirectory(atPath: up.root.path)) ?? []
                if let d = try? JSONSerialization.data(withJSONObject: o), let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
                    try? d.write(to: docs.appendingPathComponent("smoke_cdu_" + label + ".json"))
                }
            }
        }
    }
}
#endif
