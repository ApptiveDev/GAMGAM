import 'dart:async';
import 'dart:math';

import '../mock/mock_data.dart';
import '../models/appointment.dart';
import '../models/geo_point.dart';
import '../models/live_location.dart';
import '../models/participant.dart';
import 'live_location_repository.dart';

/// 와이어프레임 07~09 장면을 재현하는 시뮬레이션. 메모리에만 저장한다.
///
/// 시간은 빠르게 흘러간다: [tick]마다 [_minutesPerTick]분. (기본 0.5초 = 30초 → 1초 = 1분)
/// 약속 42분 전에서 시작해 약 1분이면 모두 도착한다. 콕 찌르기 쿨다운만은 실제 시간으로 센다.
class MockLiveLocationRepository extends LiveLocationRepository {
  MockLiveLocationRepository({String? meId, this.tick = const Duration(seconds: 2)}) : _meId = meId ?? MockData.me.id;

  final String _meId;
  final Duration tick;

  static const _minutesPerTick = 0.5;
  static const _startBefore = Duration(minutes: 42);
  static const _replyDelay = Duration(seconds: 2);

  final _levels = <String, ShareLevel>{};
  final _sims = <String, _Sim>{};
  final _cooldowns = <String, DateTime>{};
  final _events = <String, StreamController<LiveEvent>>{};

  /// API 구현체는 현재 사용자의 좌표를 기기 GPS로 대체할 수 있다.
  bool usesDeviceLocationFor(String appointmentId) => false;

  @override
  ShareLevel? shareLevelOf(String appointmentId) => _levels[appointmentId];

  @override
  Future<void> setShareLevel(String appointmentId, ShareLevel level) async {
    _levels[appointmentId] = level;
    final sim = _sims[appointmentId];
    if (sim != null) sim.session = _replace(sim.session, _meId, (p) => p.copyWith(shareLevel: level));
    notifyListeners();
  }

  @override
  LiveSession? session(String appointmentId) => _sims[appointmentId]?.session;

  @override
  void start(Appointment appointment) {
    final sim = _sims.putIfAbsent(appointment.id, () => _createSim(appointment));
    if (sim.finished || sim.timer != null) return;
    sim.timer = Timer.periodic(tick, (_) => _advance(sim));
  }

  @override
  void stop(String appointmentId) {
    final sim = _sims[appointmentId];
    sim?.timer?.cancel();
    sim?.timer = null;
  }

  void applyServerPositions(String appointmentId, Map<String, GeoPoint> positions) {
    final sim = _sims[appointmentId];
    if (sim == null) return;
    sim.session = sim.session.copyWith(participants: [
      for (final participant in sim.session.participants)
        positions.containsKey(participant.id)
            ? participant.copyWith(position: positions[participant.id], departed: true, shareLevel: ShareLevel.close)
            : participant,
    ]);
    notifyListeners();
  }

  void setTransport(String appointmentId, String participantId, Transport transport) {
    final sim = _sims[appointmentId];
    if (sim == null) return;
    sim.session = sim.session.copyWith(participants: [for (final participant in sim.session.participants) participant.id == participantId ? participant.copyWith(transport: transport) : participant]);
    notifyListeners();
  }

  void setMeasuredLocation(String appointmentId, String participantId, GeoPoint position, Transport transport, int etaMinutes) {
    final sim = _sims[appointmentId];
    if (sim == null) return;
    sim.session = sim.session.copyWith(participants: [for (final participant in sim.session.participants) participant.id == participantId ? participant.copyWith(position: position, transport: transport, departed: true, etaMinutes: etaMinutes) : participant]);
    notifyListeners();
  }

  @override
  Stream<LiveEvent> events(String appointmentId) => _controller(appointmentId).stream;

