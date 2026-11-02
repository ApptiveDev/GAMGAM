/// 앱의 모든 경로. 화면에서 문자열 경로를 직접 쓰지 말고 여기 것을 쓴다.
///
/// 웹에서도 같은 주소로 열리므로 초대 링크(/invite/:code)가 그대로 딥링크가 된다.
abstract final class AppRoutes {
  // 하단 탭
  static const home = '/';
  static const groups = '/groups';
  static const profile = '/profile';

  // 그룹(폴더) — 약속은 그룹 안에서 만든다.
  static const createGroup = '/groups/new';
  static String group(String id) => '/groups/$id';
  static String groupSearch(String id) => '/groups/$id/search';
  static String createAppointment(String groupId) => '/groups/$groupId/new';

  // 약속 상세 (예전 "방"). 지도·도착 화면이 이 경로로 돌아오므로 주소를 바꾸지 않는다.
  static String room(String id) => '/appointments/$id';
  static String rename(String id) => '/appointments/$id/rename';
  static String pickPlace(String id) => '/appointments/$id/places';
  static String penalty(String id) => '/appointments/$id/penalty';
  static String confirmed(String id) => '/appointments/$id/confirmed';

  // 핵심기능 #2 — 당일 위치 공유
  // 당일 지도는 보통 openLiveMap()으로 연다. 공개 범위를 아직 안 골랐으면 06을 먼저 거친다.
  static String locationSetting(String id, {bool thenLiveMap = false}) =>
      '/appointments/$id/location-setting${thenLiveMap ? '?next=live' : ''}';
  static String liveMap(String id) => '/appointments/$id/live';
  static String arrival(String id) => '/appointments/$id/arrival';

  // 초대 링크로 입장
  static String invite(String code) => '/invite/$code';
}
