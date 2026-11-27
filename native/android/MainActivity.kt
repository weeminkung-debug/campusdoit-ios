package com.campusdoit.app

import android.os.Bundle
import com.getcapacitor.BridgeActivity
import com.getcapacitor.ServerPath

class MainActivity : BridgeActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        registerPlugin(NativeTabsPlugin::class.java)
        registerPlugin(CampusAdsPlugin::class.java)
        registerPlugin(AppUpdatePlugin::class.java)
        // 앱 자동 최신: Bridge가 첫 페이지를 열기 전에 이번 실행의 폴더를 정함(저장하지 않음). 어떤 오류든 넣어 둔 화면
        AppUpdate.assets = assets
        if (BuildConfig.DEBUG) {
            intent?.getStringExtra("cduOrigin")?.let { AppUpdate.origin = it }
            intent?.getStringExtra("cduPub")?.let { AppUpdate.pubKey = it }
        }
        val dir = try { AppUpdate.pickFolderAtLaunch(this) } catch (e: Throwable) { null }
        if (dir != null) bridgeBuilder.setServerPath(ServerPath(ServerPath.PathType.BASE_PATH, dir))
        super.onCreate(savedInstanceState)
        if (dir != null) AppUpdate.armReadyTimeout { try { bridge?.setServerAssetPath("public") } catch (e: Throwable) {} }
    }
}
