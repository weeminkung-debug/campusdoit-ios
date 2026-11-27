package com.campusdoit.app

import android.content.pm.ApplicationInfo
import android.graphics.Color
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
        if ((applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) {   // AGP 8은 BuildConfig를 기본으로 안 만듦 → 디버그 빌드 여부를 앱 정보로 봄
            intent?.getStringExtra("cduOrigin")?.let { AppUpdate.origin = it }
            intent?.getStringExtra("cduPub")?.let { AppUpdate.pubKey = it }
        }
        val dir = try { AppUpdate.pickFolderAtLaunch(this) } catch (e: Throwable) { null }
        if (dir != null) bridgeBuilder.setServerPath(ServerPath(ServerPath.PathType.BASE_PATH, dir))
        super.onCreate(savedInstanceState)
        // Capacitor 8 · targetSdk 36(5번방 #129): Android 15+는 화면이 상태·탐색 막대 뒤까지 그려짐. SystemBars(css)가 막대 높이만큼 안쪽 여백을 줌 → 그 여백 자리를 흰색으로(라이트 전용)
        window.decorView.setBackgroundColor(Color.WHITE)
        if (dir != null) AppUpdate.armReadyTimeout { try { bridge?.setServerAssetPath("public") } catch (e: Throwable) {} }
    }
}
