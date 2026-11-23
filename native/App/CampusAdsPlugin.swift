import Foundation
import Capacitor
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport
import WebKit

// 캠퍼스두잇 광고 플러그인(iOS) — 보상형(rewarded, 버튼 탭 직후만) · 적응형 배너 · 네이티브 광고 카드(오버레이)
// 단위 ID: Info.plist ADMOB_REWARDED / ADMOB_BANNER / ADMOB_NATIVE (빌드 시 Secrets 주입, 없으면 구글 테스트 단위)
@objc(CampusAdsPlugin)
public class CampusAdsPlugin: CAPPlugin, CAPBridgedPlugin, GADFullScreenContentDelegate, GADNativeAdLoaderDelegate, GADBannerViewDelegate {
    public let identifier = "CampusAdsPlugin"
    public let jsName = "CampusAds"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "requestATT", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showRewarded", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "preloadRewarded", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showRewardedChain", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showBanner", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "hideBanner", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showNativeCard", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "positionNativeCard", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "hideNativeCard", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "status", returnType: CAPPluginReturnPromise)
    ]
    // 비맞춤 광고만(ATT 안 띄움 · 5번방 #67): npa=1
    static func npaRequest() -> GADRequest { let r = GADRequest(); let x = GADExtras(); x.additionalParameters = ["npa": "1"]; r.register(x); return r }
    static let TEST_REWARDED = "ca-app-pub-3940256099942544/1712485313"
    static let TEST_BANNER   = "ca-app-pub-3940256099942544/2934735716"
    static let TEST_NATIVE   = "ca-app-pub-3940256099942544/3986624511"
    private var rewarded: GADRewardedAd?
    private var rewardedCall: CAPPluginCall?
    private var earned = false
    // 미리 받아 둔 보상형 광고(5번방 #71). 50분 지나면 버리고 다시 받음(광고는 1시간 뒤 못 씀)
    private var pool: [GADRewardedAd] = []
    private var poolAt: [Date] = []
    private var poolLoading = 0
    private var poolErr: String?
    private var chainCall: CAPPluginCall?
    private var chainNeed = 0
    private var chainDone = 0
    private var chainUid = ""
    private var chainT0 = Date()
    private var chainTries = 0
    private var banner: GADBannerView?
    private var nativeLoader: GADAdLoader?
    private var nativeAd: GADNativeAd?
    private var nativeView: GADNativeAdView?
    private var nativeCall: CAPPluginCall?
    private var initialized = false

    private func unit(_ key: String, _ fallback: String) -> String {
        if let v = Bundle.main.object(forInfoDictionaryKey: key) as? String, v.hasPrefix("ca-app-pub-"), !v.contains("__") { return v }
        return fallback
    }
    private func ensureInit() { if !initialized { GADMobileAds.sharedInstance().start(completionHandler: nil); initialized = true } }
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
        GADRewardedAd.load(withAdUnitID: id, request: CampusAdsPlugin.npaRequest()) { [weak self] ad, err in
            guard let self = self else { return }
            if let err = err { self.finishRewarded(false, "load_failed:\(err.localizedDescription)"); return }
            if call.getBool("dryRun") ?? false { self.rewardedCall = nil; call.resolve(["rewarded": false, "loaded": true, "unit": id]); return }
            guard let ad = ad, let vc = self.root() else { self.finishRewarded(false, "no_vc"); return }
            let ssv = GADServerSideVerificationOptions(); ssv.userIdentifier = uid; ad.serverSideVerificationOptions = ssv
            ad.fullScreenContentDelegate = self; self.rewarded = ad
            DispatchQueue.main.async { ad.present(fromRootViewController: vc) { self.earned = true } }
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
            GADRewardedAd.load(withAdUnitID: id, request: CampusAdsPlugin.npaRequest()) { [weak self] ad, err in
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
        let ssv = GADServerSideVerificationOptions(); ssv.userIdentifier = chainUid; ad.serverSideVerificationOptions = ssv
        ad.fullScreenContentDelegate = self; rewarded = ad; earned = false; chainTries = 0
        ad.present(fromRootViewController: vc) { self.earned = true; self.chainEvent("earned") }
        if chainDone + 1 < chainNeed { fillPool(1) }
    }
    private func finishChain(_ err: String?) {
        guard let c = chainCall else { return }; chainCall = nil; rewarded = nil
        var r: [String: Any] = ["rewarded": chainDone, "ms": Int(Date().timeIntervalSince(chainT0) * 1000)]; if let e = err { r["error"] = e }; c.resolve(r)
    }
    public func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) { if chainCall != nil { chainEvent("shown") } }
    private func finishRewarded(_ ok: Bool, _ err: String?) {
        guard let c = rewardedCall else { return }; rewardedCall = nil; rewarded = nil
        var r: [String: Any] = ["rewarded": ok]; if let e = err { r["error"] = e }; c.resolve(r)
    }
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        if chainCall != nil {
            chainEvent("dismissed")
            if !earned { finishChain("dismissed"); return }
            chainDone += 1; rewarded = nil
            if chainDone >= chainNeed { finishChain(nil) } else { presentNext() }   // 사이 화면 없이 바로 다음 편
            return
        }
        finishRewarded(earned, earned ? nil : "dismissed")
    }
    public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        if chainCall != nil { finishChain("present_failed:\(error.localizedDescription)"); return }
        finishRewarded(false, "present_failed:\(error.localizedDescription)")
    }

    // 적응형 배너: 하단 탭바 위
    @objc func showBanner(_ call: CAPPluginCall) {
        ensureInit()
        DispatchQueue.main.async {
            guard let vc = self.root(), let host = vc.view.window ?? vc.view else { call.reject("no_view"); return }
            if self.banner == nil {
                let width = host.bounds.width
                let b = GADBannerView(adSize: GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width))
                b.adUnitID = self.unit("ADMOB_BANNER", CampusAdsPlugin.TEST_BANNER); b.rootViewController = vc; b.delegate = self
                b.translatesAutoresizingMaskIntoConstraints = false; host.addSubview(b)
                let bottomInset = CGFloat(call.getInt("bottomInset") ?? 0)
                NSLayoutConstraint.activate([b.centerXAnchor.constraint(equalTo: host.centerXAnchor), b.bottomAnchor.constraint(equalTo: host.safeAreaLayoutGuide.bottomAnchor, constant: -bottomInset)])
                self.banner = b; b.load(CampusAdsPlugin.npaRequest())
            }
            self.banner?.isHidden = false
            call.resolve(["height": Double(self.banner?.adSize.size.height ?? 0)])
        }
    }
    @objc func hideBanner(_ call: CAPPluginCall) { DispatchQueue.main.async { self.banner?.isHidden = true; call.resolve() } }

    // 네이티브 광고 카드: 웹 목록 안 자리(top/height, CSS px)에 GADNativeAdView 오버레이
    @objc func showNativeCard(_ call: CAPPluginCall) {
        ensureInit(); nativeCall = call
        DispatchQueue.main.async {
            guard let vc = self.root() else { call.reject("no_vc"); return }
            if self.nativeAd != nil { self.placeNative(call); call.resolve(["loaded": true]); return }
            let opts = GADNativeAdViewAdOptions(); opts.preferredAdChoicesPosition = .topRightCorner
            self.nativeLoader = GADAdLoader(adUnitID: self.unit("ADMOB_NATIVE", CampusAdsPlugin.TEST_NATIVE), rootViewController: vc, adTypes: [.native], options: [opts])
            self.nativeLoader?.delegate = self; self.nativeLoader?.load(CampusAdsPlugin.npaRequest())
        }
    }
    public func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        self.nativeAd = nativeAd
        let v = GADNativeAdView(frame: .zero); v.backgroundColor = UIColor(red: 0.933, green: 0.941, blue: 0.957, alpha: 1); v.layer.cornerRadius = 8; v.clipsToBounds = true
        let tag = UILabel(); tag.text = "AD"; tag.font = .boldSystemFont(ofSize: 11); tag.textColor = UIColor(white: 0.54, alpha: 1); tag.layer.borderWidth = 1; tag.layer.borderColor = UIColor(white: 0.81, alpha: 1).cgColor; tag.layer.cornerRadius = 6; tag.textAlignment = .center
        let head = UILabel(); head.text = nativeAd.headline; head.font = .boldSystemFont(ofSize: 15); head.lineBreakMode = .byTruncatingTail; head.numberOfLines = 1
        let icon = UIImageView(image: nativeAd.icon?.image); icon.contentMode = .scaleAspectFit; icon.layer.cornerRadius = 4; icon.clipsToBounds = true
        let cta = UILabel(); cta.text = "›"; cta.textColor = UIColor(red: 0.169, green: 0.357, blue: 0.769, alpha: 1); cta.font = .systemFont(ofSize: 16)
        [tag, head, icon, cta].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; v.addSubview($0) }
        NSLayoutConstraint.activate([
            tag.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 8), tag.centerYAnchor.constraint(equalTo: v.centerYAnchor), tag.widthAnchor.constraint(equalToConstant: 30), tag.heightAnchor.constraint(equalToConstant: 18),
            icon.leadingAnchor.constraint(equalTo: tag.trailingAnchor, constant: 8), icon.centerYAnchor.constraint(equalTo: v.centerYAnchor), icon.widthAnchor.constraint(equalToConstant: nativeAd.icon == nil ? 0 : 22), icon.heightAnchor.constraint(equalToConstant: 22),
            head.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8), head.centerYAnchor.constraint(equalTo: v.centerYAnchor), head.trailingAnchor.constraint(equalTo: cta.leadingAnchor, constant: -8),
            cta.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -10), cta.centerYAnchor.constraint(equalTo: v.centerYAnchor)])
        v.headlineView = head; v.iconView = icon; v.callToActionView = cta; v.nativeAd = nativeAd
        nativeView = v
        if let c = nativeCall { if !(c.getBool("dryRun") ?? false) { placeNative(c) }; c.resolve(["loaded": true, "headline": nativeAd.headline ?? ""]) }; nativeCall = nil
    }
    public func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) { nativeCall?.resolve(["loaded": false, "error": error.localizedDescription]); nativeCall = nil }
    private func placeNative(_ call: CAPPluginCall) {
        guard let v = nativeView, let wv = bridge?.webView, let host = wv.superview else { return }
        if v.superview == nil { host.addSubview(v) }
        let top = CGFloat(call.getDouble("top") ?? 0), h = CGFloat(call.getDouble("height") ?? 47), x = CGFloat(call.getDouble("left") ?? 16), w = CGFloat(call.getDouble("width") ?? (wv.bounds.width - 32))
        v.frame = CGRect(x: wv.frame.minX + x, y: wv.frame.minY + top, width: w, height: h)
        v.isHidden = top + h < 0 || top > wv.bounds.height
    }
    @objc func positionNativeCard(_ call: CAPPluginCall) { DispatchQueue.main.async { self.placeNative(call); call.resolve() } }
    @objc func hideNativeCard(_ call: CAPPluginCall) { DispatchQueue.main.async { self.nativeView?.isHidden = true; call.resolve() } }
    @objc func status(_ call: CAPPluginCall) {
        var att = "n/a"; if #available(iOS 14, *) { att = ["notDetermined","restricted","denied","authorized"][Int(ATTrackingManager.trackingAuthorizationStatus.rawValue)] }
        call.resolve(["att": att, "rewardedUnit": unit("ADMOB_REWARDED", CampusAdsPlugin.TEST_REWARDED), "test": unit("ADMOB_REWARDED", "") == "", "chain": true, "ready": pool.count ])
    }
    public func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) { bannerView.isHidden = true }
    public func bannerViewDidReceiveAd(_ bannerView: GADBannerView) { bannerView.isHidden = false }
}
