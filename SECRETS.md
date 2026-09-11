# GitHub Secrets 명세 (Settings → Secrets and variables → Actions → New repository secret)
| Name | 값 | 출처 |
|---|---|---|
| ASC_KEY_ID | (10자리 Key ID) | App Store Connect → Users and Access → Integrations → App Store Connect API → 키 생성(Admin 또는 App Manager) |
| ASC_ISSUER_ID | (UUID) | 같은 화면 상단 Issuer ID |
| ASC_KEY_P8_B64 | `base64 -i AuthKey_XXXX.p8` 결과 1줄 | 키 생성 시 1회만 다운로드되는 .p8 파일 |
| IOS_CERT_P12_B64 | `base64 -i dist.p12` 결과 1줄 | Apple Developer → Certificates → Apple Distribution 인증서 생성 후 내보낸 .p12 |
| IOS_CERT_PASSWORD | .p12 내보내기 비밀번호 | 내보낼 때 W가 정한 값 |
※ 프로비저닝 프로필은 fastlane sigh가 API 키로 자동 발급 — 수동 등록 불요
※ Mac 없이 .p12 만들기: 5번방 안내 단계 ④에서 Windows용 OpenSSL 절차 별도 발행
