/// 앱의 모든 경로. 화면에서 문자열 경로를 직접 쓰지 말고 여기 것을 쓴다.
///
/// 웹에서도 같은 주소로 열리므로 초대 링크(/invite/:code)가 그대로 딥링크가 된다.
abstract final class AppRoutes {
  // 하단 탭
  static const home = '/';
  static const records = '/records';
  static const profile = '/profile';

  // 핵심기능 #1 — 약속 생성
  static const create = '/appointments/new';
  static const createDetails = '/appointments/new/details';

  // 핵심기능 #1 — 방 (약속 하나 = 방 하나)
  static String room(String id) => '/appointments/$id';
  static String penalty(String id) => '/appointments/$id/penalty';
  static String confirmed(String id) => '/appointments/$id/confirmed';

  // 핵심기능 #2 — 당일 위치 공유 (자리만 잡아둠)
  static String locationSetting(String id) => '/appointments/$id/location-setting';
  static String liveMap(String id) => '/appointments/$id/live';
  static String arrival(String id) => '/appointments/$id/arrival';

  // 초대 링크로 입장
  static String invite(String code) => '/invite/$code';
}
