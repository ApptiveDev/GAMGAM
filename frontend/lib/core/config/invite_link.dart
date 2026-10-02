import 'package:flutter/foundation.dart';

/// 초대 링크 앞부분. 실제 도메인은 백엔드와 정한 뒤 `--dart-define=INVITE_BASE_URL=https://...` 로 넣는다.
/// 지정이 없으면 웹은 지금 열린 주소, 앱은 로컬 웹 개발 서버(localhost:5000)를 쓴다.
/// 라우터가 해시(#) 주소를 쓰므로 `/#`까지가 앞부분이다.
abstract final class InviteLink {
  static const _configured = String.fromEnvironment('INVITE_BASE_URL');
  static const _localWeb = 'http://localhost:5000/#';

  static String get base {
    if (_configured.isNotEmpty) return _configured;
    return kIsWeb ? '${Uri.base.origin}/#' : _localWeb;
  }

  static String of(String inviteCode) => '$base/invite/$inviteCode';
}
