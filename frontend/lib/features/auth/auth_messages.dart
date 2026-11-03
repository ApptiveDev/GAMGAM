import '../../data/api/api_client.dart';

/// 입력 검증. 서버 규칙(SignupRequest)과 같게 맞춘다: 이메일 형식, 비밀번호 8~64자, 이름 2~30자.
abstract final class AuthRules {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String value) {
    final v = value.trim();
    if (v.isEmpty) return '이메일을 입력해 주세요';
    if (v.length > 255 || !_email.hasMatch(v)) return '이메일 형식을 한 번 더 확인해 주세요';
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return '비밀번호를 입력해 주세요';
    if (value.length < 8) return '비밀번호는 8자 이상으로 정해 주세요';
    if (value.length > 64) return '비밀번호는 64자까지 쓸 수 있어요';
    return null;
  }

  static String? name(String value) {
    final v = value.trim();
    if (v.length < 2) return '이름은 2자 이상으로 정해 주세요';
    if (v.length > 30) return '이름은 30자까지 쓸 수 있어요';
    return null;
  }
}

/// 서버 에러를 화면 문구로 바꾼다.
String authErrorMessage(Object error) {
  if (error is! ApiException) return '서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요';
  return switch (error.statusCode) {
    401 => '이메일이나 비밀번호를 다시 확인해 주세요',
    409 => '이미 가입된 이메일이에요. 로그인해 볼까요?',
    400 => '입력한 내용을 한 번 더 확인해 주세요',
    _ => '잠시 문제가 생겼어요. 조금 뒤에 다시 시도해 주세요',
  };
}
