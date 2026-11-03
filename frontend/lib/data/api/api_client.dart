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
/// 로그인 화면이 생기기 전까지는 개발용 계정으로 자동 로그인한다.
/// 로컬 서버는 H2 메모리 DB라 켤 때마다 비어 있으므로, 로그인이 안 되면 먼저 가입한다.
/// 토큰은 메모리에만 들고 있다.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl}) : _client = client ?? http.Client(), baseUrl = baseUrl ?? _defaultBaseUrl;

  final http.Client _client;
  final String baseUrl;

  static const devEmail = 'yeeun@gamgam.dev';
  static const devPassword = 'gamgam-dev-1234';
  static const devName = '예은';

  String? _token;
  ApiUser? _user;
  Future<void>? _login;

  /// 자동 로그인이 끝난 뒤의 사용자. 로그인 전이거나 실패했으면 null.
  ApiUser? get user => _user;

  static String get _defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    return Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
  }

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body);
  Future<dynamic> put(String path, [Object? body]) => _send('PUT', path, body);

  /// 동시에 여러 번 불려도 로그인은 한 번만 한다. 실패하면 다음 요청에서 다시 시도한다.
  Future<void> ensureLoggedIn() {
    if (_token != null) return Future.value();
    return _login ??= _loginAsDevUser().whenComplete(() => _login = null);
  }

  Future<void> _loginAsDevUser() async {
    final credentials = {'email': devEmail, 'password': devPassword};
    dynamic data;
    try {
      data = await _request('POST', '/api/v1/auth/login', credentials);
    } on ApiException catch (e) {
      if (e.statusCode >= 500) rethrow;
      await _request('POST', '/api/v1/auth/signup', {...credentials, 'name': devName});
      data = await _request('POST', '/api/v1/auth/login', credentials);
    }
    final json = data as Map<String, dynamic>;
    final user = json['user'] as Map<String, dynamic>;
    _token = json['accessToken'] as String;
    _user = ApiUser(id: user['id'] as String, name: user['name'] as String);
  }

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    await ensureLoggedIn();
    try {
      return await _request(method, path, body);
    } on ApiException catch (e) {
      // 토큰이 만료됐으면 한 번만 다시 로그인한다.
      if (e.statusCode != 401) rethrow;
      _token = null;
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
