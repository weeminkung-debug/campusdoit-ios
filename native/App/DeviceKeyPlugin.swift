import Foundation
import Capacitor
import Security
import CommonCrypto

// 기기 열쇠(iOS) — 코디 광고 권한용 서명 열쇠(ECDSA P-256).
// WKWebView는 꺼낼 수 없는 Web Crypto 열쇠를 IndexedDB에 보관하지 못함(DataCloneError — 시뮬레이터 확인 2026-11-20)
// → 열쇠를 Keychain에 두고(되면 Secure Enclave), 화면에는 공개 열쇠와 서명만 내줌. 개인 열쇠를 내주는 메서드는 없음.
// 형식은 Web Crypto와 같게: 공개 열쇠 = X9.63 raw 65바이트, 서명 = r||s 64바이트, 둘 다 base64url. 식별값 = 공개 열쇠 SHA-256.
@objc(DeviceKeyPlugin)
public class DeviceKeyPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "DeviceKeyPlugin"
    public let jsName = "DeviceKey"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "publicKey", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "sign", returnType: CAPPluginReturnPromise)
    ]
    private let tag = "com.campusdoit.app.devicekey.v1".data(using: .utf8)!

    private func b64u(_ d: Data) -> String {
        return d.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
    private func sha256(_ d: Data) -> Data {
        var h = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        d.withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(d.count), &h) }
        return Data(h)
    }
    private func load() -> SecKey? {
        let q: [String: Any] = [kSecClass as String: kSecClassKey,
                                kSecAttrApplicationTag as String: tag,
                                kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                                kSecReturnRef as String: true]
        var item: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess, let it = item else { return nil }
        return (it as! SecKey)
    }
    private func make() -> (SecKey?, Bool, String) {
        var err: Unmanaged<CFError>?
        if let ac = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, .privateKeyUsage, nil) {
            let attrs: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                                        kSecAttrKeySizeInBits as String: 256,
                                        kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
                                        kSecPrivateKeyAttrs as String: [kSecAttrIsPermanent as String: true,
                                                                        kSecAttrApplicationTag as String: tag,
                                                                        kSecAttrAccessControl as String: ac] as [String: Any]]
            if let k = SecKeyCreateRandomKey(attrs as CFDictionary, &err) { return (k, true, "") }
        }
        err = nil   // Secure Enclave를 못 쓰면(시뮬레이터 등) Keychain 소프트웨어 열쇠
        let attrs: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                                    kSecAttrKeySizeInBits as String: 256,
                                    kSecPrivateKeyAttrs as String: [kSecAttrIsPermanent as String: true,
                                                                    kSecAttrApplicationTag as String: tag,
                                                                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly] as [String: Any]]
        if let k = SecKeyCreateRandomKey(attrs as CFDictionary, &err) { return (k, false, "") }
        let msg = err.map { String(describing: $0.takeRetainedValue()) } ?? "unknown"
        return (nil, false, msg)
    }
    private func key() -> (SecKey?, Bool, String) {
        if let k = load() { return (k, false, "") }
        let (k, _, e) = make()
        return (k, k != nil, e)
    }
    // DER(30 len 02 rl r 02 sl s) → r||s 각 32바이트
    private func rawSig(_ der: Data) -> Data? {
        let b = [UInt8](der); var i = 0
        guard b.count > 8, b[i] == 0x30 else { return nil }
        i += 1; if b[i] & 0x80 != 0 { i += Int(b[i] & 0x7f) }; i += 1
        var out = Data()
        for _ in 0..<2 {
            guard i + 1 < b.count, b[i] == 0x02 else { return nil }
            let n = Int(b[i + 1]); i += 2
            guard i + n <= b.count else { return nil }
            var v = Array(b[i..<(i + n)]); i += n
            while v.count > 32, v.first == 0 { v.removeFirst() }
            guard v.count <= 32 else { return nil }
            out.append(contentsOf: [UInt8](repeating: 0, count: 32 - v.count) + v)
        }
        return out
    }

    @objc func publicKey(_ call: CAPPluginCall) {
        let (k, made, e) = key()
        guard let priv = k, let pub = SecKeyCopyPublicKey(priv) else { call.reject("no key: \(e)"); return }
        var err: Unmanaged<CFError>?
        guard let raw = SecKeyCopyExternalRepresentation(pub, &err) as Data? else { call.reject("no public key"); return }
        let attrs = SecKeyCopyAttributes(priv) as? [String: Any]
        let se = (attrs?[kSecAttrTokenID as String] as? String) == (kSecAttrTokenIDSecureEnclave as String)
        call.resolve(["pub": b64u(raw), "id": b64u(sha256(raw)), "made": made, "secureEnclave": se])
    }
    @objc func sign(_ call: CAPPluginCall) {
        guard let msg = call.getString("msg"), let data = msg.data(using: .utf8), msg.hasPrefix("coach|") else { call.reject("bad msg"); return }
        let (k, _, e) = key()
        guard let priv = k else { call.reject("no key: \(e)"); return }
        var err: Unmanaged<CFError>?
        guard let der = SecKeyCreateSignature(priv, .ecdsaSignatureMessageX962SHA256, data as CFData, &err) as Data?, let raw = rawSig(der) else { call.reject("sign failed"); return }
        call.resolve(["sig": b64u(raw)])
    }
}
