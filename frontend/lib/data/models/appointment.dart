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
    this.confirmedTime,
    this.confirmedPlace,
    this.penalty,
    this.lateThresholdMinutes = 10,
    this.penaltyAgreedIds = const [],
    this.lateCount = 0,
    this.groupId,
    this.imageAsset,
    this.createdAt,
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

  final DateTime? confirmedTime;
  final Place? confirmedPlace;

  /// 지각 벌칙. null이면 아직 안 정함, '벌칙 없음'도 하나의 값.
  final String? penalty;
  final int lateThresholdMinutes;
  final List<String> penaltyAgreedIds;

  /// 지난 약속의 지각자 수.
  final int lateCount;

  /// 이 약속이 들어 있는 그룹(폴더). 서버에 그룹 API가 생기기 전에는 앱에서만 정한다.
  final String? groupId;

  /// 약속 썸네일 (앱 번들 이미지).
  final String? imageAsset;

  /// 그룹 안 "최근 만든 순" 정렬에 쓴다.
  final DateTime? createdAt;

  bool get isCoordinating => status == AppointmentStatus.coordinating;
  bool get isConfirmed => status == AppointmentStatus.confirmed;
  bool get isCompleted => status == AppointmentStatus.completed;

  bool isHost(String userId) => hostId == userId;
  bool hasMember(String userId) => participants.any((p) => p.id == userId);

  /// 시간·장소를 투표로 정하는 중인지. 둘 중 하나라도 아직 안 정해졌으면 true.
  bool get isVotingTime => isCoordinating && confirmedTime == null;
  bool get isVotingPlace => isCoordinating && confirmedPlace == null;

  /// 이 후보 목록에 아직 한 표도 안 던진 사람 수.
  int pendingVotersOf<T>(List<VoteOption<T>> options) {
    final voted = options.expand((o) => o.voterIds).toSet();
    return participants.where((p) => !voted.contains(p.id)).length;
  }

  /// 확정 전이면 현재 1위 후보를 보여준다.
  DateTime? get time => confirmedTime ?? _leader(timeOptions)?.value;
  Place? get place => confirmedPlace ?? _leader(placeOptions)?.value;

  /// 투표가 필요한 항목에 아직 한 표도 안 던진 사람 수.
  int get pendingVoterCount {
    if (!isCoordinating || !template.hasVote) return 0;
    final voted = <String>{
      if (template.votesTime) ...timeOptions.expand((o) => o.voterIds),
      if (template.votesPlace) ...placeOptions.expand((o) => o.voterIds),
    };
    return participants.where((p) => !voted.contains(p.id)).length;
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
    String? name,
    List<Participant>? participants,
    AppointmentStatus? status,
    List<TimeOption>? timeOptions,
    List<PlaceOption>? placeOptions,
    DateTime? confirmedTime,
    Place? confirmedPlace,
    String? penalty,
    int? lateThresholdMinutes,
    List<String>? penaltyAgreedIds,
    int? lateCount,
    String? groupId,
    String? imageAsset,
  }) =>
      Appointment(
        id: id,
        name: name ?? this.name,
        template: template,
        hostId: hostId,
        inviteCode: inviteCode,
        participants: participants ?? this.participants,
        status: status ?? this.status,
        timeOptions: timeOptions ?? this.timeOptions,
        placeOptions: placeOptions ?? this.placeOptions,
        confirmedTime: confirmedTime ?? this.confirmedTime,
        confirmedPlace: confirmedPlace ?? this.confirmedPlace,
        penalty: penalty ?? this.penalty,
        lateThresholdMinutes: lateThresholdMinutes ?? this.lateThresholdMinutes,
        penaltyAgreedIds: penaltyAgreedIds ?? this.penaltyAgreedIds,
        lateCount: lateCount ?? this.lateCount,
        groupId: groupId ?? this.groupId,
        imageAsset: imageAsset ?? this.imageAsset,
        createdAt: createdAt,
      );
}
