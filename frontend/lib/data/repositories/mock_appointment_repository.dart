import 'dart:math';

import '../../core/config/invite_link.dart';
import '../mock/mock_data.dart';
import '../models/appointment.dart';
import '../models/decision_template.dart';
import '../models/participant.dart';
import '../models/place.dart';
import '../models/vote_option.dart';
import 'appointment_repository.dart';

/// 메모리에만 저장하는 목업. 앱을 껐다 켜면 초기화된다.
class MockAppointmentRepository extends AppointmentRepository {
  MockAppointmentRepository({DateTime? now}) : _items = {for (final a in MockData.appointments(now ?? DateTime.now())) a.id: a};

  final Map<String, Appointment> _items;

  /// 약속 id → 이 브라우저의 게스트. 목업이라 새로고침하면 사라진다.
  // TODO: 백엔드 게스트 토큰이 나오면 브라우저 저장소에 보관한다.
  final Map<String, Participant> _guests = {};
  final _random = Random();

  static const _latency = Duration(milliseconds: 250);

  @override
  Participant get me => MockData.me;

  @override
  List<Appointment> get myAppointments => _items.values.where((a) => a.hasMember(me.id)).toList();

  @override
  Appointment? findById(String id) => _items[id];

  @override
  Appointment? findByInviteCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final a in _items.values) {
      // 서버 약속은 소문자 UUID를 초대 코드로 쓰므로 대소문자를 무시하고 비교한다.
      if (a.inviteCode.toUpperCase() == normalized) return a;
    }
    return null;
  }

  @override
  String inviteLink(Appointment appointment) => InviteLink.of(appointment.inviteCode);

  @override
  Future<Appointment> create({
    required String name,
    required DecisionTemplate template,
    required List<DateTime> times,
    required List<Place> places,
    DateTime? voteDeadline,
  }) async {
    await Future.delayed(_latency);
    final id = 'a-${DateTime.now().microsecondsSinceEpoch}';
    final appointment = Appointment(
      id: id,
      name: name,
      template: template,
      hostId: me.id,
      inviteCode: _newInviteCode(),
      // 목업 연출: 링크를 받은 친구들이 이미 들어와 있다고 가정.
      participants: [me, ...MockData.friends],
      timeOptions: [for (final (i, t) in times.indexed) TimeOption(id: 't$i', value: t)],
      placeOptions: [for (final (i, p) in places.indexed) PlaceOption(id: 'p$i', value: p)],
      voteDeadline: template.hasVote ? voteDeadline : null,
    );
    _items[id] = appointment;
    notifyListeners();
    return appointment;
  }

  @override
  Future<void> join(String appointmentId) async {
    await Future.delayed(_latency);
    _update(appointmentId, (a) => a.hasMember(me.id) ? a : a.copyWith(participants: [...a.participants, me]));
  }

  @override
  Participant? guestOf(String appointmentId) => _guests[appointmentId];

  @override
  Future<Participant> joinAsGuest(String appointmentId, String name) async {
    await Future.delayed(_latency);
    final existing = _guests[appointmentId];
    if (existing != null) return existing;
    final a = _items[appointmentId];
    if (a == null) throw StateError('약속을 찾을 수 없어요.');
    final guest = Participant(id: 'g-${DateTime.now().microsecondsSinceEpoch}', name: a.uniqueName(name.trim()), hasApp: false);
    _guests[appointmentId] = guest;
    _update(appointmentId, (a) => a.copyWith(participants: [...a.participants, guest]));
    return guest;
  }

  @override
  Future<void> toggleTimeVote(String appointmentId, String optionId, {String? voterId}) async {
    final uid = voterId ?? me.id;
    _updateVote(appointmentId, (a) => a.copyWith(
          timeOptions: [
            for (final o in a.timeOptions)
              o.id == optionId ? o.copyWith(voterIds: o.votedBy(uid) ? (List.of(o.voterIds)..remove(uid)) : [...o.voterIds, uid]) : o,
          ],
        ));
  }

  @override
  Future<void> votePlace(String appointmentId, String optionId, {String? voterId}) async {
    final uid = voterId ?? me.id;
    _updateVote(appointmentId, (a) => a.copyWith(
          placeOptions: [
            for (final o in a.placeOptions)
              o.copyWith(voterIds: [
                ...o.voterIds.where((id) => id != uid),
                if (o.id == optionId) uid,
              ]),
          ],
        ));
  }

  @override
  Future<void> addTimeOption(String appointmentId, DateTime time) async {
    _update(appointmentId, (a) => a.copyWith(
          timeOptions: [...a.timeOptions, TimeOption(id: 't${a.timeOptions.length}-${time.millisecondsSinceEpoch}', value: time, voterIds: [me.id])],
        ));
  }

  @override
  Future<void> setPenalty(String appointmentId, {required String penalty, required int lateThresholdMinutes}) async {
    await Future.delayed(_latency);
    _update(appointmentId, (a) => a.copyWith(
          penalty: penalty,
          lateThresholdMinutes: lateThresholdMinutes,
          // 벌칙을 바꾸면 동의를 처음부터 다시 받는다. 정한 사람은 동의한 것으로 본다.
          penaltyAgreedIds: [me.id],
        ));
  }

  @override
  Future<void> confirm(String appointmentId) async {
    await Future.delayed(_latency);
    _update(appointmentId, (a) => a.copyWith(status: AppointmentStatus.confirmed, confirmedTime: a.time, confirmedPlace: a.place));
  }

  @override
  Future<void> complete(String appointmentId, {required int lateCount}) async {
    await Future.delayed(_latency);
    _update(appointmentId, (a) => a.copyWith(status: AppointmentStatus.completed, lateCount: lateCount));
  }

  /// 서버에서 받은 약속을 기존 목업 상태에 합친다. API가 아직 없는 화면 기능은
  /// 이 저장소의 목업 동작을 계속 사용한다.
  void mergeServerAppointments(Iterable<Appointment> appointments) {
    for (final appointment in appointments) {
      _items[appointment.id] = appointment;
    }
    notifyListeners();
  }

  /// 마감이 지난 투표는 서버에서도 거절된다고 가정한다.
  void _updateVote(String id, Appointment Function(Appointment) change) {
    final current = _items[id];
    if (current == null || current.isVoteClosed(DateTime.now())) return;
    _update(id, change);
  }

  void _update(String id, Appointment Function(Appointment) change) {
    final current = _items[id];
    if (current == null) return;
    _items[id] = change(current);
    notifyListeners();
  }

  String _newInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }
}
