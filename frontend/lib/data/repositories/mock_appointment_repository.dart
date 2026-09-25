import 'dart:math';

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
  final _random = Random();

  static const _latency = Duration(milliseconds: 250);
  static const _linkBase = 'https://gamgam.app/invite';

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
      if (a.inviteCode == normalized) return a;
    }
    return null;
  }

  @override
  String inviteLink(Appointment appointment) => '$_linkBase/${appointment.inviteCode}';

  @override
  Future<Appointment> create({
    required String name,
    required DecisionTemplate template,
    required List<DateTime> times,
    required List<Place> places,
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
  Future<void> toggleTimeVote(String appointmentId, String optionId) async {
    _update(appointmentId, (a) => a.copyWith(
          timeOptions: [
            for (final o in a.timeOptions)
              o.id == optionId ? o.copyWith(voterIds: o.votedBy(me.id) ? (List.of(o.voterIds)..remove(me.id)) : [...o.voterIds, me.id]) : o,
          ],
        ));
  }

  @override
  Future<void> votePlace(String appointmentId, String optionId) async {
    _update(appointmentId, (a) => a.copyWith(
          placeOptions: [
            for (final o in a.placeOptions)
              o.copyWith(voterIds: [
                ...o.voterIds.where((id) => id != me.id),
                if (o.id == optionId) me.id,
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
