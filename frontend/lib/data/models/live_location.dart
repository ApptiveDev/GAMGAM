import 'geo_point.dart';
import 'participant.dart';

/// 06 · 방별 위치 공개 범위.
enum ShareLevel {
  off('끔', '친구들에게는 "아직 출발 전"으로만 보여요'),
  basic('기본', '"집에 있음 · 도착까지 40분"까지 보여요. 집 주소는 안 보여요'),
  close('친한 방', '지도에 우리 집 위치까지 보여요');

  const ShareLevel(this.title, this.description);

  final String title;
  final String description;

  /// 아직 고르지 않았을 때 적용하는 값. 06에서 "권장"으로 안내한다.
  static const recommended = ShareLevel.basic;
}

enum Transport {
  bus('Bus', 'On the bus'),
  walk('걷기', '걷는 중'),
  car('자동차', '자동차'),
  subway('지하철', '지하철');

  const Transport(this.label, this.movingLabel);

  final String label;

  /// "5분 후 도착 · 걷는 중" / "이동 중 · 자동차"
  final String movingLabel;

  static Transport fromSpeedKmh(double speedKmh) {
    if (speedKmh < 7) return Transport.walk;
    if (speedKmh < 45) return Transport.bus;
    if (speedKmh < 90) return Transport.car;
    return Transport.subway;
  }
}

enum LiveStatus { arrived, moving, notDeparted, sharingOff }

/// 당일 지도에서 본 참여자 한 명.
class LiveParticipant {
  const LiveParticipant({
    required this.participant,
    required this.shareLevel,
    required this.transport,
    this.departed = false,
    this.position,
    this.etaMinutes,
    this.arrivedAt,
  });

  final Participant participant;
  final ShareLevel shareLevel;
  final Transport transport;
  final bool departed;

  /// 서버가 내려준 현재 위치. 화면에 찍을지는 [visibleOnMap]으로 판단한다.
  final GeoPoint? position;
  final int? etaMinutes;
  final DateTime? arrivedAt;

  String get id => participant.id;
  bool get arrived => arrivedAt != null;

  LiveStatus get status {
    if (arrived) return LiveStatus.arrived;
    if (shareLevel == ShareLevel.off) return LiveStatus.sharingOff;
    if (!departed) return LiveStatus.notDeparted;
    return LiveStatus.moving;
  }

  /// 집 위치는 '친한 방'일 때만 보인다. 도착한 사람은 목적지 핀과 겹치므로 뺀다.
  bool get visibleOnMap =>
      position != null && (status == LiveStatus.moving || (status == LiveStatus.notDeparted && shareLevel == ShareLevel.close));

  LiveParticipant copyWith({
    Transport? transport,
    ShareLevel? shareLevel,
    bool? departed,
    GeoPoint? position,
    int? etaMinutes,
    DateTime? arrivedAt,
  }) =>
      LiveParticipant(
        participant: participant,
        shareLevel: shareLevel ?? this.shareLevel,
        transport: transport ?? this.transport,
        departed: departed ?? this.departed,
        position: position ?? this.position,
        etaMinutes: etaMinutes ?? this.etaMinutes,
        arrivedAt: arrivedAt ?? this.arrivedAt,
      );
}

/// 08 · 콕 찌르기 문구.
enum PokeMessage {
  hurry('빨리와'),
  waiting('기다릴게'),
  meLate('나도 늦어'),
  takeYourTime('천천히 와');

  const PokeMessage(this.label);

  final String label;
}

/// 콕 찔린 사람이 알림에서 바로 보내는 답장.
enum PokeReply {
  fiveMinutes('5분 뒤 도착'),
  tenMinutes('10분 뒤 도착'),
  leavingNow('지금 출발');

  const PokeReply(this.label);

  final String label;
}

/// 같은 사람에게 다시 콕 찌르려면 이만큼 기다려야 한다.
const pokeCooldown = Duration(minutes: 5);

class Poke {
  const Poke({required this.from, required this.to, required this.message});

  final Participant from;
  final Participant to;
  final PokeMessage message;
}

/// 약속 하나의 당일 현황.
class LiveSession {
  const LiveSession({
    required this.appointmentId,
    required this.destination,
    required this.appointmentTime,
    required this.now,
    required this.participants,
    this.pokeCounts = const {},
  });

  final String appointmentId;
  final GeoPoint destination;
  final DateTime appointmentTime;

  /// 현황 기준 시각. 목업에서는 빠르게 흘러가는 시뮬레이션 시계.
  final DateTime now;
  final List<LiveParticipant> participants;

  /// 참여자별 오늘 받은 콕 찌르기 수.
  final Map<String, int> pokeCounts;

  Duration get remaining => appointmentTime.difference(now);
  bool get allArrived => participants.every((p) => p.arrived);
  int get totalPokes => pokeCounts.values.fold(0, (a, b) => a + b);

  /// 도착한 순서.
  List<LiveParticipant> get arrivalOrder => participants.where((p) => p.arrived).toList()..sort((a, b) => a.arrivedAt!.compareTo(b.arrivedAt!));

  LiveParticipant? byId(String id) {
    for (final p in participants) {
      if (p.id == id) return p;
    }
    return null;
  }

  LiveSession copyWith({DateTime? now, List<LiveParticipant>? participants, Map<String, int>? pokeCounts}) => LiveSession(
        appointmentId: appointmentId,
        destination: destination,
        appointmentTime: appointmentTime,
        now: now ?? this.now,
        participants: participants ?? this.participants,
        pokeCounts: pokeCounts ?? this.pokeCounts,
      );
}

/// 당일 지도를 보는 동안 실시간으로 들어오는 일. 화면은 배너·스낵바로 보여준다.
sealed class LiveEvent {
  const LiveEvent();
}

class PokeReceived extends LiveEvent {
  const PokeReceived(this.poke);

  final Poke poke;
}

class PokeReplied extends LiveEvent {
  const PokeReplied(this.from, this.reply);

  final Participant from;
  final PokeReply reply;
}

class FriendDeparted extends LiveEvent {
  const FriendDeparted(this.who);

  final Participant who;
}

class AllArrived extends LiveEvent {
  const AllArrived();
}
