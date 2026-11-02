import 'package:flutter/foundation.dart';

import '../models/appointment.dart';
import '../models/decision_template.dart';
import '../models/group.dart';
import '../models/participant.dart';
import '../models/place.dart';

/// 화면은 이 인터페이스만 안다.
/// 서버에 있는 기능은 [ApiAppointmentRepository]가, 아직 없는 기능은 [MockAppointmentRepository]가 맡는다.
///
/// 읽기는 캐시된 값을 동기로, 쓰기는 서버 호출을 가정해 Future로 둔다.
abstract class AppointmentRepository extends ChangeNotifier {
  /// 로그인한 사용자.
  Participant get me;

  /// 내가 들어가 있는 그룹(폴더), 만든 순서대로.
  List<Group> get myGroups;

  Group? findGroup(String id);

  /// 그룹 안의 내 약속.
  List<Appointment> appointmentsIn(String groupId);

  /// 내가 참여 중인 약속 (최신 상태).
  List<Appointment> get myAppointments;

  Appointment? findById(String id);
  Appointment? findByInviteCode(String code);

  /// 초대 링크 (카카오톡 공유, 복사용).
  String inviteLink(Appointment appointment);

  Future<Group> createGroup(String name);

  /// 이름만 정해서 그룹 안에 약속을 만든다. 시간·장소는 약속 상세에서 투표로 정한다.
  Future<Appointment> createAppointment({required String groupId, required String name});

  /// 템플릿·후보를 한 번에 넣어 만드는 기존 방식. 서버 POST /api/v1/appointments 와 같은 모양이다.
  Future<Appointment> create({
    required String name,
    required DecisionTemplate template,
    required List<DateTime> times,
    required List<Place> places,
  });

  Future<void> rename(String appointmentId, String name);

  Future<void> join(String appointmentId);

  /// 투표하기. 시간은 여러 개, 장소는 한 곳만 고른다.
  Future<void> voteTimes(String appointmentId, Set<String> optionIds);
  Future<void> votePlace(String appointmentId, String optionId);

  /// 다시 투표하기 — 내 표만 지운다.
  Future<void> clearMyTimeVotes(String appointmentId);
  Future<void> clearMyPlaceVotes(String appointmentId);

  Future<void> addTimeOption(String appointmentId, DateTime time);
  Future<void> addPlaceOption(String appointmentId, Place place);

  /// 투표 종료하기 — 1위 후보로 그 항목을 확정한다. 시간·장소가 모두 정해지면 약속이 확정된다.
  Future<void> closeTimeVote(String appointmentId);
  Future<void> closePlaceVote(String appointmentId);

  Future<void> setPenalty(String appointmentId, {required String penalty, required int lateThresholdMinutes});

  /// 1위 후보로 확정. 방장만 할 수 있다.
  Future<void> confirm(String appointmentId);

  /// 09 "정산 완료" — 모두 도착한 약속을 지난 약속으로 넘긴다.
  Future<void> complete(String appointmentId, {required int lateCount});
}