  @override
  Duration pokeCooldownOf(String appointmentId, String targetId) {
    final until = _cooldowns['$appointmentId/$targetId'];
    if (until == null) return Duration.zero;
    final left = until.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  Future<void> poke(String appointmentId, String targetId, PokeMessage message) async {
    final sim = _sims[appointmentId];
    // 도착한 사람과 쿨다운 중인 사람에게는 보내지 않는다.
    if (sim == null || (sim.session.byId(targetId)?.arrived ?? true) || pokeCooldownOf(appointmentId, targetId) > Duration.zero) return;
    _cooldowns['$appointmentId/$targetId'] = DateTime.now().add(pokeCooldown);
    _countPoke(sim, targetId);
    notifyListeners();

    // 목업 연출: 상대가 알림에서 바로 답장한다.
    await Future.delayed(_replyDelay);
    final target = sim.session.byId(targetId);
    if (target == null || target.arrived) return;
    final PokeReply reply;
    if (!target.departed) {
      reply = PokeReply.leavingNow;
      sim.runners[targetId]!.departAfter = sim.elapsed;
    } else {
      reply = (target.etaMinutes ?? 99) <= 5 ? PokeReply.fiveMinutes : PokeReply.tenMinutes;
    }
    _controller(appointmentId).add(PokeReplied(target.participant, reply));
  }

  @override
  Future<void> reply(String appointmentId, Poke poke, PokeReply reply) async {
    final sim = _sims[appointmentId];
    final me = sim?.runners[_meId];
    if (reply == PokeReply.leavingNow && me != null && me.departAfter != null) me.departAfter = sim!.elapsed;
  }

  @override
  void dispose() {
    for (final sim in _sims.values) {
      sim.timer?.cancel();
    }
    for (final c in _events.values) {
      c.close();
    }
    super.dispose();
  }

  StreamController<LiveEvent> _controller(String appointmentId) => _events.putIfAbsent(appointmentId, () => StreamController<LiveEvent>.broadcast());

  _Sim _createSim(Appointment a) {
    final destination = a.place?.location ?? GeoPoint.hongikUniv;
    final appointmentTime = a.time ?? DateTime.now().add(_startBefore);
    final start = appointmentTime.subtract(_startBefore);

    final others = a.participants.where((p) => p.id != _meId).toList();
    final roles = <String, _Role>{
      for (final p in a.participants) p.id: p.id == _meId ? _Role.me : _Role.friends[min(others.indexOf(p), _Role.friends.length - 1)],
    };

    final runners = <String, _Runner>{};
    final participants = <LiveParticipant>[];
    for (final p in a.participants) {
      final role = roles[p.id]!;
      final runner = _Runner(role, destination);
      runners[p.id] = runner;
      participants.add(LiveParticipant(
        participant: p,
        shareLevel: p.id == _meId ? (_levels[a.id] ?? ShareLevel.recommended) : role.shareLevel,
        transport: role.transport,
        departed: role.departAfter == null,
        position: runner.home,
        etaMinutes: role.travelMinutes,
        arrivedAt: role.arrivedBefore == null ? null : start.subtract(Duration(minutes: role.arrivedBefore!)),
      ));
      if (role.initialCooldown != null) _cooldowns['${a.id}/${p.id}'] = DateTime.now().add(role.initialCooldown!);
    }

    // 약속 당일 이미 오간 콕 찌르기 (09 "오늘 콕 찌르기 N번"용).
    final pokeCounts = <String, int>{if (others.isNotEmpty) others.first.id: 3, _meId: 1};

    return _Sim(
      incomingFrom: others.isEmpty ? null : others.first,
      runners: runners,
      session: LiveSession(
        appointmentId: a.id,
        destination: destination,
        appointmentTime: appointmentTime,
        now: start,
        participants: participants,
        pokeCounts: pokeCounts,
      ),
    );
  }

  void _advance(_Sim sim) {
    sim.elapsed += _minutesPerTick;
    final now = sim.session.appointmentTime.subtract(_startBefore).add(Duration(seconds: (sim.elapsed * 60).round()));
    final events = <LiveEvent>[];

    final participants = [
      for (final p in sim.session.participants)
        if (p.arrived || (usesDeviceLocationFor(sim.session.appointmentId) && p.id == _meId)) p else _move(p, sim.runners[p.id]!, sim.elapsed, now, sim.session.destination, events),
    ];
    sim.session = sim.session.copyWith(now: now, participants: participants);

    // 목업 연출: 지도를 연 지 조금 지나면 친구가 나를 콕 찌른다.
    final from = sim.incomingFrom;
    final me = sim.session.byId(_meId);
    if (!sim.pokedMe && from != null && me != null && !me.arrived && sim.elapsed >= 2) {
      sim.pokedMe = true;
      _countPoke(sim, _meId);
      events.add(PokeReceived(Poke(from: from, to: me.participant, message: PokeMessage.hurry)));
    }

    if (sim.session.allArrived) {
      sim.finished = true;
      stop(sim.session.appointmentId);
      events.add(const AllArrived());
    }
    notifyListeners();
    final controller = _controller(sim.session.appointmentId);
    events.forEach(controller.add);
  }

  LiveParticipant _move(LiveParticipant p, _Runner r, double elapsed, DateTime now, GeoPoint destination, List<LiveEvent> events) {
    if (!p.departed) {
      if (r.departAfter == null || elapsed < r.departAfter!) return p;
      // 친구가 집을 나서면 방에 출발 알림. 위치 공유를 끈 사람은 알리지 않는다.
      if (p.id != _meId && p.shareLevel != ShareLevel.off) events.add(FriendDeparted(p.participant));
      return p.copyWith(departed: true);
    }
    r.remaining -= _minutesPerTick;
    if (r.remaining <= 0) return p.copyWith(arrivedAt: now, position: destination, etaMinutes: 0);
    return p.copyWith(
      position: r.home.lerp(destination, 1 - r.remaining / r.role.travelMinutes),
      etaMinutes: r.remaining.ceil(),
    );
  }

  void _countPoke(_Sim sim, String targetId) {
    final counts = Map.of(sim.session.pokeCounts);
    counts[targetId] = (counts[targetId] ?? 0) + 1;
    sim.session = sim.session.copyWith(pokeCounts: counts);
  }

  static LiveSession _replace(LiveSession s, String id, LiveParticipant Function(LiveParticipant) change) =>
      s.copyWith(participants: [for (final p in s.participants) p.id == id ? change(p) : p]);
}

class _Sim {
  _Sim({required this.session, required this.runners, required this.incomingFrom});

