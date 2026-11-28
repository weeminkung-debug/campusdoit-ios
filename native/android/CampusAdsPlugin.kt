package com.campusdoit.app

import android.graphics.Color
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.google.android.gms.ads.*
import com.google.ads.mediation.admob.AdMobAdapter
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import com.google.android.gms.ads.rewarded.RewardedAd
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback
import com.google.android.gms.ads.rewarded.ServerSideVerificationOptions

// 캠퍼스두잇 광고 플러그인(안드로이드) — iOS CampusAdsPlugin과 동일 계약. 단위 ID = res/values/ads.xml(ADMOB_*), 없으면 구글 테스트 단위
@CapacitorPlugin(name = "CampusAds")
class CampusAdsPlugin : Plugin() {
    companion object {
        // 비맞춤 광고만(5번방 #67): npa=1
        fun npaRequest(): AdRequest = AdRequest.Builder().addNetworkExtrasBundle(AdMobAdapter::class.java, Bundle().apply { putString("npa", "1") }).build()
        const val TEST_REWARDED = "ca-app-pub-3940256099942544/5224354917"
        const val TEST_BANNER = "ca-app-pub-3940256099942544/9214589741"
    }
    private var inited = false
    private var banner: AdView? = null
    private fun unit(key: String, fb: String): String {
        // 5번방 #131: 디버그(시험) 빌드는 늘 구글 테스트 단위 — 실제 단위는 에뮬에서 No fill·무효 트래픽 위험. 출시(release)는 그대로 실제 단위
        if ((activity.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0) { android.util.Log.i("CDUADS", "unit $key = $fb (debug demo)"); return fb }
        val id = activity.resources.getIdentifier(key, "string", activity.packageName)
        val v = if (id != 0) activity.getString(id) else ""
        return if (v.startsWith("ca-app-pub-") && !v.contains("__")) v else fb
    }
    private fun ensureInit() { if (!inited) { MobileAds.initialize(activity) {}; inited = true } }
    private fun dp(v: Double): Int = (v * activity.resources.displayMetrics.density).toInt()

    @PluginMethod fun requestATT(call: PluginCall) { call.resolve(JSObject().put("status", "n/a")) }

    @PluginMethod fun showRewarded(call: PluginCall) {
        ensureInit(); val uid = call.getString("userId") ?: ""; val dry = call.getBoolean("dryRun") ?: false
        val id = unit("ADMOB_REWARDED", TEST_REWARDED)
        activity.runOnUiThread {
            RewardedAd.load(activity, id, npaRequest(), object : RewardedAdLoadCallback() {
                override fun onAdFailedToLoad(e: LoadAdError) { android.util.Log.w("CDUADS", "rewarded fail $e"); call.resolve(JSObject().put("rewarded", false).put("error", "load_failed:" + e.message)) }
                override fun onAdLoaded(ad: RewardedAd) {
                    if (dry) { call.resolve(JSObject().put("rewarded", false).put("loaded", true).put("unit", id)); return }
                    ad.setServerSideVerificationOptions(ServerSideVerificationOptions.Builder().setUserId(uid).build())
                    var earned = false
                    ad.fullScreenContentCallback = object : FullScreenContentCallback() {
                        override fun onAdDismissedFullScreenContent() { call.resolve(JSObject().put("rewarded", earned).apply { if (!earned) put("error", "dismissed") }) }
                        override fun onAdFailedToShowFullScreenContent(e: AdError) { call.resolve(JSObject().put("rewarded", false).put("error", "present_failed:" + e.message)) }
                    }
                    ad.show(activity) { earned = true }
                }
            })
        }
    }
    // ── 미리 받기 + 2편 연달아(5번방 #71). pool은 메인 스레드에서만 만짐. 50분 지난 광고는 버림
    private val pool = ArrayList<RewardedAd>()
    private val poolAt = ArrayList<Long>()
    private var poolLoading = 0
    private var poolErr: String? = null
    private var chainCall: PluginCall? = null
    private var chainNeed = 0
    private var chainDone = 0
    private var chainUid = ""
    private var chainT0 = 0L
    private var chainTries = 0
    private val main = Handler(Looper.getMainLooper())
    private fun fillPool(n: Int) {
        val now = System.currentTimeMillis()
        var i = 0
        while (i < pool.size) { if (now - poolAt[i] > 3000000L) { pool.removeAt(i); poolAt.removeAt(i) } else i++ }
        val want = n - pool.size - poolLoading
        if (want <= 0) return
        val id = unit("ADMOB_REWARDED", TEST_REWARDED)
        for (k in 0 until want) {
            poolLoading++
            RewardedAd.load(activity, id, npaRequest(), object : RewardedAdLoadCallback() {
                override fun onAdFailedToLoad(e: LoadAdError) { main.post { poolLoading--; poolErr = e.message } }
                override fun onAdLoaded(ad: RewardedAd) { main.post { poolLoading--; pool.add(ad); poolAt.add(System.currentTimeMillis()); poolErr = null } }
            })
        }
    }
    @PluginMethod fun preloadRewarded(call: PluginCall) {
        ensureInit(); val n = (call.getInt("count") ?: 2).coerceIn(1, 2)
        activity.runOnUiThread { fillPool(n); call.resolve(JSObject().put("ready", pool.size).put("loading", poolLoading)) }
    }
    private fun chainEvent(type: String) { notifyListeners("rewardedEvent", JSObject().put("i", chainDone + 1).put("type", type).put("ms", System.currentTimeMillis() - chainT0)) }
    @PluginMethod fun showRewardedChain(call: PluginCall) {
        ensureInit()
        activity.runOnUiThread {
            if (chainCall != null) { call.resolve(JSObject().put("rewarded", 0).put("error", "busy")); return@runOnUiThread }
            chainCall = call; chainNeed = (call.getInt("count") ?: 2).coerceIn(1, 2); chainDone = 0
            chainUid = call.getString("userId") ?: ""; chainT0 = System.currentTimeMillis(); chainTries = 0; poolErr = null
            fillPool(chainNeed); presentNext()
        }
    }
    private fun presentNext() {
        if (chainCall == null) return
        if (pool.isEmpty()) {
            if (poolLoading == 0) { val e = poolErr; if (e != null) { finishChain("load_failed:$e"); return }; fillPool(1) }
            chainTries++
            if (chainTries > 250) { finishChain("load_timeout"); return }
            main.postDelayed({ presentNext() }, 100); return
        }
        val ad = pool.removeAt(0); poolAt.removeAt(0)
        ad.setServerSideVerificationOptions(ServerSideVerificationOptions.Builder().setUserId(chainUid).build())
        var earned = false
        ad.fullScreenContentCallback = object : FullScreenContentCallback() {
            override fun onAdShowedFullScreenContent() { chainEvent("shown") }
            override fun onAdDismissedFullScreenContent() {
                chainEvent("dismissed")
                if (!earned) { finishChain("dismissed"); return }
                chainDone++
                if (chainDone >= chainNeed) finishChain(null) else presentNext()   // 사이 화면 없이 바로 다음 편
            }
            override fun onAdFailedToShowFullScreenContent(e: AdError) { finishChain("present_failed:" + e.message) }
        }
        chainTries = 0
        ad.show(activity) { earned = true; chainEvent("earned") }
        if (chainDone + 1 < chainNeed) fillPool(1)
    }
    private fun finishChain(err: String?) {
        val c = chainCall ?: return; chainCall = null
        val r = JSObject().put("rewarded", chainDone).put("ms", System.currentTimeMillis() - chainT0); if (err != null) r.put("error", err); c.resolve(r)
    }
    @PluginMethod fun showBanner(call: PluginCall) {
        ensureInit()
        activity.runOnUiThread {
            val root = activity.findViewById<ViewGroup>(android.R.id.content)
            if (banner == null) {
                val b = AdView(activity); b.adUnitId = unit("ADMOB_BANNER", TEST_BANNER)
                val wdp = (root.width / activity.resources.displayMetrics.density).toInt()
                b.setAdSize(AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(activity, if (wdp > 0) wdp else 360))
                val lp = FrameLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT); lp.gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL; lp.bottomMargin = dp(56.0)
                root.addView(b, lp); b.loadAd(npaRequest()); banner = b
            }
            banner?.visibility = View.VISIBLE
            call.resolve(JSObject().put("height", 50))
        }
    }
    @PluginMethod fun hideBanner(call: PluginCall) { activity.runOnUiThread { banner?.visibility = View.GONE; call.resolve() } }

    @PluginMethod fun status(call: PluginCall) { call.resolve(JSObject().put("att", "n/a").put("rewardedUnit", unit("ADMOB_REWARDED", TEST_REWARDED)).put("test", unit("ADMOB_REWARDED", "") == "").put("chain", true).put("ready", pool.size)) }
}
