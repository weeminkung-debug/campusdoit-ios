package com.campusdoit.app

import android.graphics.Color
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import android.content.res.ColorStateList
import android.view.ContextThemeWrapper
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
    private var polls = -1
    private var programmatic = false   // 5번방 #120: 안드로이드는 selectedItemId를 코드로 바꿔도 선택 리스너가 불림 → 웹 goApp이 다시 돌아 로그인 화면을 덮음

    override fun load() {
        h.postDelayed({ install() }, 200)
        val ex = activity?.intent?.extras
        val key = ex?.getString("smokeTab"); val action = ex?.getString("smokeAction")
        if (key != null) smoke(key, action)
    }
    private fun install() {
        val act = activity ?: return
        val root = act.findViewById<ViewGroup>(android.R.id.content) ?: return
        val themed = ContextThemeWrapper(act, com.google.android.material.R.style.Theme_MaterialComponents_DayNight_NoActionBar)
        val v = BottomNavigationView(themed)
        v.setBackgroundColor(Color.WHITE)
        val cobalt = Color.parseColor("#2B5BC4"); val gray = Color.parseColor("#8B8983")
        val states = arrayOf(intArrayOf(android.R.attr.state_checked), intArrayOf())
        v.itemIconTintList = ColorStateList(states, intArrayOf(cobalt, gray)); v.itemTextColor = ColorStateList(states, intArrayOf(cobalt, gray))
        v.labelVisibilityMode = BottomNavigationView.LABEL_VISIBILITY_LABELED
        val icons = listOf(R.drawable.ic_tab_cat, R.drawable.ic_tab_score, R.drawable.ic_tab_home, R.drawable.ic_tab_sched, R.drawable.ic_tab_my)
        keys.forEachIndexed { i, _ -> v.menu.add(0, i, i, titles[i]).setIcon(icons[i]) }
        v.selectedItemId = 2
        v.setOnItemSelectedListener { item -> if (!programmatic) select(keys[item.itemId]); true }   // 웹이 탭 표시만 바꿀 때(setActive)는 화면 이동을 다시 부르지 않음
        val lp = FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(56)); lp.gravity = Gravity.BOTTOM
        v.visibility = android.view.View.INVISIBLE
        root.addView(v, lp); nav = v
        pollDom(0)
    }
    private fun pollDom(n: Int) {
        val wv = bridge?.webView ?: return
        wv.evaluateJavascript("(function(){try{document.documentElement.style.setProperty('--native-tab-inset','56px'); document.body.classList.add('native-tabs'); return (document.readyState!=='loading'&&!!document.getElementById('bottomNav'))?1:0;}catch(e){return 0}})()") { r ->
            polls = n; if (r == "1" || n > 60) { h.postDelayed({ nav?.visibility = android.view.View.VISIBLE; if (revealAt < 0) revealAt = (System.currentTimeMillis() - t0) / 1000.0 }, 1300) }
            else h.postDelayed({ pollDom(n + 1) }, 100)
        }
    }
    private fun dp(v: Int): Int = (v * (activity?.resources?.displayMetrics?.density ?: 3f)).toInt()
    private fun select(key: String) { bridge?.webView?.evaluateJavascript("window.__nativeTab && window.__nativeTab('$key')", null) }
    @PluginMethod fun setActive(call: PluginCall) { val k = call.getString("key") ?: ""; val i = keys.indexOf(k); h.post { val n = nav; if (i >= 0 && n != null && n.selectedItemId != i) { programmatic = true; try { n.selectedItemId = i } finally { programmatic = false } } }; call.resolve() }
    @PluginMethod fun isAvailable(call: PluginCall) { call.resolve(JSObject().put("available", true)) }

    // 5번방 #136: 고정 시각 대신 '화면 준비됨'을 기다린 뒤 시험(느린 에뮬에서 2.5초에 탭을 눌러 놓쳐 MY=homeView, 9초에 화면이 덜 떠 기록이 비던 문제)
    private fun waitReady(n: Int, cb: () -> Unit) {
        val wv = bridge?.webView ?: run { h.postDelayed({ waitReady(n + 1, cb) }, 300); return }
        wv.evaluateJavascript("(function(){try{return (document.readyState!=='loading'&&typeof window.__nativeTab==='function'&&!!document.getElementById('bottomNav'))?1:0}catch(e){return 0}})()") { r ->
            if (r == "1" || n > 100) cb() else h.postDelayed({ waitReady(n + 1, cb) }, 300)
        }
    }
    private fun ev(js: String) { bridge?.webView?.evaluateJavascript(js, null) }
    private fun smoke(key: String, action: String?) {
        val t0s = System.currentTimeMillis()
        waitReady(0) {
            val readyAt = (System.currentTimeMillis() - t0s) / 1000.0
            ev("(function(){try{var d=document.getElementById('dmAgree'); if(d) d.click();}catch(e){} return 1;})()")
            h.postDelayed({ select(key) }, 800)
            if (action == "runSim") h.postDelayed({ ev("(function(){try{localStorage.removeItem('doit_token_v1');}catch(e){} try{goApp(); setScope('KR'); SCORE_TOUCHED=true; document.getElementById('scoreBigNum').value='88'; runSim();}catch(e){window.__smokeErr=String(e);} return 1;})()") }, 4000)
            if (action == "camSmoke") h.postDelayed({ ev("(function(){var i=document.createElement('input');i.type='file';i.accept='image/*';i.setAttribute('capture','environment');i.id='__camIn';i.style.display='none';document.body.appendChild(i);var b=document.createElement('button');b.id='__camBtn';b.style.cssText='position:fixed;inset:0;z-index:2147483647;opacity:0.01';b.onclick=function(){i.click()};document.body.appendChild(b);console.log('CDUCAM:ready');return 1})()") }, 1500)   // 5번방 #133: 프로필 '사진 찍기'(capture) → 카메라 앱이 뜨는지
            if (action == "adsSmoke") h.postDelayed({ ev("(function(){window.__ads={}; try{ var P=Capacitor.Plugins.CampusAds; P.status().then(function(s){window.__ads.status=s;}); P.showRewarded({userId:'0',dryRun:true}).then(function(r){window.__ads.rewarded=r;}).catch(function(e){window.__ads.rewarded={error:String(e)};}); P.showNativeCard({top:300,height:47,dryRun:true}).then(function(r){window.__ads.native=r;}).catch(function(e){window.__ads.native={error:String(e)};}); }catch(e){window.__ads.err=String(e);} return 1;})()") }, 1000)
            h.postDelayed({
                // 기록 JS는 절대 throw하지 않게(요소가 없으면 'missing') — 예전엔 bottomNav가 없으면 통째로 실패해 빈 기록
                val js = "(function(){var o={};try{o.view=(typeof _visView==='function'?_visView():'');}catch(e){o.view='err'} try{var bn=document.getElementById('bottomNav');o.nav=bn?getComputedStyle(bn).display:'missing';}catch(e){o.nav='err'} try{o.native=document.body.classList.contains('native-tabs');o.err=(window.__smokeErr||'');o.rs=document.readyState;o.logged=(typeof isLoggedIn==='function'?isLoggedIn():null);o.inset=getComputedStyle(document.documentElement).getPropertyValue('--native-tab-inset');o.ads=(window.__ads||null);}catch(e){o.jsErr=String(e)} return JSON.stringify(o)})()"
                bridge?.webView?.evaluateJavascript(js) { r ->
                    val o = try { JSONObject(JSONObject("{\"v\":${r ?: "\"{}\""}}").optString("v", "{}")) } catch (e: Exception) { JSONObject().put("parseErr", r ?: "null") }
                    try {
                        o.put("readyAt", readyAt); o.put("revealAt", revealAt); o.put("tabVisible", nav?.visibility == android.view.View.VISIBLE)
                        val dv = activity?.window?.decorView; val n = nav; val loc = IntArray(2); n?.getLocationOnScreen(loc)
                        o.put("padTop", dv?.paddingTop ?: -1); o.put("padBottom", dv?.paddingBottom ?: -1); o.put("tabBottom", if (n != null) loc[1] + n.height else -1); o.put("screenH", dv?.height ?: -1); o.put("sdk", android.os.Build.VERSION.SDK_INT); o.put("polls", polls)
                    } catch (e: Exception) { o.put("ktErr", e.toString()) }
                    try {
                        val dir = activity?.getExternalFilesDir(null) ?: activity?.filesDir
                        val fname = if (action == "adsSmoke") "smoke_ads.json" else if (action == "camSmoke") "smoke_cam.json" else "smoke_$key.json"
                        File(dir, fname).writeText(o.toString())
                    } catch (e: Exception) { android.util.Log.e("CDUSMOKE", "write fail $e") }
                }
            }, if (action == null) 6000L else if (action == "adsSmoke") 16000L else 9000L)
        }
    }
}
