/* 캠퍼스두잇 sw.js — 네트워크 우선 · 즉시 교체
   버전은 아래 VERSION 상수가 유일한 기준(주석에 버전 기재 금지 — 불일치 방지).
   배포 때마다 VERSION을 UI 빌드번호에 맞춰 올리면 됨. */
const VERSION = "b592b";
const CACHE = "doit-" + VERSION;

/* 설치 즉시 대기 없이 활성화 */
const PRECACHE = ["appdata.json", "offline.html"];   /* 애플심사 09.11: 오프라인 폴백 셸 */   /* W 09.03: 평면 배포 */   /* [b581 ⓐ] 분할 데이터 프리캐시 (오프라인·TWA 첫 로드) */
self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(PRECACHE)).catch(() => {}));
  self.skipWaiting();
});

/* 활성화 시: 옛 캐시 전부 삭제 + 열려있는 탭 즉시 인수 */
self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

/* 네트워크 우선: 항상 서버 최신을 먼저, 실패(오프라인) 시에만 캐시 */
self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;                          // API POST 등은 손대지 않음
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;           // turnstile 등 외부는 통과

  e.respondWith(
    fetch(req)
      .then((res) => {
        if (res && res.ok) {
          const copy = res.clone();
          caches.open(CACHE).then((c) => c.put(req, copy)).catch(() => {});
        }
        return res;
      })
      .catch(() => {
        /* 애플심사 09.11 · W 09.16: 문서(내비게이션) 요청 실패 시 구버전 캐시 HTML 대신 항상 오프라인 폴백 셸 */
        if (req.mode === "navigate" || (req.headers.get("accept") || "").includes("text/html")) {
          return caches.match("offline.html").then((o) => o || Response.error());
        }
        return caches.match(req).then((hit) => hit || Response.error());
      })
  );
});
