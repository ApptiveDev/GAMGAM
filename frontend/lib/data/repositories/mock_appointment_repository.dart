import 'dart:math';

import '../mock/mock_data.dart';
import '../models/appointment.dart';
import '../models/decision_template.dart';
import '../models/group.dart';
import '../models/participant.dart';
import '../models/place.dart';
import '../models/vote_option.dart';
import 'appointment_repository.dart';

/// 메모리에만 저장하는 목업. 앱을 껐다 켜면 초기화된다.
class MockAppointmentRepository extends AppointmentRepository {
  MockAppointmentRepository({DateTime? now})
      : _groups = {for (final g in MockData.groups(now ?? DateTime.now())) g.id: g},
        _items = {for (final a in MockData.appointments(now ?? DateTime.now())) a.id: a};

  final Map<String, Group> _groups;
  final Map<String, Appointment> _items;
  final _random = Random();

  static const _latency = Duration(milliseconds: 250);
  static const _linkBase = 'https://gamgam.app/invite';

  @override
  Participant get me => MockData.me;

  @override
  List<Group> get myGroups => _groups.values.where((g) => g.members.any((m) => m.id == me.id)).toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Group? findGroup(String id) => _groups[id];

  @override
  List<Appointment> appointmentsIn(String groupId) => myAppointments.where((a) => a.groupId == groupId).toList();

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
  Future<Group> createGroup(String name) async {
    await Future.delayed(_latency);
    final group = Group(id: 'g-${DateTime.now().microsecondsSinceEpoch}', name: name, members: [me], createdAt: DateTime.now());
    _groups[group.id] = group;
    notifyListeners();
    return group;
  }

  @override
  Future<Appointment> createAppointment({required String groupId, required String name}) async {
    await Future.delayed(_latency);
    final group = _groups[groupId];
    final images = MockData.appointmentImages;
    final appointment = Appointment(
      id: 'a-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      groupId: groupId,
      imageAsset: images[_items.length % images.length],
      createdAt: DateTime.now(),
      template: DecisionTemplate.voteBoth,
      hostId: me.id,
      inviteCode: _newInviteCode(),
      // 그룹 멤버가 모두 들어와 있는 것으로 본다.
      participants: group?.members ?? [me],
    );
    _items[appointment.id] = appointment;
    notifyListeners();
    return appointment;
  }

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
      createdAt: DateTime.now(),
    );
    _items[id] = appointment;
    notifyListeners();
    return appointment;
  }

  @override
  Future<void> rename(String appointmentId, String name) async {
    await Future.delayed(_latency);
    _update(appointmentId, (a) => a.copyWith(name: name));
  }

  @override
  Future<void> join(String appointmentId) async {
    await Future.delayed(_latency);
    _update(appointmentId, (a) => a.hasMember(me.id) ? a : a.copyWith(participants: [...a.participants, me]));
  }

  @override
  Future<void> voteTimes(String appointmentId, Set<String> optionIds) async {
    _update(appointmentId, (a) => a.copyWith(timeOptions: [
          for (final o in a.timeOptions)
            o.copyWith(voterIds: [...o.voterIds.where((id) => id != me.id), if (optionIds.contains(o.id)) me.id]),
        ]));
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
  Future<void> clearMyTimeVotes(String appointmentId) => voteTimes(appointmentId, const {});

  @override
  Future<void> clearMyPlaceVotes(String appointmentId) async {
    _update(appointmentId, (a) => a.copyWith(placeOptions: [
          for (final o in a.placeOptions) o.copyWith(voterIds: o.voterIds.where((id) => id != me.id).toList()),
        ]));
  }

  @override
  Future<void> addTimeOption(String appointmentId, DateTime time) async {
    _update(appointmentId, (a) => a.copyWith(
          timeOptions: [...a.timeOptions, TimeOption(id: 't${a.timeOptions.length}-${time.millisecondsSinceEpoch}', value: time)],
        ));
  }

  @override
  Future<void> addPlaceOption(String appointmentId, Place place) async {
    _update(appointmentId, (a) => a.placeOptions.any((o) => o.value.name == place.name)
        ? a
        : a.copyWith(placeOptions: [...a.placeOptions, PlaceOption(id: 'p${a.placeOptions.length}-${place.name.hashCode}', value: place)]));
  }

  @override
  Future<void> closeTimeVote(String appointmentId) async {
    await Future.delayed(_latency);
    _update(appointmentId, (a) => _settle(a.copyWith(confirmedTime: a.time)));
  }

  @override
  Future<void> closePlaceVote(String appointmentId) async {
    await Future.delayed(_latency);
    _update(appointmentId, (a) => _settle(a.copyWith(confirmedPlace: a.place)));
  }

  /// 시간·장소가 모두 정해졌으면 약속을 확정한다.
  Appointment _settle(Appointment a) =>
      a.confirmedTime != null && a.confirmedPlace != null ? a.copyWith(status: AppointmentStatus.confirmed) : a;

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

  /// 서버에서 받은 약속을 기존 목업 상태에 합친다.
  /// 서버가 아직 모르는 값(그룹, 썸네일, 참여자, 투표 현황)은 앱에 있던 값을 그대로 둔다.
  void mergeServerAppointments(Iterable<Appointment> appointments) {
    for (final server in appointments) {
      final local = _items[server.id];
      _items[server.id] = local == null
          ? server.copyWith(groupId: myGroups.firstOrNull?.id, imageAsset: MockData.appointmentImages.first)
          : Appointment(
              id: server.id,
              name: server.name,
              template: server.template,
              hostId: local.hostId,
              inviteCode: local.inviteCode,
              participants: local.participants,
              status: server.status,
              timeOptions: local.timeOptions.isEmpty ? server.timeOptions : local.timeOptions,
              placeOptions: local.placeOptions.isEmpty ? server.placeOptions : local.placeOptions,
              confirmedTime: server.confirmedTime ?? local.confirmedTime,
              confirmedPlace: server.confirmedPlace ?? local.confirmedPlace,
              penalty: local.penalty,
              lateThresholdMinutes: local.lateThresholdMinutes,
              penaltyAgreedIds: local.penaltyAgreedIds,
              lateCount: local.lateCount,
              groupId: local.groupId,
              imageAsset: local.imageAsset,
              createdAt: local.createdAt,
            );
    }
    notifyListeners();
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
