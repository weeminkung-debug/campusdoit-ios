import Foundation
import Capacitor
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport
import WebKit

// Google Mobile Ads SDK v12(5번방 #141: v11은 Deprecated) — Swift 이름은 GAD 접두 없음
// 캠퍼스두잇 광고 플러그인(iOS) — 보상형(rewarded, 버튼 탭 직후만) · 적응형 배너 
// 단위 ID: Info.plist ADMOB_REWARDED (빌드 시 Secrets 주입, 없으면 구글 테스트 단위). 배너 광고는 쓰지 않음(5번방 #156·#167)
@objc(CampusAdsPlugin)
public class CampusAdsPlugin: CAPPlugin, CAPBridgedPlugin, FullScreenContentDelegate {
    public let identifier = "CampusAdsPlugin"
    public let jsName = "CampusAds"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "requestATT", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showRewarded", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "preloadRewarded", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showRewardedChain", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "status", returnType: CAPPluginReturnPromise)
    ]
    // 비맞춤 광고만(ATT 안 띄움 · 5번방 #67): npa=1
    static func npaRequest() -> Request { let r = Request(); let x = Extras(); x.additionalParameters = ["npa": "1"]; r.register(x); return r }
    static let TEST_REWARDED = "ca-app-pub-3940256099942544/1712485313"
    private var rewarded: RewardedAd?
    private var rewardedCall: CAPPluginCall?
    private var earned = false
    // 미리 받아 둔 보상형 광고(5번방 #71). 50분 지나면 버리고 다시 받음(광고는 1시간 뒤 못 씀)
    private var pool: [RewardedAd] = []
    private var poolAt: [Date] = []
    private var poolLoading = 0
    private var poolErr: String?
    private var chainCall: CAPPluginCall?
    private var chainNeed = 0
    private var chainDone = 0
    private var chainUid = ""
    private var chainT0 = Date()
    private var chainTries = 0
    private var initialized = false

    private func unit(_ key: String, _ fallback: String) -> String {
        if let v = Bundle.main.object(forInfoDictionaryKey: key) as? String, v.hasPrefix("ca-app-pub-"), !v.contains("__") { return v }
        return fallback
    }
    private func ensureInit() { if !initialized { MobileAds.shared.start(completionHandler: nil); initialized = true } }
    private func root() -> UIViewController? { return bridge?.viewController }

    // ATT: 첫 광고 직전 1회. 거부/미결정이어도 광고는 비개인화로 진행
    @objc func requestATT(_ call: CAPPluginCall) {
        // ATT 안 띄움(5번방 #67) — 창을 띄우지 않고 현재 상태만 돌려줌(설명 문구가 없어 요청 시 앱이 멈추므로 호출 금지)
        if #available(iOS 14, *) { call.resolve(["status": ["notDetermined","restricted","denied","authorized"][Int(ATTrackingManager.trackingAuthorizationStatus.rawValue)], "prompt": false]) }
        else { call.resolve(["status": "n/a", "prompt": false]) }
    }

    // 보상형: 사용자가 "광고 보고 결과 열기"를 탭한 직후에만 호출됨(정책: 개별 동의). SSV userId = users.id
    @objc func showRewarded(_ call: CAPPluginCall) {
        ensureInit(); rewardedCall = call; earned = false
        let uid = call.getString("userId") ?? ""
        let id = unit("ADMOB_REWARDED", CampusAdsPlugin.TEST_REWARDED)
        RewardedAd.load(with: id, request: CampusAdsPlugin.npaRequest()) { [weak self] ad, err in
            guard let self = self else { return }
            if let err = err { self.finishRewarded(false, "load_failed:\(err.localizedDescription)"); return }
            if call.getBool("dryRun") ?? false { self.rewardedCall = nil; call.resolve(["rewarded": false, "loaded": true, "unit": id]); return }
            guard let ad = ad, let vc = self.root() else { self.finishRewarded(false, "no_vc"); return }
            let ssv = ServerSideVerificationOptions(); ssv.userIdentifier = uid; ad.serverSideVerificationOptions = ssv
            ad.fullScreenContentDelegate = self; self.rewarded = ad
            DispatchQueue.main.async { ad.present(from: vc) { self.earned = true } }
        }
    }
    // ── 미리 받기 + 2편 연달아(5번방 #71) ── 반드시 메인 스레드에서만 pool을 만짐
    private func fillPool(_ n: Int) {
        var i = 0
        while i < pool.count { if Date().timeIntervalSince(poolAt[i]) > 3000 { pool.remove(at: i); poolAt.remove(at: i) } else { i += 1 } }
        let want = n - pool.count - poolLoading
        if want <= 0 { return }
        let id = unit("ADMOB_REWARDED", CampusAdsPlugin.TEST_REWARDED)
        for _ in 0..<want {
            poolLoading += 1
            RewardedAd.load(with: id, request: CampusAdsPlugin.npaRequest()) { [weak self] ad, err in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.poolLoading -= 1
                    if let ad = ad { self.pool.append(ad); self.poolAt.append(Date()); self.poolErr = nil }
                    else { self.poolErr = err?.localizedDescription ?? "load" }
                }
            }
        }
    }
    @objc func preloadRewarded(_ call: CAPPluginCall) {
        ensureInit(); let n = max(1, min(2, call.getInt("count") ?? 2))
        DispatchQueue.main.async { self.fillPool(n); call.resolve(["ready": self.pool.count, "loading": self.poolLoading]) }
    }
    private func chainEvent(_ type: String) {
        notifyListeners("rewardedEvent", data: ["i": chainDone + 1, "type": type, "ms": Int(Date().timeIntervalSince(chainT0) * 1000)])
    }
    @objc func showRewardedChain(_ call: CAPPluginCall) {
        ensureInit()
        DispatchQueue.main.async {
            if self.chainCall != nil || self.rewardedCall != nil { call.resolve(["rewarded": 0, "error": "busy"]); return }
            self.chainCall = call; self.chainNeed = max(1, min(2, call.getInt("count") ?? 2)); self.chainDone = 0
            self.chainUid = call.getString("userId") ?? ""; self.chainT0 = Date(); self.chainTries = 0; self.poolErr = nil
            self.fillPool(self.chainNeed); self.presentNext()
        }
    }
    private func presentNext() {
        guard chainCall != nil else { return }
        if pool.isEmpty {
            if poolLoading == 0 { if let e = poolErr { finishChain("load_failed:\(e)"); return }; fillPool(1) }
            chainTries += 1
            if chainTries > 250 { finishChain("load_timeout"); return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.presentNext() }; return
        }
        guard let vc = root() else { finishChain("no_vc"); return }
        if vc.presentedViewController != nil {
            chainTries += 1
            if chainTries > 250 { finishChain("present_timeout"); return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self.presentNext() }; return
        }
        let ad = pool.removeFirst(); poolAt.removeFirst()
        let ssv = ServerSideVerificationOptions(); ssv.userIdentifier = chainUid; ad.serverSideVerificationOptions = ssv
        ad.fullScreenContentDelegate = self; rewarded = ad; earned = false; chainTries = 0
        ad.present(from: vc) { self.earned = true; self.chainEvent("earned") }
        if chainDone + 1 < chainNeed { fillPool(1) }
    }
    private func finishChain(_ err: String?) {
        guard let c = chainCall else { return }; chainCall = nil; rewarded = nil
        var r: [String: Any] = ["rewarded": chainDone, "ms": Int(Date().timeIntervalSince(chainT0) * 1000)]; if let e = err { r["error"] = e }; c.resolve(r)
    }
    public func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) { if chainCall != nil { chainEvent("shown") } }
    private func finishRewarded(_ ok: Bool, _ err: String?) {
        guard let c = rewardedCall else { return }; rewardedCall = nil; rewarded = nil
        var r: [String: Any] = ["rewarded": ok]; if let e = err { r["error"] = e }; c.resolve(r)
    }
    public func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        if chainCall != nil {
            chainEvent("dismissed")
            if !earned { finishChain("dismissed"); return }
            chainDone += 1; rewarded = nil
            if chainDone >= chainNeed { finishChain(nil) } else { presentNext() }   // 사이 화면 없이 바로 다음 편
            return
        }
        finishRewarded(earned, earned ? nil : "dismissed")
    }
    public func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        if chainCall != nil { finishChain("present_failed:\(error.localizedDescription)"); return }
        finishRewarded(false, "present_failed:\(error.localizedDescription)")
    }

    @objc func status(_ call: CAPPluginCall) {
        var att = "n/a"; if #available(iOS 14, *) { att = ["notDetermined","restricted","denied","authorized"][Int(ATTrackingManager.trackingAuthorizationStatus.rawValue)] }
        call.resolve(["att": att, "rewardedUnit": unit("ADMOB_REWARDED", CampusAdsPlugin.TEST_REWARDED), "test": unit("ADMOB_REWARDED", "") == "", "chain": true, "ready": pool.count ])
    }
}
