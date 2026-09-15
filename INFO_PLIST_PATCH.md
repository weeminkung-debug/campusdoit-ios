# Info.plist 수출규정 키 (면제 선언)
경로: ios/App/App/Info.plist — </dict> 바로 앞에 아래 2줄 추가

	<key>ITSAppUsesNonExemptEncryption</key>
	<false/>

※ cap add ios로 ios/가 새로 생성되면 사라지므로, 워크플로에서 자동 주입(아래 스텝이 ios.yml에 포함됨)
