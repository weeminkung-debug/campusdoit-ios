{"roots_installed":0,"app_cohort":"2|date=1789608600000&sf=143466&tid=068303e3102c5df552fe4e4fe88755706557e0d878d94006c5cb713f50c50b76&ttype=e","app_name":"App","app_version":"1.0","timestamp":"2026-09-17 10:33:21.00 +0900","slice_uuid":"0cd78e0a-0365-3d79-ae1a-8b1d17dd881e","adam_id":"6810937027","build_version":"20","platform":2,"bundleID":"com.campusdoit.app","share_with_app_devs":1,"is_first_party":0,"bug_type":"309","os_version":"iPhone OS 26.6.2 (23G90)","incident_id":"58F02E87-6930-480E-8404-EA86DA9E2D51","name":"App","is_beta":1}
{
  "uptime" : 120000,
  "procRole" : "Non UI",
  "version" : 2,
  "userID" : 501,
  "deployVersion" : 210,
  "modelCode" : "iPhone14,5",
  "coalitionID" : 2947,
  "osVersion" : {
    "isEmbedded" : true,
    "train" : "iPhone OS 26.6.2",
    "releaseType" : "User",
    "build" : "23G90"
  },
  "captureTime" : "2026-09-17 10:33:20.2590 +0900",
  "codeSigningMonitor" : 2,
  "incident" : "58F02E87-6930-480E-8404-EA86DA9E2D51",
  "pid" : 40401,
  "translated" : false,
  "cpuType" : "ARM-64",
  "procLaunch" : "2026-09-17 10:33:03.7736 +0900",
  "procStartAbsTime" : 3082590370240,
  "procExitAbsTime" : 3082984598084,
  "procName" : "App",
  "procPath" : "\/private\/var\/containers\/Bundle\/Application\/C8B9101E-0C38-48D2-B298-776CB61C786E\/App.app\/App",
  "bundleInfo" : {"CFBundleShortVersionString":"1.0","CFBundleVersion":"20","CFBundleIdentifier":"com.campusdoit.app","DTAppStoreToolsBuild":"27A261"},
  "storeInfo" : {"itemID":"6810937027","storeCohortMetadata":"2|date=1789608600000&sf=143466&tid=068303e3102c5df552fe4e4fe88755706557e0d878d94006c5cb713f50c50b76&ttype=e","entitledBeta":true,"deviceIdentifierForVendor":"E3E29DAE-9466-4A0C-A5B5-00DACE2DA023","distributorID":"com.apple.TestFlight","softwareVersionExternalIdentifier":"236968967","applicationVariant":"1:iPhone14,5:26","thirdParty":true},
  "parentProc" : "launchd",
  "parentPid" : 1,
  "coalitionName" : "com.campusdoit.app",
  "isBeta" : 1,
  "appleIntelligenceStatus" : {"state":"unavailable","reasons":["deviceNotCapable"]},
  "bootProgressRegister" : "0x20800004",
  "wasUnlockedSinceBoot" : 1,
  "isLocked" : 0,
  "codeSigningID" : "com.campusdoit.app",
  "codeSigningTeamID" : "885CWQ465B",
  "codeSigningFlags" : 570434305,
  "codeSigningValidationCategory" : 2,
  "codeSigningTrustLevel" : 4,
  "codeSigningAuxiliaryInfo" : 9007199254740992,
  "instructionByteStream" : {"beforePC":"4gMTqgMAgNLH1ouU4AMUquEDE6oCAIDSM2QAlKiDWvipXi7wKRlG+Q==","atPC":"KQFA+T8BCOshAQBU\/XtSqfRPUan2V1Cp+F9PqfpnTqn8b02p\/8MEkQ=="},
  "bootSessionUUID" : "164B9CFB-00A7-4661-BA44-F0AC84A62FB5",
  "basebandVersion" : "5.51.03",
  "exception" : {"codes":"0x0000000000000000, 0x0000000000000000","rawCodes":[0,0],"type":"EXC_CRASH","signal":"SIGKILL"},
  "termination" : {"code":2343432205,"flags":6,"namespace":"FRONTBOARD","reasons":["<RBSTerminateContext| domain:10 code:0x8BADF00D explanation:[app<com.campusdoit.app>:40401] Failed to terminate gracefully after 5.0s","ProcessVisibility: Unknown","ProcessState: Running","WatchdogEvent: process-exit","WatchdogVisibility: Background","WatchdogCPUStatistics: (","\"Elapsed total CPU time (seconds): 10.680 (user 9.000, system 1.680), 30% CPU\",","\"Elapsed application CPU time (seconds): 5.998, 17% CPU\"",")","ThermalInfo: (","\"Thermal Level:   0\",","\"Thermal State:   nominal\"",") reportType:CrashLog maxTerminationResistance:Interactive>"]},
  "faultingThread" : 0,
  "threads" : [{"triggered":true,"id":1500467,"threadState":{"x":[{"value":4315371776},{"value":144115196856389633,"symbolLocation":144115188075855873,"symbol":"OBJC_CLASS_$_NSConcreteMapTable"},{"value":8780533760,"symbolLocation":0,"symbol":"OBJC_CLASS_$_NSConcreteMapTable"},{"value":4315375168},{"value":4315375232},{"value":1},{"value":1152921508922377872},{"value":1360},{"value":11909901206092710017},{"value":8780266304,"symbolLocation":0,"symbol":"__stack_chk_guard"},{"value":24576},{"value":6287},{"value":1},{"value":4315277696},{"value":82},{"value":4302503936},{"value":144115196856389633,"symbolLocation":144115188075855873,"symbol":"OBJC_CLASS_$_NSConcreteMapTable"},{"value":2},{"value":0},{"value":6171633008},{"value":4307678544},{"value":4315371776},{"value":4315375104},{"value":0},{"value":4315530896},{"value":0},{"value":2},{"value":1},{"value":3}],"flavor":"ARM_THREAD_STATE64","lr":{"value":7107968340},"cpsr":{"value":1610616832},"fp":{"value":6171632944},"sp":{"value":6171632656},"esr":{"value":2449473607,"description":"(Data Abort) byte write Translation fault"},"pc":{"value":7107968388,"matchesCrashFrame":1},"far":{"value":0}},"queue":"com.apple.main-thread","frames":[{"imageOffset":654724,"symbol":"-[UIView _notifyGeometryObserversWithChangeInfo:]","symbolLocation":352,"imageIndex":8},{"imageOffset":78292,"symbol":"-[UIView(Geometry) setFrame:]","symbolLocation":768,"imageIndex":8},{"imageOffset":7652292,"symbol":"-[WKWebView(WKViewInternalIOS) setFrame:]","symbolLocation":116,"imageIndex":9},{"imageOffset":793064,"symbol":"-[NSObject(NSKeyValueObservingPrivate) _changeValueForKeys:count:maybeOldValuesDict:maybeNewValuesDict:usingBlock:]","symbolLocation":656,"imageIndex":10},{"imageOffset":1190196,"symbol":"-[NSObject(NSKeyValueObservingPrivate) _changeValueForKey:key:key:usingBlock:]","symbolLocation":64,"imageIndex":10},{"imageOffset":3009312,"symbol":"_NSSetRectValueAndNotify","symbolLocation":452,"imageIndex":10},{"imageOffset":22900,"imageIndex":0},{"imageOffset":23068,"imageIndex":0},{"imageOffset":591196,"imageIndex":8},{"imageOffset":592216,"imageIndex":8},{"imageOffset":291704,"symbol":"-[UIView(CALayerDelegate) layoutSublayersOfLayer:]","symbolLocation":3412,"imageIndex":8},{"imageOffset":2873508,"symbol":"CA::Layer::perform_update_(CA::Layer*, CALayer*, unsigned int, CA::LayerUpdateReason, CA::Transaction*)","symbolLocation":460,"imageIndex":11},{"imageOffset":2872308,"symbol":"CA::Layer::update_if_needed_(CA::Transaction*, CA::LayerUpdateReason)","symbolLocation":664,"imageIndex":11},{"imageOffset":718848,"symbol":"CA::Layer::layout_and_display_if_needed(CA::Transaction*)","symbolLocation":180,"imageIndex":11},{"imageOffset":450968,"symbol":"CA::Context::commit_transaction(CA::Transaction*, double, double*)","symbolLocation":560,"imageIndex":11},{"imageOffset":632096,"symbol":"CA::Transaction::commit()","symbolLocation":620,"imageIndex":11},{"imageOffset":2385148,"symbol":"__34-[UIApplication _firstCommitBlock]_block_invoke_2","symbolLocation":36,"imageIndex":8},{"imageOffset":187084,"symbol":"__CFRUNLOOP_IS_CALLING_OUT_TO_A_BLOCK__","symbolLocation":28,"imageIndex":12},{"imageOffset":186264,"symbol":"__CFRunLoopDoBlocks","symbolLocation":396,"imageIndex":12},{"imageOffset":192956,"symbol":"__CFRunLoopRun","symbolLocation":848,"imageIndex":12},{"imageOffset":189772,"symbol":"_CFRunLoopRunSpecificWithOptions","symbolLocation":532,"imageIndex":12},{"imageOffset":5272,"symbol":"GSEventRunModal","symbolLocation":120,"imageIndex":13},{"imageOffset":1185392,"symbol":"-[UIApplication _run]","symbolLocation":796,"imageIndex":8},{"imageOffset":573784,"symbol":"UIApplicationMain","symbolLocation":332,"imageIndex":8},{"imageOffset":17480,"imageIndex":0},{"imageOffset":19484,"symbol":"start","symbolLocation":6928,"imageIndex":14}]},{"id":1500485,"threadState":{"x":[{"value":18446744073709551612},{"value":0},{"value":257},{"value":0},{"value":335007449088},{"value":0},{"value":0},{"value":0},{"value":1},{"value":3},{"value":0},{"value":78},{"value":0},{"value":0},{"value":8780273200,"symbolLocation":48,"symbol":"_dispatch_main_q"},{"value":6173927173},{"value":515},{"value":7701436846560531968},{"value":0},{"value":6172204880},{"value":1},{"value":17409},{"value":6172209376},{"value":6172204832},{"value":6172209376},{"value":4313814464},{"value":0},{"value":549755813888},{"value":8887859696,"symbolLocation":400,"symbol":"_dispatch_continuation_vtables"}],"flavor":"ARM_THREAD_STATE64","lr":{"value":7995360728},"cpsr":{"value":1073745920},"fp":{"value":6172204704},"sp":{"value":6172204672},"esr":{"value":1442840704,"description":"(Syscall)"},"pc":{"value":9953259808},"far":{"value":0}},"queue":"com.apple.UIKit.KeyboardManagement","frames":[{"imageOffset":28960,"symbol":"__ulock_wait","symbolLocation":8,"imageIndex":16},{"imageOffset":13784,"symbol":"_dispatch_thread_main_event_wait_slow","symbolLocation":76,"imageIndex":17},{"imageOffset":71244,"symbol":"__DISPATCH_WAIT_FOR_QUEUE__","symbolLocation":464,"imageIndex":17},{"imageOffset":70008,"symbol":"_dispatch_sync_f_slow","symbolLocation":140,"imageIndex":17},{"imageOffset":21288112,"symbol":"__37-[_UIRemoteKeyboards startConnection]_block_invoke.449","symbolLocation":144,"imageIndex":8},{"imageOffset":407844,"symbol":"__invoking___","symbolLocation":148,"imageIndex":12},{"imageOffset":407464,"symbol":"-[NSInvocation invoke]","symbolLocation":424,"imageIndex":12},{"imageOffset":268116,"symbol":"<deduplicated_symbol>","symbolLocation":16,"imageIndex":10},{"imageOffset":241872,"symbol":"-[NSXPCConnection _decodeAndInvokeReplyBlockWithEvent:sequence:replyInfo:]","symbolLocation":528,"imageIndex":10},{"imageOffset":240172,"symbol":"__88-[NSXPCConnection _sendInvocation:orArguments:count:methodSignature:selector:withProxy:]_block_invoke_5","symbolLocation":188,"imageIndex":10},{"imageOffset":138924,"symbol":"_xpc_connection_reply_callout","symbolLocation":120,"imageIndex":18},{"imageOffset":79300,"symbol":"_xpc_connection_call_reply_async","symbolLocation":96,"imageIndex":18},{"imageOffset":111124,"symbol":"<deduplicated_symbol>","symbolLocation":16,"imageIndex":17},{"imageOffset":127544,"symbol":"_dispatch_mach_msg_async_reply_invoke","symbolLocation":340,"imageIndex":17},{"imageOffset":40472,"symbol":"_dispatch_lane_serial_drain","symbolLocation":332,"imageIndex":17},{"imageOffset":43748,"symbol":"_dispatch_lane_invoke","symbolLocation":448,"imageIndex":17},{"imageOffset":85420,"symbol":"_dispatch_root_queue_drain_deferred_wlh","symbolLocation":284,"imageIndex":17},{"imageOffset":83628,"symbol":"_dispatch_workloop_worker_thread","symbolLocation":720,"imageIndex":17},{"imageOffset":5040,"symbol":"_pthread_wqthread","symbolLocation":292,"imageIndex":19},{"imageOffset":2240,"symbol":"start_wqthread","symbolLocation":8,"imageIndex":19}]},{"id":1500486,"frames":[],"threadState":{"x":[{"value":6172782592},{"value":6403},{"value":6172246016},{"value":0},{"value":409604},{"value":18446744073709551615},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":0},"cpsr":{"value":4096},"fp":{"value":0},"sp":{"value":6172782592},"esr":{"value":1442840704,"description":"(Syscall)"},"pc":{"value":8614553784},"far":{"value":0}}},{"id":1500487,"frames":[],"threadState":{"x":[{"value":6173356032},{"value":6147},{"value":6172819456},{"value":0},{"value":409602},{"value":18446744073709551615},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":0},"cpsr":{"value":4096},"fp":{"value":0},"sp":{"value":6173356032},"esr":{"value":1442840704,"description":"(Syscall)"},"pc":{"value":8614553784},"far":{"value":0}}},{"id":1500488,"frames":[],"threadState":{"x":[{"value":6174502912},{"value":9987},{"value":6173966336},{"value":0},{"value":409604},{"value":18446744073709551615},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":0},"cpsr":{"value":4096},"fp":{"value":0},"sp":{"value":6174502912},"esr":{"value":1442840704,"description":"(Syscall)"},"pc":{"value":8614553784},"far":{"value":0}}},{"id":1500489,"threadState":{"x":[{"value":18446744073709551612},{"value":0},{"value":257},{"value":0},{"value":335007449088},{"value":0},{"value":2},{"value":0},{"value":1},{"value":3},{"value":2},{"value":78},{"value":0},{"value":0},{"value":8780273200,"symbolLocation":48,"symbol":"_dispatch_main_q"},{"value":0},{"value":515},{"value":7701436846560531968},{"value":0},{"value":6173927264},{"value":1},{"value":17409},{"value":6173929696},{"value":6173927216},{"value":4312101504},{"value":7107313664},{"value":0},{"value":4312150072},{"value":9223372036859799490}],"flavor":"ARM_THREAD_STATE64","lr":{"value":7995360728},"cpsr":{"value":1073745920},"fp":{"value":6173927088},"sp":{"value":6173927056},"esr":{"value":1442840704,"description":"(Syscall)"},"pc":{"value":9953259808},"far":{"value":0}},"queue":"com.apple.libtrace.state.block-list","frames":[{"imageOffset":28960,"symbol":"__ulock_wait","symbolLocation":8,"imageIndex":16},{"imageOffset":13784,"symbol":"_dispatch_thread_main_event_wait_slow","symbolLocation":76,"imageIndex":17},{"imageOffset":71244,"symbol":"__DISPATCH_WAIT_FOR_QUEUE__","symbolLocation":464,"imageIndex":17},{"imageOffset":70008,"symbol":"_dispatch_sync_f_slow","symbolLocation":140,"imageIndex":17},{"imageOffset":41400,"symbol":"___os_state_request_for_self_block_invoke","symbolLocation":372,"imageIndex":20},{"imageOffset":6568,"symbol":"_dispatch_call_block_and_release","symbolLocation":32,"imageIndex":17},{"imageOffset":111076,"symbol":"_dispatch_client_callout","symbolLocation":16,"imageIndex":17},{"imageOffset":40880,"symbol":"_dispatch_lane_serial_drain","symbolLocation":740,"imageIndex":17},{"imageOffset":43748,"symbol":"_dispatch_lane_invoke","symbolLocation":448,"imageIndex":17},{"imageOffset":85420,"symbol":"_dispatch_root_queue_drain_deferred_wlh","symbolLocation":284,"imageIndex":17},{"imageOffset":83628,"symbol":"_dispatch_workloop_worker_thread","symbolLocation":720,"imageIndex":17},{"imageOffset":5040,"symbol":"_pthread_wqthread","symbolLocation":292,"imageIndex":19},{"imageOffset":2240,"symbol":"start_wqthread","symbolLocation":8,"imageIndex":19}]},{"id":1500492,"name":"com.apple.uikit.eventfetch-thread","threadState":{"x":[{"value":268451845},{"value":21592279046},{"value":8589934592},{"value":71481140707328},{"value":2162692},{"value":71481140707328},{"value":2},{"value":4294967295},{"value":0},{"value":0},{"value":2},{"value":0},{"value":0},{"value":16643},{"value":4302702952},{"value":4312432640},{"value":18446744073709551569},{"value":18446744072367376383},{"value":0},{"value":4294967295},{"value":2},{"value":71481140707328},{"value":2162692},{"value":71481140707328},{"value":21592279046},{"value":6176218504},{"value":8589934592},{"value":18446744073709550527},{"value":11258331136,"symbolLocation":0,"symbol":"_libkernel_string_functions"}],"flavor":"ARM_THREAD_STATE64","lr":{"value":9953248012},"cpsr":{"value":4096},"fp":{"value":6176218352},"sp":{"value":6176218272},"esr":{"value":1442840704,"description":"(Syscall)"},"pc":{"value":9953234132},"far":{"value":0}},"frames":[{"imageOffset":3284,"symbol":"mach_msg2_trap","symbolLocation":8,"imageIndex":16},{"imageOffset":17164,"symbol":"mach_msg2_internal","symbolLocation":76,"imageIndex":16},{"imageOffset":16940,"symbol":"mach_msg_overwrite","symbolLocation":424,"imageIndex":16},{"imageOffset":16504,"symbol":"mach_msg","symbolLocation":24,"imageIndex":16},{"imageOffset":414580,"symbol":"__CFRunLoopServiceMachPort","symbolLocation":160,"imageIndex":12},{"imageOffset":193296,"symbol":"__CFRunLoopRun","symbolLocation":1188,"imageIndex":12},{"imageOffset":189772,"symbol":"_CFRunLoopRunSpecificWithOptions","symbolLocation":532,"imageIndex":12},{"imageOffset":44272,"symbol":"-[NSRunLoop(NSRunLoop) runMode:beforeDate:]","symbolLocation":212,"imageIndex":10},{"imageOffset":43992,"symbol":"-[NSRunLoop(NSRunLoop) runUntilDate:]","symbolLocation":64,"imageIndex":10},{"imageOffset":945836,"symbol":"-[UIEventFetcher threadMain]","symbolLocation":420,"imageIndex":8},{"imageOffset":583956,"symbol":"__NSThread__start__","symbolLocation":732,"imageIndex":10},{"imageOffset":17464,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":19},{"imageOffset":2252,"symbol":"thread_start","symbolLocation":8,"imageIndex":19}]},{"id":1500493,"name":"JavaScriptCore libpas scavenger","threadState":{"x":[{"value":260},{"value":0},{"value":4608},{"value":0},{"value":0},{"value":160},{"value":0},{"value":4999872},{"value":6176796328},{"value":0},{"value":0},{"value":2},{"value":2},{"value":0},{"value":0},{"value":0},{"value":305},{"value":8806957688},{"value":0},{"value":4355647552},{"value":4355647616},{"value":6176796896},{"value":4999872},{"value":0},{"value":4608},{"value":649729},{"value":649984},{"value":0},{"value":8784232448,"symbolLocation":0,"symbol":"WTF::globalMaxQOSclass"}],"flavor":"ARM_THREAD_STATE64","lr":{"value":8614562632},"cpsr":{"value":1610616832},"fp":{"value":6176796448},"sp":{"value":6176796304},"esr":{"value":1442840704,"description":"(Syscall)"},"pc":{"value":9953256936},"far":{"value":0}},"frames":[{"imageOffset":26088,"symbol":"__psynch_cvwait","symbolLocation":8,"imageIndex":16},{"imageOffset":11080,"symbol":"_pthread_cond_wait","symbolLocation":980,"imageIndex":19},{"imageOffset":29667100,"symbol":"scavenger_thread_main","symbolLocation":1416,"imageIndex":21},{"imageOffset":17464,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":19},{"imageOffset":2252,"symbol":"thread_start","symbolLocation":8,"imageIndex":19}]}],
  "usedImages" : [
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4295229440,
    "size" : 65536,
    "uuid" : "0cd78e0a-0365-3d79-ae1a-8b1d17dd881e",
    "path" : "\/private\/var\/containers\/Bundle\/Application\/C8B9101E-0C38-48D2-B298-776CB61C786E\/App.app\/App",
    "name" : "App"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4300783616,
    "size" : 557056,
    "uuid" : "7a4d8d47-64c9-345e-a8d4-a2296cb784cf",
    "path" : "\/private\/var\/containers\/Bundle\/Application\/C8B9101E-0C38-48D2-B298-776CB61C786E\/App.app\/Frameworks\/Capacitor.framework\/Capacitor",
    "name" : "Capacitor"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4296605696,
    "size" : 49152,
    "uuid" : "972d1f55-b580-3a19-91f9-eea5f175de04",
    "path" : "\/private\/var\/containers\/Bundle\/Application\/C8B9101E-0C38-48D2-B298-776CB61C786E\/App.app\/Frameworks\/CapacitorApp.framework\/CapacitorApp",
    "name" : "CapacitorApp"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4296949760,
    "size" : 49152,
    "uuid" : "8d35475b-e152-310d-a61e-f4fe5f16068b",
    "path" : "\/private\/var\/containers\/Bundle\/Application\/C8B9101E-0C38-48D2-B298-776CB61C786E\/App.app\/Frameworks\/CapacitorBrowser.framework\/CapacitorBrowser",
    "name" : "CapacitorBrowser"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4297424896,
    "size" : 114688,
    "uuid" : "d65ffd62-3755-322e-afc3-122f66aaab73",
    "path" : "\/private\/var\/containers\/Bundle\/Application\/C8B9101E-0C38-48D2-B298-776CB61C786E\/App.app\/Frameworks\/CapacitorLocalNotifications.framework\/CapacitorLocalNotifications",
    "name" : "CapacitorLocalNotifications"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4297719808,
    "size" : 65536,
    "uuid" : "ba2b5803-bc3a-377c-bb84-005412f5d5a9",
    "path" : "\/private\/var\/containers\/Bundle\/Application\/C8B9101E-0C38-48D2-B298-776CB61C786E\/App.app\/Frameworks\/CapacitorSplashScreen.framework\/CapacitorSplashScreen",
    "name" : "CapacitorSplashScreen"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4296769536,
    "size" : 49152,
    "uuid" : "d80657e8-7404-38dd-b27b-65d23d711582",
    "path" : "\/private\/var\/containers\/Bundle\/Application\/C8B9101E-0C38-48D2-B298-776CB61C786E\/App.app\/Frameworks\/Cordova.framework\/Cordova",
    "name" : "Cordova"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 4297129984,
    "size" : 49152,
    "uuid" : "004ce93c-f142-3d68-b3c3-30c6efef4d65",
    "path" : "\/private\/preboot\/Cryptexes\/OS\/usr\/lib\/libobjc-trampolines.dylib",
    "name" : "libobjc-trampolines.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 7107313664,
    "size" : 39073344,
    "uuid" : "0d94422f-fe7c-302e-b896-3bc5873c0cfc",
    "path" : "\/System\/Library\/PrivateFrameworks\/UIKitCore.framework\/UIKitCore",
    "name" : "UIKitCore"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 7466770432,
    "size" : 24644064,
    "uuid" : "c39bd22c-3475-38af-91bd-0b7574081011",
    "path" : "\/System\/Library\/Frameworks\/WebKit.framework\/WebKit",
    "name" : "WebKit"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 6962937856,
    "size" : 15244480,
    "uuid" : "73841aa3-bfdd-322d-8dc2-e5185a14dee1",
    "path" : "\/System\/Library\/Frameworks\/Foundation.framework\/Foundation",
    "name" : "Foundation"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 7020982272,
    "size" : 4132544,
    "uuid" : "8f1e0b3f-add6-3710-a790-009333597ab4",
    "path" : "\/System\/Library\/Frameworks\/QuartzCore.framework\/QuartzCore",
    "name" : "QuartzCore"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 7010578432,
    "size" : 5884480,
    "uuid" : "101eb2f1-1915-34a0-8bc9-631d03753b84",
    "path" : "\/System\/Library\/Frameworks\/CoreFoundation.framework\/CoreFoundation",
    "name" : "CoreFoundation"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 9795485696,
    "size" : 34752,
    "uuid" : "411165e2-ee8e-380e-b254-9977273971e3",
    "path" : "\/System\/Library\/PrivateFrameworks\/GraphicsServices.framework\/GraphicsServices",
    "name" : "GraphicsServices"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 6956273664,
    "size" : 676992,
    "uuid" : "0f8d35b6-556f-3e34-8eaa-80ab54047dc5",
    "path" : "\/usr\/lib\/dyld",
    "name" : "dyld"
  },
  {
    "size" : 0,
    "source" : "A",
    "base" : 0,
    "uuid" : "00000000-0000-0000-0000-000000000000"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 9953230848,
    "size" : 244512,
    "uuid" : "18665b3f-6d51-33ab-b9e9-63062200ec42",
    "path" : "\/usr\/lib\/system\/libsystem_kernel.dylib",
    "name" : "libsystem_kernel.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 7995346944,
    "size" : 288256,
    "uuid" : "49c0cd3e-a696-3b11-ba92-5755f0c3c6e3",
    "path" : "\/usr\/lib\/system\/libdispatch.dylib",
    "name" : "libdispatch.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 7357210624,
    "size" : 333408,
    "uuid" : "72214f26-ea8c-3f8a-bdf7-2f518fe9f87e",
    "path" : "\/usr\/lib\/system\/libxpc.dylib",
    "name" : "libxpc.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 8614551552,
    "size" : 50416,
    "uuid" : "34b44744-bc64-386e-ab90-eee86b23ac46",
    "path" : "\/usr\/lib\/system\/libsystem_pthread.dylib",
    "name" : "libsystem_pthread.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 7648419840,
    "size" : 132032,
    "uuid" : "635d31a0-a5e6-3209-af07-b84c7ff132e6",
    "path" : "\/usr\/lib\/system\/libsystem_trace.dylib",
    "name" : "libsystem_trace.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 7371673600,
    "size" : 32251488,
    "uuid" : "f7906028-1c6d-3b4c-bd93-78c196c83a83",
    "path" : "\/System\/Library\/Frameworks\/JavaScriptCore.framework\/JavaScriptCore",
    "name" : "JavaScriptCore"
  }
],
  "sharedCache" : {
  "base" : 6955106304,
  "size" : 5394350080,
  "uuid" : "ca21ad80-e2af-3cf3-aa57-0db11df436dd"
},
  "vmSummary" : "ReadOnly portion of Libraries: Total=1.7G resident=0K(0%) swapped_out_or_unallocated=1.7G(100%)\nWritable regions: Total=1.5G written=994K(0%) resident=962K(0%) swapped_out=32K(0%) unallocated=1.5G(100%)\n\n                                VIRTUAL   REGION \nREGION TYPE                        SIZE    COUNT (non-coalesced) \n===========                     =======  ======= \nActivity Tracing                   256K        1 \nCG raster data                     160K        5 \nCoreAnimation                       64K        4 \nFoundation                          16K        1 \nJS VM Gigacage (reserved)        512.0M        1         reserved VM address space (unallocated)\nKernel Alloc Once                   32K        1 \nMALLOC                            88.8M       28 \nMALLOC guard page                 3984K        4 \nSTACK GUARD                        128K        8 \nStack                             4816K        8 \nVM_ALLOCATE                        352K       14 \nWebKit Malloc                    904.5M       29 \n__AUTH                            8295K      708 \n__AUTH_CONST                     104.5M     1120 \n__CTF                               824        1 \n__DATA                            44.0M     1072 \n__DATA_CONST                      35.9M     1133 \n__DATA_DIRTY                      9786K      992 \n__FONT_DATA                        2352        1 \n__LINKEDIT                       180.5M        9 \n__OBJC_RO                         85.0M        1 \n__OBJC_RW                         3209K        1 \n__TEXT                             1.5G     1148 \n__TPRO_CONST                       128K        2 \nmapped file                      366.6M       20 \npage table in kernel               962K        1 \nshared memory                       80K        4 \n===========                     =======  ======= \nTOTAL                              3.8G     6317 \nTOTAL, minus reserved VM space     3.3G     6317 \n",
  "legacyInfo" : {
  "threadTriggered" : {
    "queue" : "com.apple.main-thread"
  }
},
  "logWritingSignature" : "d4d012d8f73f0104fe951e159ba3e43df62e714a",
  "bug_type" : "309",
  "roots_installed" : 0,
  "trmStatus" : 1,
  "sandboxProfileName" : "container",
  "voucherInfos" : [{"proximateName":"SpringBoard","thread_id":1500485},{"proximateName":"SpringBoard","thread_id":1500489}],
  "trialInfo" : {
  "rollouts" : [
    {
      "rolloutId" : "68095e8ecb2a9d1eaa8463c9",
      "factorPackIds" : [
        "68bf4eac9c31c5367e5529ca"
      ],
      "deploymentId" : 240000008
    },
    {
      "rolloutId" : "682ef9612c2ae30e2f38d3a4",
      "factorPackIds" : [

      ],
      "deploymentId" : 240000006
    }
  ],
  "experiments" : [
    {
      "treatmentId" : "b94e9aec-71bd-46f0-b53b-72fe0d8e9aa4",
      "experimentId" : "67e32776f470dc0e83d9e147",
      "deploymentId" : 400000014
    },
    {
      "treatmentId" : "d5c127b8-b13e-42a1-acf5-c483124a1bb5",
      "experimentId" : "66b1602abe27b2208fd291ba",
      "deploymentId" : 400000022
    }
  ]
}
}
