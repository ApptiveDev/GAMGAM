import 'package:flutter/foundation.dart';

import '../models/appointment.dart';
import '../models/decision_template.dart';
import '../models/participant.dart';
import '../models/place.dart';

/// 화면은 이 인터페이스만 안다.
/// 지금은 [MockAppointmentRepository]를 쓰고, 백엔드 API가 나오면 구현체만 바꿔 끼운다.
///
/// 읽기는 캐시된 값을 동기로, 쓰기는 서버 호출을 가정해 Future로 둔다.
abstract class AppointmentRepository extends ChangeNotifier {
  /// 로그인한 사용자.
  Participant get me;

  /// 내가 참여 중인 약속 (최신 상태).
  List<Appointment> get myAppointments;

  Appointment? findById(String id);
  Appointment? findByInviteCode(String code);

  /// 초대 링크 (카카오톡 공유, 복사용).
  String inviteLink(Appointment appointment);

  Future<Appointment> create({
    required String name,
    required DecisionTemplate template,
    required List<DateTime> times,
    required List<Place> places,
  });

  Future<void> join(String appointmentId);

  /// 시간은 중복 투표 → 토글.
  Future<void> toggleTimeVote(String appointmentId, String optionId);

  /// 장소는 한 곳만 투표.
  Future<void> votePlace(String appointmentId, String optionId);

  Future<void> addTimeOption(String appointmentId, DateTime time);

  Future<void> setPenalty(String appointmentId, {required String penalty, required int lateThresholdMinutes});

  /// 1위 후보로 확정. 방장만 할 수 있다.
  Future<void> confirm(String appointmentId);
}
