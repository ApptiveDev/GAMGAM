class ArrivalResult {
  const ArrivalResult({
    required this.participantId,
    required this.rank,
    required this.lateMinutes,
    this.penalty,
  });

  final String participantId;
  final int rank;
  final int lateMinutes;
  final String? penalty;
}
