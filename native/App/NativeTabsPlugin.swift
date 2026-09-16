import Foundation
import Capacitor

@objc(NativeTabsPlugin)
public class NativeTabsPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "NativeTabsPlugin"
    public let jsName = "NativeTabs"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "setActive", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isAvailable", returnType: CAPPluginReturnPromise)
    ]
    @objc func setActive(_ call: CAPPluginCall) {
        let key = call.getString("key") ?? "home"
        NativeTabsViewController.shared?.setActive(key)
        call.resolve()
    }
    @objc func isAvailable(_ call: CAPPluginCall) {
        call.resolve(["available": NativeTabsViewController.shared != nil])
    }
}
