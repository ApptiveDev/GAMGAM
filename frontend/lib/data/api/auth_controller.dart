import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// 로그인 상태. 라우터는 [isLoggedIn]이 바뀌면 로그인 화면과 홈 사이를 옮긴다.
///
/// 토큰과 사용자는 [ApiClient]가 들고 있고, 여기서는 바뀌었다는 것만 화면에 알린다.
class AuthController extends ChangeNotifier {
  AuthController(ApiClient this.client) : _offline = false {
    client!.onSessionChanged = notifyListeners;
    // 개발용 자동 로그인이면 화면을 막지 않고 뒤에서 미리 로그인해 둔다.
    if (ApiClient.devAutoLogin) client!.ensureLoggedIn().catchError((_) {});
  }

  /// 서버 없이 목업으로만 도는 앱(테스트 등). 늘 로그인한 것으로 본다.
  AuthController.offline()
      : client = null,
        _offline = true;

  final ApiClient? client;
  final bool _offline;

  ApiUser? get user => client?.user;

  bool get isLoggedIn => _offline || ApiClient.devAutoLogin || user != null;

  Future<void> login(String email, String password) async {
    await client!.login(email, password);
  }

  /// 가입한 정보로 바로 로그인한다.
  Future<void> signup({required String email, required String password, required String name}) async {
    await client!.signup(email: email, password: password, name: name);
    await client!.login(email, password);
  }

  Future<void> logout() async => client?.logout();

  @override
  void dispose() {
    if (client?.onSessionChanged == notifyListeners) client!.onSessionChanged = null;
    super.dispose();
  }
}
