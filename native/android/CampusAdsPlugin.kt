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
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import com.google.android.gms.ads.rewarded.RewardedAd
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback
import com.google.android.gms.ads.rewarded.ServerSideVerificationOptions

// 캠퍼스두잇 광고 플러그인(안드로이드) — iOS CampusAdsPlugin과 동일 계약. 단위 ID = res/values/ads.xml(ADMOB_*), 없으면 구글 테스트 단위
@CapacitorPlugin(name = "CampusAds")
class CampusAdsPlugin : Plugin() {
    companion object {
        const val TEST_REWARDED = "ca-app-pub-3940256099942544/5224354917"
        const val TEST_BANNER = "ca-app-pub-3940256099942544/9214589741"
        const val TEST_NATIVE = "ca-app-pub-3940256099942544/2247696110"
    }
    private var inited = false
    private var banner: AdView? = null
    private var nativeAd: NativeAd? = null
    private var nativeView: NativeAdView? = null
    private fun unit(key: String, fb: String): String {
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
            RewardedAd.load(activity, id, AdRequest.Builder().build(), object : RewardedAdLoadCallback() {
                override fun onAdFailedToLoad(e: LoadAdError) { call.resolve(JSObject().put("rewarded", false).put("error", "load_failed:" + e.message)) }
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
    @PluginMethod fun showBanner(call: PluginCall) {
        ensureInit()
        activity.runOnUiThread {
            val root = activity.findViewById<ViewGroup>(android.R.id.content)
            if (banner == null) {
                val b = AdView(activity); b.adUnitId = unit("ADMOB_BANNER", TEST_BANNER)
                val wdp = (root.width / activity.resources.displayMetrics.density).toInt()
                b.setAdSize(AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(activity, if (wdp > 0) wdp else 360))
                val lp = FrameLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT); lp.gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL; lp.bottomMargin = dp(56.0)
                root.addView(b, lp); b.loadAd(AdRequest.Builder().build()); banner = b
            }
            banner?.visibility = View.VISIBLE
            call.resolve(JSObject().put("height", 50))
        }
    }
    @PluginMethod fun hideBanner(call: PluginCall) { activity.runOnUiThread { banner?.visibility = View.GONE; call.resolve() } }

    @PluginMethod fun showNativeCard(call: PluginCall) {
        ensureInit(); val dry = call.getBoolean("dryRun") ?: false
        activity.runOnUiThread {
            if (nativeAd != null) { if (!dry) place(call); call.resolve(JSObject().put("loaded", true)); return@runOnUiThread }
            val loader = AdLoader.Builder(activity, unit("ADMOB_NATIVE", TEST_NATIVE)).forNativeAd { ad ->
                nativeAd = ad
                val v = NativeAdView(activity); v.setBackgroundColor(Color.parseColor("#EEF0F4"))
                val row = LinearLayout(activity); row.orientation = LinearLayout.HORIZONTAL; row.gravity = Gravity.CENTER_VERTICAL; row.setPadding(dp(8.0), 0, dp(10.0), 0)
                val tag = TextView(activity); tag.text = "AD"; tag.textSize = 11f; tag.setTextColor(Color.parseColor("#8A8A8A")); tag.setPadding(dp(5.0), dp(1.0), dp(5.0), dp(1.0))
                val icon = ImageView(activity); icon.setImageDrawable(ad.icon?.drawable); icon.layoutParams = LinearLayout.LayoutParams(dp(22.0), dp(22.0)).apply { marginStart = dp(8.0) }
                val head = TextView(activity); head.text = ad.headline; head.textSize = 15f; head.setTextColor(Color.parseColor("#1C1C1E")); head.maxLines = 1; head.ellipsize = android.text.TextUtils.TruncateAt.END; head.setTypeface(null, android.graphics.Typeface.BOLD); head.layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply { marginStart = dp(8.0) }
                val cta = TextView(activity); cta.text = "›"; cta.textSize = 16f; cta.setTextColor(Color.parseColor("#2B5BC4"))
                row.addView(tag); row.addView(icon); row.addView(head); row.addView(cta); v.addView(row, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
                v.headlineView = head; v.iconView = icon; v.callToActionView = cta; v.setNativeAd(ad)
                nativeView = v
                if (!dry) place(call); call.resolve(JSObject().put("loaded", true).put("headline", ad.headline ?: ""))
            }.withAdListener(object : AdListener() { override fun onAdFailedToLoad(e: LoadAdError) { call.resolve(JSObject().put("loaded", false).put("error", e.message)) } }).build()
            loader.loadAd(AdRequest.Builder().build())
        }
    }
    private fun place(call: PluginCall) {
        val v = nativeView ?: return; val root = activity.findViewById<ViewGroup>(android.R.id.content)
        if (v.parent == null) root.addView(v)
        val top = call.getDouble("top") ?: 0.0; val h = call.getDouble("height") ?: 47.0; val left = call.getDouble("left") ?: 16.0; val w = call.getDouble("width") ?: 328.0
        val lp = FrameLayout.LayoutParams(dp(w), dp(h)); lp.leftMargin = dp(left); lp.topMargin = dp(top); v.layoutParams = lp
        v.visibility = if (top + h < 0 || dp(top) > root.height) View.INVISIBLE else View.VISIBLE
    }
    @PluginMethod fun positionNativeCard(call: PluginCall) { activity.runOnUiThread { place(call); call.resolve() } }
    @PluginMethod fun hideNativeCard(call: PluginCall) { activity.runOnUiThread { nativeView?.visibility = View.GONE; call.resolve() } }
    @PluginMethod fun status(call: PluginCall) { call.resolve(JSObject().put("att", "n/a").put("rewardedUnit", unit("ADMOB_REWARDED", TEST_REWARDED)).put("test", unit("ADMOB_REWARDED", "") == "")) }
}
