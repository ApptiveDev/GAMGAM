import 'api_client.dart';

/// 약속·투표 요청이 실패했을 때 보여 줄 문구. [code]는 서버 ErrorCode다.
String apiErrorMessage(Object error) {
  if (error is! ApiException) return '서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요';
  return switch (error.code) {
    'NOT_COORDINATING' => '이미 확정된 약속이에요',
    'DUPLICATE_CANDIDATE' => '이미 올라온 후보예요',
    'INVALID_OPTION' || 'INVALID_VOTE_OPTION' => '후보가 바뀌었어요. 다시 골라 주세요',
    'VOTE_NOT_ALLOWED' => '이 약속은 그 항목을 투표로 정하지 않아요',
    'INVALID_INVITE_CODE' => '초대 코드를 찾을 수 없어요',
    'APPOINTMENT_ACCESS_DENIED' => '이 약속에 참여한 사람만 볼 수 있어요',
    'APPOINTMENT_NOT_FOUND' => '약속을 찾을 수 없어요',
    _ when error.statusCode == 400 => '입력한 내용을 한 번 더 확인해 주세요',
    _ => '잠시 문제가 생겼어요. 조금 뒤에 다시 시도해 주세요',
  };
}
