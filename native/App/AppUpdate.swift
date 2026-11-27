import Foundation
import CryptoKit
import Capacitor

/// 앱 자동 최신(5번방 #97, 방법 C · 11-24 구조): Capacitor에 "다음에 켤 폴더"를 저장하지 않는다.
/// 매번 넣어 둔 화면(public)을 기준으로, 웹뷰가 첫 페이지를 열기 전에 이 코드가 검증된 폴더로 갈아탄다.
/// 갈아타기 전 "시도 중"(trying)을 적고, 화면의 준비됨 신호(ready)에 지운다. 지워지지 않은 채 다시 켜지면 그 ver는 막는다.
/// 어떤 오류든 넣어 둔 화면으로 연다.
final class AppUpdate {
    static let shared = AppUpdate()

    // 고정 값 — 받는 곳은 이 주소 한 곳뿐
    static let origin = "https://campusdoit.com"
    static let manifestPath = "/app/manifest.json"
    // 목록 서명 공개 열쇠(P-256, SPKI DER base64). 비밀 열쇠는 배포 자동화의 비밀값에만 있음
    static let publicKeyB64 = "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEm0NlYlpIUzs2eaDI5UgHoON7qqm0A3+Mbak+hdTa7AyQ/k7uMQlFES4HTo/8hNsE5XGWvtQ+YtpmGxpa+uFILA=="
    static let readyTimeout: TimeInterval = 10      // 갈아탄 화면이 이 안에 준비됨을 못 보내면 넣어 둔 화면으로

    private let fm = FileManager.default
    private let lock = NSLock()
    private(set) var activeVer: String? = nil        // 이번 실행에 갈아탄 ver(nil = 넣어 둔 화면)
    private var originStr: String = AppUpdate.origin
    private var manifestURL: String { originStr + AppUpdate.manifestPath }
    private var pubKeyB64: String = AppUpdate.publicKeyB64
    weak var bridge: CAPBridgeProtocol?

    // 폴더: iOS 제약상 Library/NoCloud/ionic_built_snapshots 아래여야 함(시험 1)
    var root: URL {
        let lib = fm.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        return lib.appendingPathComponent("NoCloud/ionic_built_snapshots", isDirectory: true)
    }
    private var stateURL: URL { root.appendingPathComponent("cdu_state.json") }
    var currentBuild: Int { Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0") ?? 0 }

    struct State: Codable {
        var build: Int
        var ready: String?          // 검증 끝난 최신 ver (다음 실행 후보)
        var trying: String?         // 갈아타는 중(준비됨 신호 전)
        var blocked: [String]
        var off: Bool               // 서버 끄기 스위치를 받음 → 넣어 둔 화면
    }

    // MARK: 시작 — 웹뷰가 첫 페이지를 열기 전(capacitorDidLoad)에 부름. 반환 = 갈아탈 폴더 경로 또는 nil
    func pickFolderAtLaunch() -> String? {
        #if DEBUG
        applyTestArgs()
        #endif
        do {
            // Capacitor가 혹시 저장해 둔 폴더 값은 늘 지움(저장하는 길을 쓰지 않음)
            UserDefaults.standard.removeObject(forKey: "serverBasePath")
            try fm.createDirectory(at: root, withIntermediateDirectories: true)
            var st = loadState()
            // 7) 빌드 번호가 바뀌면 받아 둔 폴더·막은 목록·세기 전부 삭제
            if st.build != currentBuild {
                for n in (try? fm.contentsOfDirectory(atPath: root.path)) ?? [] { try? fm.removeItem(at: root.appendingPathComponent(n)) }
                st = State(build: currentBuild, ready: nil, trying: nil, blocked: [], off: false)
                saveState(st)
            }
            // 6) 받다 꺼진 임시 폴더 삭제
            for n in (try? fm.contentsOfDirectory(atPath: root.path)) ?? [] where n.hasPrefix("tmp_") {
                try? fm.removeItem(at: root.appendingPathComponent(n))
            }
            // 4) 지난번에 갈아탄 뒤 준비됨을 못 받았으면 그 ver를 막고 넣어 둔 화면으로
            if let t = st.trying {
                if !st.blocked.contains(t) { st.blocked.append(t) }
                if st.ready == t { st.ready = nil }
                st.trying = nil
                saveState(st)
                cleanup(keep: [])
                return nil
            }
            // 5번방 #112: 시작 때 기다리지 않음 — 지난번에 받아 검증해 둔 것만 씀, 새 것은 뒤에서 받아 다음 실행 때 적용
            guard !st.off, let v = st.ready, !st.blocked.contains(v), let dir = verifiedDir(v) else { cleanup(keep: []); return nil }
            // 1)~3) 폴더 있음 + index.html 있음 + 검증 끝 표시 있음일 때만, "시도 중"을 먼저 적고 갈아탐
            st.trying = v
            guard saveState(st) else { return nil }
            activeVer = v
            cleanup(keep: [v])
            return dir.path
        } catch {
            return nil
        }
    }

    /// 폴더가 쓸 수 있는 상태인지: 폴더 + index.html + 검증 끝 표시(ver 일치)
    func verifiedDir(_ v: String) -> URL? {
        guard isSafeName(v) else { return nil }
        let d = root.appendingPathComponent(v, isDirectory: true)
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: d.path, isDirectory: &isDir), isDir.boolValue,
              fm.fileExists(atPath: d.appendingPathComponent("index.html").path),
              let ok = try? String(contentsOf: d.appendingPathComponent("cdu_ok"), encoding: .utf8),
              ok.trimmingCharacters(in: .whitespacesAndNewlines) == v else { return nil }
        return d
    }

