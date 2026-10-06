package com.campusdoit.app

import android.graphics.Color
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import android.content.res.ColorStateList
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.google.android.material.bottomnavigation.BottomNavigationView
import android.os.Handler
import android.os.Looper
import org.json.JSONObject
import java.io.File

// 캠퍼스두잇 안드로이드 셸 — iOS NativeTabsPlugin과 동일 계약: 5탭(cat·score·home·sched·my), 웹 __nativeTab(key) 호출, setActive 동기, 라이트 전용
@CapacitorPlugin(name = "NativeTabs")
class NativeTabsPlugin : Plugin() {
    private val keys = listOf("cat", "score", "home", "sched", "my")
    private val titles = listOf("카테고리", "점수진단", "홈", "일정", "MY")
    private var nav: BottomNavigationView? = null
    private val h = Handler(Looper.getMainLooper())
    private var t0 = System.currentTimeMillis()
    private var revealAt = -1.0

    override fun load() {
        h.postDelayed({ install() }, 200)
        val ex = activity?.intent?.extras
        val key = ex?.getString("smokeTab"); val action = ex?.getString("smokeAction")
        if (key != null) smoke(key, action)
    }
    private fun install() {
        val act = activity ?: return
        val root = act.findViewById<ViewGroup>(android.R.id.content) ?: return
        val v = BottomNavigationView(act)
        v.setBackgroundColor(Color.WHITE)
        val cobalt = Color.parseColor("#2B5BC4"); val gray = Color.parseColor("#8B8983")
        val states = arrayOf(intArrayOf(android.R.attr.state_checked), intArrayOf())
        v.itemIconTintList = ColorStateList(states, intArrayOf(cobalt, gray)); v.itemTextColor = ColorStateList(states, intArrayOf(cobalt, gray))
        v.labelVisibilityMode = BottomNavigationView.LABEL_VISIBILITY_LABELED
        val icons = listOf(R.drawable.ic_tab_cat, R.drawable.ic_tab_score, R.drawable.ic_tab_home, R.drawable.ic_tab_sched, R.drawable.ic_tab_my)
        keys.forEachIndexed { i, _ -> v.menu.add(0, i, i, titles[i]).setIcon(icons[i]) }
        v.selectedItemId = 2
        v.setOnItemSelectedListener { item -> select(keys[item.itemId]); true }
        val lp = FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(56)); lp.gravity = Gravity.BOTTOM
        v.visibility = android.view.View.INVISIBLE
        root.addView(v, lp); nav = v
        pollDom(0)
    }
    private fun pollDom(n: Int) {
        val wv = bridge?.webView ?: return
        wv.evaluateJavascript("(function(){try{document.documentElement.style.setProperty('--native-tab-inset','56px'); document.body.classList.add('native-tabs'); return (document.readyState==='complete'&&!!document.getElementById('bottomNav'))?1:0;}catch(e){return 0}})()") { r ->
            if (r == "1" || n > 60) { h.postDelayed({ nav?.visibility = android.view.View.VISIBLE; if (revealAt < 0) revealAt = (System.currentTimeMillis() - t0) / 1000.0 }, 1300) }
            else h.postDelayed({ pollDom(n + 1) }, 100)
        }
    }
    private fun dp(v: Int): Int = (v * (activity?.resources?.displayMetrics?.density ?: 3f)).toInt()
    private fun select(key: String) { bridge?.webView?.evaluateJavascript("window.__nativeTab && window.__nativeTab('$key')", null) }
    @PluginMethod fun setActive(call: PluginCall) { val k = call.getString("key") ?: ""; val i = keys.indexOf(k); h.post { if (i >= 0) nav?.selectedItemId = i }; call.resolve() }
    @PluginMethod fun isAvailable(call: PluginCall) { call.resolve(JSObject().put("available", true)) }

    private fun smoke(key: String, action: String?) {
        h.postDelayed({ bridge?.webView?.evaluateJavascript("(function(){try{var d=document.getElementById('dmAgree'); if(d) d.click();}catch(e){} return 1;})()", null) }, 1500)
        h.postDelayed({ select(key) }, 2500)
        if (action == "runSim") h.postDelayed({ bridge?.webView?.evaluateJavascript("(function(){try{localStorage.removeItem('doit_token_v1');}catch(e){} try{goApp(); setScope('KR'); SCORE_TOUCHED=true; document.getElementById('scoreBigNum').value='88'; runSim();}catch(e){window.__smokeErr=String(e);} return 1;})()", null) }, 5000)
        if (action == "adsSmoke") h.postDelayed({ bridge?.webView?.evaluateJavascript("(function(){window.__ads={}; try{ var P=Capacitor.Plugins.CampusAds; P.status().then(function(s){window.__ads.status=s;}); P.showRewarded({userId:'0',dryRun:true}).then(function(r){window.__ads.rewarded=r;}).catch(function(e){window.__ads.rewarded={error:String(e)};}); P.showNativeCard({top:300,height:47,dryRun:true}).then(function(r){window.__ads.native=r;}).catch(function(e){window.__ads.native={error:String(e)};}); }catch(e){window.__ads.err=String(e);} try{ goApp(); setScope('KR'); var h=document.getElementById('result'); h.innerHTML='<div>x</div>'; _kLock(h,'score_result','smoke'); window.__ads.card={blur:h.classList.contains('kblur'), btns:[...h.querySelectorAll('.kbtn')].map(function(b){return b.textContent.trim();})}; }catch(e){window.__ads.cardErr=String(e);} return 1;})()", null) }, 3000)
        h.postDelayed({
            val js = "JSON.stringify({view:(typeof _visView==='function'?_visView():''), nav:getComputedStyle(document.getElementById('bottomNav')).display, native:document.body.classList.contains('native-tabs'), err:(window.__smokeErr||''), logged:(typeof isLoggedIn==='function'?isLoggedIn():null), inset:getComputedStyle(document.documentElement).getPropertyValue('--native-tab-inset'), ads:(window.__ads||null)})"
            bridge?.webView?.evaluateJavascript(js) { r ->
                try {
                    var s = r ?: "\"{}\""; s = JSONObject("{\"v\":$s}").getString("v")
                    val o = JSONObject(s); o.put("revealAt", revealAt); o.put("tabVisible", nav?.visibility == android.view.View.VISIBLE)
                    val dir = activity?.getExternalFilesDir(null) ?: activity?.filesDir
                    val fname = if (action == "adsSmoke") "smoke_ads.json" else "smoke_$key.json"
                    File(dir, fname).writeText(o.toString())
                } catch (e: Exception) { }
            }
        }, if (action == null) 6000L else 12000L)
    }
}