  LiveSession session;
  final Map<String, _Runner> runners;
  final Participant? incomingFrom;
  double elapsed = 0;
  Timer? timer;
  bool finished = false;
  bool pokedMe = false;
}

/// 참여자 한 명의 실제 움직임. 공개 범위와 상관없이 움직이고, 보여줄지는 화면이 정한다.
class _Runner {
  _Runner(this.role, GeoPoint destination)
      : remaining = role.travelMinutes.toDouble(),
        departAfter = role.departAfter,
        home = destination.offset(
          northMeters: role.distanceMeters * cos(role.bearing * pi / 180),
          eastMeters: role.distanceMeters * sin(role.bearing * pi / 180),
        );

  final _Role role;
  final GeoPoint home;
  double remaining;

  /// 시뮬레이션 시작 후 몇 분 뒤에 출발하는지. null이면 이미 출발.
  double? departAfter;
}

/// 와이어프레임 07 장면의 배역. 나 다음 순서의 친구부터 차례로 맡는다.
class _Role {
  const _Role({
    required this.transport,
    required this.travelMinutes,
    required this.bearing,
    this.shareLevel = ShareLevel.basic,
    this.departAfter,
    this.arrivedBefore,
    this.initialCooldown,
  });

  final Transport transport;
  final int travelMinutes;

  /// 목적지에서 본 출발지 방향(도).
  final double bearing;
  final ShareLevel shareLevel;
  final double? departAfter;

  /// 시뮬레이션 시작 몇 분 전에 이미 도착했는지.
  final int? arrivedBefore;
  final Duration? initialCooldown;

  double get distanceMeters =>
      travelMinutes *
      switch (transport) {
        Transport.walk => 70,
        Transport.bus => 110,
        Transport.car => 150,
        Transport.subway => 150,
      };

  /// 나(예은) — 걸어서 5분.
  static const me = _Role(transport: Transport.walk, travelMinutes: 5, bearing: 200);

  static const friends = [
    // 도윤 — 자동차로 18분, 가장 늦게 올 것 같은 사람.
    _Role(transport: Transport.car, travelMinutes: 18, bearing: 60),
    // 서아 — 이미 도착 (1등).
    _Role(transport: Transport.walk, travelMinutes: 0, bearing: 0, shareLevel: ShareLevel.close, arrivedBefore: 4),
    // 민준 — 집에 있음. 늦게 출발해서 약속 시간을 넘긴다. 콕 찌르기 쿨다운 중.
    _Role(transport: Transport.subway, travelMinutes: 40, bearing: 300, departAfter: 14, initialCooldown: Duration(minutes: 3, seconds: 12)),
    // 하린 — 위치 공유 꺼짐. 조용히 와서 도착만 알려진다.
    _Role(transport: Transport.subway, travelMinutes: 43, bearing: 120, shareLevel: ShareLevel.off),
    // 그 밖의 친구 — 걸어서 9분.
    _Role(transport: Transport.walk, travelMinutes: 9, bearing: 160),
    _Role(transport: Transport.bus, travelMinutes: 25, bearing: 270),
  ];
}
