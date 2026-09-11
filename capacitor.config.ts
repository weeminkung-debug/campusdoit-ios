import type { CapacitorConfig } from '@capacitor/cli';
const config: CapacitorConfig = {
  appId: 'com.campusdoit.app',
  appName: '캠퍼스두잇',
  webDir: 'www',                       // 정본 HTML·i18n·appdata·sw·정적 3종·cat/ 아이콘 = 배포 zip 그대로
  server: { androidScheme: 'https', iosScheme: 'https' },
  ios: { contentInset: 'automatic', scheme: 'CampusDoIt', limitsNavigationsToAppBoundDomains: false },
  plugins: { LocalNotifications: { smallIcon: 'ic_stat_campusdoit', iconColor: '#2B5BC4' } }
};
export default config;
