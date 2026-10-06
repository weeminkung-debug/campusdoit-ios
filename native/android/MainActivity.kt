package com.campusdoit.app

import android.os.Bundle
import com.getcapacitor.BridgeActivity

class MainActivity : BridgeActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        registerPlugin(NativeTabsPlugin::class.java)
        registerPlugin(CampusAdsPlugin::class.java)
        super.onCreate(savedInstanceState)
    }
}
