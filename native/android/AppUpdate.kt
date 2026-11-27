package com.campusdoit.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Base64
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.security.KeyFactory
import java.security.MessageDigest
import java.security.Signature
import java.security.spec.X509EncodedKeySpec
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * 앱 자동 최신(5번방 #97, 방법 C · 11-24 구조). iOS AppUpdate.swift와 같은 규칙.
 * Capacitor에 폴더를 저장(persist)하지 않고, Bridge가 만들어지기 전에 이번 실행에 쓸 폴더만 정한다.
 */
object AppUpdate {
    const val ORIGIN = "https://campusdoit.com"
    const val MANIFEST_PATH = "/app/manifest.json"
    const val PUBLIC_KEY_B64 = "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEm0NlYlpIUzs2eaDI5UgHoON7qqm0A3+Mbak+hdTa7AyQ/k7uMQlFES4HTo/8hNsE5XGWvtQ+YtpmGxpa+uFILA=="
    const val READY_TIMEOUT_MS = 10_000L
    const val LAUNCH_BUDGET_MS = 800L

    var origin = ORIGIN
    var pubKey = PUBLIC_KEY_B64
    @Volatile var activeVer: String? = null
    @Volatile private var readyReceived = false
    @Volatile private var running = false
    private val exec = Executors.newSingleThreadExecutor()
    lateinit var root: File
    var currentBuild = 0

    data class State(var build: Int, var ready: String?, var trying: String?, var blocked: MutableList<String>, var off: Boolean)

    fun init(ctx: Context) {
        root = File(ctx.filesDir, "cdu")
        currentBuild = try {
            val pi = ctx.packageManager.getPackageInfo(ctx.packageName, 0)
            if (android.os.Build.VERSION.SDK_INT >= 28) pi.longVersionCode.toInt() else @Suppress("DEPRECATION") pi.versionCode
        } catch (e: Exception) { 0 }
    }

    /** Bridge 만들기 전에 부름. 반환 = 이번 실행에 쓸 폴더 경로 또는 null(넣어 둔 화면) */
    fun pickFolderAtLaunch(ctx: Context): String? {
        return try {
            init(ctx)
            // Capacitor가 저장해 둔 폴더 값은 늘 지움
            ctx.getSharedPreferences("CapWebViewSettings", Context.MODE_PRIVATE).edit().remove("serverBasePath").commit()
            root.mkdirs()
            var st = loadState()
            if (st.build != currentBuild) {                       // 7) 빌드 번호 바뀜 → 전부 삭제
                root.listFiles()?.forEach { it.deleteRecursively() }
                st = State(currentBuild, null, null, mutableListOf(), false); saveState(st)
            }
            root.listFiles()?.filter { it.name.startsWith("tmp_") }?.forEach { it.deleteRecursively() }   // 6)
            st.trying?.let { t ->                                 // 4) 지난번 준비됨 못 받음 → 막고 넣어 둔 화면
                if (!st.blocked.contains(t)) st.blocked.add(t)
                if (st.ready == t) st.ready = null
                st.trying = null; saveState(st); cleanup(emptyList()); return null
            }
            if (!st.off) { checkAndDownload(LAUNCH_BUDGET_MS); st = loadState() }
            val v = st.ready
            if (st.off || v == null || st.blocked.contains(v)) { cleanup(emptyList()); return null }
            val dir = verifiedDir(v) ?: run { cleanup(emptyList()); return null }
            st.trying = v                                         // 1)~3) "시도 중"을 먼저 적고 갈아탐
            if (!saveState(st)) return null
            activeVer = v
            cleanup(listOf(v))
            dir.absolutePath
        } catch (e: Throwable) { null }
    }

    fun verifiedDir(v: String): File? {
        if (!safeName(v)) return null
        val d = File(root, v)
        if (!d.isDirectory || !File(d, "index.html").isFile) return null
        val ok = try { File(d, "cdu_ok").readText().trim() } catch (e: Exception) { return null }
        return if (ok == v) d else null
    }

    @Synchronized fun markReady() {
        val st = loadState()
        if (st.trying != null) { st.trying = null; saveState(st) }
        readyReceived = true
    }

    fun armReadyTimeout(onFallback: () -> Unit) {
        if (activeVer == null) return
        Handler(Looper.getMainLooper()).postDelayed({
            val v = activeVer
            if (!readyReceived && v != null) {
                val st = loadState()
                if (!st.blocked.contains(v)) st.blocked.add(v)
                if (st.ready == v) st.ready = null
                st.trying = null; saveState(st)
                activeVer = null
                onFallback()
            }
        }, READY_TIMEOUT_MS)
    }

    fun checkAndDownload(budgetMs: Long): Boolean {
        val f = exec.submit<Boolean> { runUpdate() }
        return try { f.get(budgetMs, TimeUnit.MILLISECONDS) } catch (e: Exception) { false }
    }

    fun runUpdateInBackground() { exec.submit { runUpdate() } }

    private fun runUpdate(): Boolean {
        synchronized(this) { if (running) return false; running = true }
        try {
            val env = JSONObject(String(fetch(origin + MANIFEST_PATH, 4000), Charsets.UTF_8))
            val body = Base64.decode(env.getString("body"), Base64.DEFAULT)
            val sig = Base64.decode(env.getString("sig"), Base64.DEFAULT)
            if (!verify(body, sig)) return false
            val m = JSONObject(String(body, Charsets.UTF_8))
            val ver = m.getString("ver")
            var st = loadState()
            if (ver == "off") { st.off = true; st.ready = null; saveState(st); return true }
            if (st.off) { st.off = false; saveState(st) }
            if (!safeName(ver) || st.blocked.contains(ver)) return false
            if (m.optInt("min_shell", 0) > currentBuild) return false
            if (st.ready == ver && verifiedDir(ver) != null) return true
            val files = m.getJSONArray("files")
            if (files.length() == 0) return false
            val tmp = File(root, "tmp_$ver"); tmp.deleteRecursively(); tmp.mkdirs()
            val have = st.ready?.let { verifiedDir(it) }
            var hasIndex = false
            for (i in 0 until files.length()) {
                val f = files.getJSONObject(i)
                val p = f.getString("p"); val h = f.getString("h")
                if (!safePath(p)) throw Exception("bad path")
                if (p == "index.html") hasIndex = true
                val dest = File(tmp, p); dest.parentFile?.mkdirs()
                var got: ByteArray? = null
                if (have != null) { val c = File(have, p); if (c.isFile) { val d = c.readBytes(); if (sha256(d) == h) got = d } }
                if (got == null) got = bundled(p)?.takeIf { sha256(it) == h }
                if (got == null) {
                    val u = f.getString("u")
                    if (!u.startsWith("/") || u.startsWith("//")) throw Exception("bad url")
                    val enc = u.split("/").joinToString("/") { URLEncoder.encode(it, "UTF-8").replace("+", "%20") }
                    val d = fetch(origin + enc, 20000)
                    if (sha256(d) != h) throw Exception("sha")
                    got = d
                }
                dest.writeBytes(got)
            }
            if (!hasIndex) throw Exception("no index")
            File(tmp, "cdu_ok").writeText(ver)
            val fin = File(root, ver)
            if (fin.exists()) { if (activeVer == ver) { tmp.deleteRecursively(); return true }; fin.deleteRecursively() }
            if (!tmp.renameTo(fin)) throw Exception("rename")
            st = loadState(); st.ready = ver; saveState(st)
            return true
        } catch (e: Throwable) {
            return false
        } finally { synchronized(this) { running = false } }
    }

    var assets: android.content.res.AssetManager? = null
    private fun bundled(p: String): ByteArray? = try { assets?.open("public/$p")?.use { it.readBytes() } } catch (e: Exception) { null }

    private fun fetch(u: String, timeoutMs: Int): ByteArray {
        val c = URL(u).openConnection() as HttpURLConnection
        c.connectTimeout = timeoutMs; c.readTimeout = timeoutMs
        c.useCaches = false; c.instanceFollowRedirects = false
        c.setRequestProperty("Cookie", "")
        try {
            if (c.responseCode != 200) throw Exception("http ${c.responseCode}")
            return c.inputStream.use { it.readBytes() }
        } finally { c.disconnect() }
    }

    private fun verify(body: ByteArray, sig: ByteArray): Boolean = try {
        val key = KeyFactory.getInstance("EC").generatePublic(X509EncodedKeySpec(Base64.decode(pubKey, Base64.DEFAULT)))
        Signature.getInstance("SHA256withECDSA").run { initVerify(key); update(body); verify(sig) }
    } catch (e: Exception) { false }

    private fun sha256(d: ByteArray) = MessageDigest.getInstance("SHA-256").digest(d).joinToString("") { "%02x".format(it) }
    private fun safeName(s: String) = s.length in 1..64 && Regex("^[A-Za-z0-9_-]+$").matches(s) && !s.startsWith("tmp_")
    private fun safePath(p: String) = p.length in 1..200 && !p.startsWith("/") && !p.contains("..") && !p.contains("\\") &&
        Regex("^[A-Za-z0-9_./-]+$").matches(p) && p != "cdu_ok"

    private fun cleanup(keep: List<String>) {
        val st = loadState()
        val k = keep.toMutableSet(); st.ready?.let { k.add(it) }; activeVer?.let { k.add(it) }
        root.listFiles()?.forEach { if (it.name != "cdu_state.json" && !it.name.startsWith("tmp_") && !k.contains(it.name)) it.deleteRecursively() }
    }

    fun loadState(): State = try {
        val o = JSONObject(File(root, "cdu_state.json").readText())
        val b = o.optJSONArray("blocked") ?: JSONArray()
        State(o.optInt("build", currentBuild), o.optString("ready").ifEmpty { null }, o.optString("trying").ifEmpty { null },
            MutableList(b.length()) { b.getString(it) }, o.optBoolean("off", false))
    } catch (e: Exception) { State(currentBuild, null, null, mutableListOf(), false) }

    fun saveState(s: State): Boolean = try {
        val o = JSONObject().put("build", s.build).put("ready", s.ready ?: "").put("trying", s.trying ?: "")
            .put("blocked", JSONArray(s.blocked)).put("off", s.off)
        val tmp = File(root, "cdu_state.json.tmp"); tmp.writeText(o.toString())
        tmp.renameTo(File(root, "cdu_state.json"))
    } catch (e: Exception) { false }
}

@CapacitorPlugin(name = "AppUpdate")
class AppUpdatePlugin : Plugin() {
    @PluginMethod
    fun ready(call: PluginCall) {
        AppUpdate.markReady()
        call.resolve(JSObject().put("ver", AppUpdate.activeVer ?: "bundle"))
        AppUpdate.runUpdateInBackground()
    }
    @PluginMethod
    fun info(call: PluginCall) {
        call.resolve(JSObject().put("ver", AppUpdate.activeVer ?: "bundle").put("build", AppUpdate.currentBuild))
    }
}
