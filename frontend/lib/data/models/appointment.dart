import 'decision_template.dart';
import 'participant.dart';
import 'place.dart';
import 'vote_option.dart';

enum AppointmentStatus { coordinating, confirmed, completed }

/// 약속 하나 = 방 하나.
class Appointment {
  const Appointment({
    required this.id,
    required this.name,
    required this.template,
    required this.hostId,
    required this.inviteCode,
    required this.participants,
    this.status = AppointmentStatus.coordinating,
    this.timeOptions = const [],
    this.placeOptions = const [],
    this.voteDeadline,
    this.confirmedTime,
    this.confirmedPlace,
    this.penalty,
    this.lateThresholdMinutes = 10,
    this.penaltyAgreedIds = const [],
    this.lateCount = 0,
  });

  final String id;
  final String name;
  final DecisionTemplate template;
  final String hostId;
  final String inviteCode;
  final List<Participant> participants;
  final AppointmentStatus status;

  /// 투표 후보. 투표하지 않는 항목은 후보가 1개(=주최자가 정한 값)다.
  final List<TimeOption> timeOptions;
  final List<PlaceOption> placeOptions;

  /// 방장이 만들 때 정한 투표 마감 시각. 투표가 없는 약속은 null.
  /// 마감이 지나도 자동 확정은 하지 않고, 방장이 확정할 때까지 투표만 막는다.
  final DateTime? voteDeadline;

  final DateTime? confirmedTime;
  final Place? confirmedPlace;

  /// 지각 벌칙. null이면 아직 안 정함, '벌칙 없음'도 하나의 값.
  final String? penalty;
  final int lateThresholdMinutes;
  final List<String> penaltyAgreedIds;

  /// 지난 약속의 지각자 수.
  final int lateCount;

  bool get isCoordinating => status == AppointmentStatus.coordinating;
  bool get isConfirmed => status == AppointmentStatus.confirmed;
  bool get isCompleted => status == AppointmentStatus.completed;

  bool isHost(String userId) => hostId == userId;

  bool isVoteClosed(DateTime now) => !isCoordinating || (voteDeadline != null && !now.isBefore(voteDeadline!));

  /// 이미 같은 이름이 있으면 "지수(2)", "지수(3)"처럼 번호를 붙인다.
  String uniqueName(String name) {
    final taken = participants.map((p) => p.name).toSet();
    if (!taken.contains(name)) return name;
    var n = 2;
    while (taken.contains('$name($n)')) {
      n++;
    }
    return '$name($n)';
  }
  bool hasMember(String userId) => participants.any((p) => p.id == userId);

  /// 확정 전이면 현재 1위 후보를 보여준다.
  DateTime? get time => confirmedTime ?? _leader(timeOptions)?.value;
  Place? get place => confirmedPlace ?? _leader(placeOptions)?.value;

  /// 투표가 필요한 항목에 한 표라도 던졌는지.
  bool hasVoted(String userId) =>
      (template.votesTime && timeOptions.any((o) => o.votedBy(userId))) || (template.votesPlace && placeOptions.any((o) => o.votedBy(userId)));

  /// 투표가 필요한 항목에 아직 한 표도 안 던진 사람 수.
  int get pendingVoterCount {
    if (!isCoordinating || !template.hasVote) return 0;
    return participants.where((p) => !hasVoted(p.id)).length;
  }

  /// 약속 2시간 전부터 약속 시각까지 = 위치 공유 창.
  bool isSharingLocation(DateTime now) {
    final t = confirmedTime;
    if (!isConfirmed || t == null) return false;
    return now.isAfter(t.subtract(const Duration(hours: 2))) && now.isBefore(t);
  }

  static VoteOption<T>? _leader<T>(List<VoteOption<T>> options) {
    if (options.isEmpty) return null;
    return options.reduce((a, b) => b.voteCount > a.voteCount ? b : a);
  }

  Appointment copyWith({
    List<Participant>? participants,
    AppointmentStatus? status,
    List<TimeOption>? timeOptions,
    List<PlaceOption>? placeOptions,
    DateTime? voteDeadline,
    DateTime? confirmedTime,
    Place? confirmedPlace,
    String? penalty,
    int? lateThresholdMinutes,
    List<String>? penaltyAgreedIds,
    int? lateCount,
  }) =>
      Appointment(
        id: id,
        name: name,
        template: template,
        hostId: hostId,
        inviteCode: inviteCode,
        participants: participants ?? this.participants,
        status: status ?? this.status,
        timeOptions: timeOptions ?? this.timeOptions,
        placeOptions: placeOptions ?? this.placeOptions,
        voteDeadline: voteDeadline ?? this.voteDeadline,
        confirmedTime: confirmedTime ?? this.confirmedTime,
        confirmedPlace: confirmedPlace ?? this.confirmedPlace,
        penalty: penalty ?? this.penalty,
        lateThresholdMinutes: lateThresholdMinutes ?? this.lateThresholdMinutes,
        penaltyAgreedIds: penaltyAgreedIds ?? this.penaltyAgreedIds,
        lateCount: lateCount ?? this.lateCount,
      );
}