    // MARK: 화면의 준비됨 신호
    func markReady() {
        lock.lock(); defer { lock.unlock() }
        var st = loadState()
        if st.trying != nil { st.trying = nil; saveState(st) }
        readyReceived = true
    }
    private var readyReceived = false

    /// 갈아탄 뒤 일정 시간 안에 준비됨이 없으면 지금 바로 넣어 둔 화면으로 되돌림(다음 실행에서도 막힘)
    func armReadyTimeout(_ onFallback: @escaping () -> Void) {
        guard activeVer != nil else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + AppUpdate.readyTimeout) { [weak self] in
            guard let self = self, !self.readyReceived, let v = self.activeVer else { return }
            var st = self.loadState()
            if !st.blocked.contains(v) { st.blocked.append(v) }
            if st.ready == v { st.ready = nil }
            st.trying = nil
            self.saveState(st)
            self.activeVer = nil
            onFallback()
        }
    }

    // MARK: 목록 받기 → 서명 확인 → 파일 받기 → sha256 → 검증 끝 표시 → ready 갱신
    @discardableResult
    func checkAndDownload(timeout: TimeInterval) -> Bool {
        let sem = DispatchSemaphore(value: 0)
        var done = false
        DispatchQueue.global(qos: .userInitiated).async {
            done = self.runUpdate()
            sem.signal()
        }
        return sem.wait(timeout: .now() + timeout) == .success && done
    }

    func runUpdateInBackground() {
        DispatchQueue.global(qos: .utility).async { _ = self.runUpdate() }
    }

    private var running = false
    private func runUpdate() -> Bool {
        lock.lock(); if running { lock.unlock(); return false }; running = true; lock.unlock()
        defer { lock.lock(); running = false; lock.unlock() }
        do {
            guard let url = URL(string: manifestURL) else { return false }
            let env = try fetch(url, timeout: 4)
            guard let o = try JSONSerialization.jsonObject(with: env) as? [String: Any],
                  let b64 = o["body"] as? String, let sigB64 = o["sig"] as? String,
                  let body = Data(base64Encoded: b64), let sig = Data(base64Encoded: sigB64),
                  verify(body: body, sig: sig),
                  let m = try JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let ver = m["ver"] as? String else { return false }
            var st = loadState()
            // 서버 끄기 스위치: ver == "off" → 다음 실행부터 넣어 둔 화면
            if ver == "off" { st.off = true; st.ready = nil; saveState(st); return true }
            if st.off { st.off = false; saveState(st) }
            guard isSafeName(ver), !st.blocked.contains(ver) else { return false }
            if let ms = m["min_shell"] as? Int, ms > currentBuild { return false }
            if st.ready == ver, verifiedDir(ver) != nil { return true }
            guard let files = m["files"] as? [[String: Any]], !files.isEmpty else { return false }
            let tmp = root.appendingPathComponent("tmp_" + ver, isDirectory: true)
            try? fm.removeItem(at: tmp)
            try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
            let have = st.ready.flatMap { verifiedDir($0) }
            let bundled = Bundle.main.url(forResource: "public", withExtension: nil)
            var hasIndex = false
            for f in files {
                guard let p = f["p"] as? String, let h = f["h"] as? String, isSafePath(p) else { throw E.bad }
                let dest = tmp.appendingPathComponent(p)
                try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
                if p == "index.html" { hasIndex = true }
                // 같은 내용이 이미 있으면(받아 둔 폴더·넣어 둔 화면) 복사
                var got: Data? = nil
                for base in [have, bundled].compactMap({ $0 }) {
                    if let d = try? Data(contentsOf: base.appendingPathComponent(p)), sha256(d) == h { got = d; break }
                }
                if got == nil {
                    guard let u = f["u"] as? String, u.hasPrefix("/"), !u.hasPrefix("//"),
                          let fu = URL(string: originStr + (u.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? u)) else { throw E.bad }
                    let d = try fetch(fu, timeout: 20)
                    guard sha256(d) == h else { throw E.bad }
                    got = d
                }
                try got!.write(to: dest, options: .atomic)
            }
            guard hasIndex else { throw E.bad }
            try ver.write(to: tmp.appendingPathComponent("cdu_ok"), atomically: true, encoding: .utf8)
            let final = root.appendingPathComponent(ver, isDirectory: true)
            if fm.fileExists(atPath: final.path) {
                // 가리키는 폴더(지금 쓰는 ver)는 지우지 않음
                if activeVer == ver { try? fm.removeItem(at: tmp); return true }
                try fm.removeItem(at: final)
            }
            try fm.moveItem(at: tmp, to: final)
            st = loadState()
            st.ready = ver
            saveState(st)
            return true
        } catch {
            return false
        }
    }

    enum E: Error { case bad }

    private func fetch(_ url: URL, timeout: TimeInterval) throws -> Data {
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        req.httpShouldHandleCookies = false      // 계정·기기 식별값을 보내지 않음
        let sem = DispatchSemaphore(value: 0)
        var out: Data? = nil
        let task = URLSession.shared.dataTask(with: req) { d, r, _ in
            if let h = r as? HTTPURLResponse, h.statusCode == 200 { out = d }
            sem.signal()
        }
        task.resume()
        if sem.wait(timeout: .now() + timeout + 1) == .timedOut { task.cancel(); throw E.bad }
        guard let d = out else { throw E.bad }
        return d
    }

    private func verify(body: Data, sig: Data) -> Bool {
        guard let kd = Data(base64Encoded: pubKeyB64),
              let key = try? P256.Signing.PublicKey(derRepresentation: kd),
              let s = try? P256.Signing.ECDSASignature(derRepresentation: sig) else { return false }
        return key.isValidSignature(s, for: body)
    }

    private func sha256(_ d: Data) -> String { SHA256.hash(data: d).map { String(format: "%02x", $0) }.joined() }

    private func isSafeName(_ s: String) -> Bool {
        !s.isEmpty && s.count <= 64 && s.range(of: "^[A-Za-z0-9_-]+$", options: .regularExpression) != nil && !s.hasPrefix("tmp_")
    }
    private func isSafePath(_ p: String) -> Bool {
        !p.isEmpty && p.count <= 200 && !p.hasPrefix("/") && !p.contains("..") && !p.contains("\\")
            && p.range(of: "^[A-Za-z0-9_./-]+$", options: .regularExpression) != nil && p != "cdu_ok"
    }

    /// 지울 때: 가리키는 폴더·다음 후보는 남기고 나머지만
    private func cleanup(keep: [String]) {
        let st = loadState()
        var k = Set(keep); if let r = st.ready { k.insert(r) }; if let a = activeVer { k.insert(a) }
        for n in (try? fm.contentsOfDirectory(atPath: root.path)) ?? [] {
            if n == "cdu_state.json" || n.hasPrefix("tmp_") || k.contains(n) { continue }
            try? fm.removeItem(at: root.appendingPathComponent(n))
        }
    }

    func loadState() -> State {
        if let d = try? Data(contentsOf: stateURL), let s = try? JSONDecoder().decode(State.self, from: d) { return s }
        return State(build: currentBuild, ready: nil, trying: nil, blocked: [], off: false)
    }
    @discardableResult
    func saveState(_ s: State) -> Bool {
        guard let d = try? JSONEncoder().encode(s) else { return false }
        return (try? d.write(to: stateURL, options: .atomic)) != nil
    }

    #if DEBUG
    // 시험 전용(Debug 빌드만, 스토어·TestFlight 배포 빌드에는 들어가지 않음): 목록 주소·공개 열쇠 바꾸기
    private func applyTestArgs() {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-cduOrigin"), i + 1 < a.count { originStr = a[i + 1] }
        if let i = a.firstIndex(of: "-cduPub"), i + 1 < a.count { pubKeyB64 = a[i + 1] }
    }
    #endif
}
