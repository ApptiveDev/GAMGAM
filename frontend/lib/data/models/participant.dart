class Participant {
  const Participant({required this.id, required this.name, this.hasApp = true});

  final String id;
  final String name;

  /// 웹 링크로만 들어와서 아직 앱이 없는 참여자. 05 확정 화면의 설치 현황에 쓴다.
  final bool hasApp;

  /// 아바타 원 안에 들어가는 한 글자.
  String get initial => name.isEmpty ? '?' : String.fromCharCode(name.runes.first);
}
