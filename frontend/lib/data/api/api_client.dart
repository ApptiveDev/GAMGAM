import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 서버 응답이 성공이 아닐 때. [code]는 서버 ApiResponse의 에러 코드다.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.code, this.message);

  final int statusCode;
  final String? code;
  final String? message;

  @override
  String toString() => 'ApiException($statusCode, $code, $message)';
}

/// 로그인한 사용자. 서버 user id는 앱 목업의 참여자 id와 다르다.
class ApiUser {
  const ApiUser({required this.id, required this.name});

  final String id;
  final String name;
}

/// Spring Boot API를 부르는 공용 클라이언트.
///
/// 로그인 화면에서 [login]·[signup]으로 토큰을 받는다. 토큰은 메모리에만 들고 있어서 앱을 다시 켜면 다시 로그인한다.
/// 개발할 때 `--dart-define=DEV_AUTO_LOGIN=true`로 켜면 예전처럼 개발용 계정으로 자동 로그인한다.
/// 로컬 서버는 H2 메모리 DB라 켤 때마다 비어 있으므로, 자동 로그인이 안 되면 먼저 가입한다.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? _defaultBaseUrl;

  final http.Client _client;
  final String baseUrl;

  /// 개발용 자동 로그인. 끄면 로그인하지 않은 요청은 서버에 보내지 않고 401로 끝낸다.
  static const devAutoLogin = bool.fromEnvironment('DEV_AUTO_LOGIN');

  static const devEmail = 'yeeun@gamgam.dev';
  static const devPassword = 'gamgam-dev-1234';
  static const devName = '예은';

  String? _token;
  ApiUser? _user;
  Future<void>? _login;

  /// 로그인하거나 로그아웃되거나 토큰이 만료됐을 때 불린다. [AuthController]가 화면에 알린다.
  VoidCallback? onSessionChanged;

  /// 로그인한 사용자. 로그인 전이거나 실패했으면 null.
  ApiUser? get user => _user;

  static String get _defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    return Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
  }

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body);
  Future<dynamic> put(String path, [Object? body]) => _send('PUT', path, body);

  Future<ApiUser> login(String email, String password) async {
    final data = await _request('POST', '/api/v1/auth/login', {'email': email, 'password': password});
    final json = data as Map<String, dynamic>;
    _setSession(json['accessToken'] as String, _userFrom(json['user'] as Map<String, dynamic>));
    return _user!;
  }

  /// 가입만 한다. 토큰은 [login]으로 받는다.
  Future<void> signup({required String email, required String password, required String name}) =>
      _request('POST', '/api/v1/auth/signup', {'email': email, 'password': password, 'name': name});

  Future<ApiUser> me() async => _userFrom(await _send('GET', '/api/v1/auth/me') as Map<String, dynamic>);

  /// 서버 토큰은 상태가 없어서 서버 응답과 상관없이 내 쪽 토큰을 버린다.
  Future<void> logout() async {
    try {
      if (_token != null) await _request('POST', '/api/v1/auth/logout');
    } catch (_) {
      // 서버가 꺼져 있어도 로그아웃은 된다.
    }
    _setSession(null, null);
  }

  /// 동시에 여러 번 불려도 로그인은 한 번만 한다. 실패하면 다음 요청에서 다시 시도한다.
  Future<void> ensureLoggedIn() {
    if (_token != null) return Future.value();
    if (!devAutoLogin) return Future.error(const ApiException(401, 'AUTHENTICATION_REQUIRED', '로그인이 필요해요.'));
    return _login ??= _loginAsDevUser().whenComplete(() => _login = null);
  }

  Future<void> _loginAsDevUser() async {
    try {
      await login(devEmail, devPassword);
    } on ApiException catch (e) {
      if (e.statusCode >= 500) rethrow;
      await signup(email: devEmail, password: devPassword, name: devName);
      await login(devEmail, devPassword);
    }
  }

  void _setSession(String? token, ApiUser? user) {
    _token = token;
    _user = user;
    onSessionChanged?.call();
  }

  static ApiUser _userFrom(Map<String, dynamic> json) => ApiUser(id: json['id'] as String, name: json['name'] as String);

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    await ensureLoggedIn();
    try {
      return await _request(method, path, body);
    } on ApiException catch (e) {
      if (e.statusCode != 401) rethrow;
      // 토큰이 만료됐다. 자동 로그인이면 한 번만 다시 로그인하고, 아니면 로그인 화면으로 돌아간다.
      _setSession(null, null);
      if (!devAutoLogin) rethrow;
      await ensureLoggedIn();
      return _request(method, path, body);
    }
  }

  Future<dynamic> _request(String method, String path, [Object? body]) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final response = await http.Response.fromStream(await _client.send(request));
    final json = response.body.isEmpty ? null : jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = json is Map<String, dynamic> ? json : const <String, dynamic>{};
      throw ApiException(response.statusCode, error['code'] as String?, error['message'] as String?);
    }
    return json is Map<String, dynamic> ? json['data'] : null;
  }
}
