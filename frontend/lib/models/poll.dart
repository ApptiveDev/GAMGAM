class PollOption {
  const PollOption({required this.label, required this.voterIds, required this.voteCount});

  final String label;
  final List<String> voterIds;
  final int voteCount;
}

class RoomPoll {
  const RoomPoll({required this.timeOptions, required this.placeOptions, required this.pendingCount});

  final List<PollOption> timeOptions;
  final List<PollOption> placeOptions;
  final int pendingCount;
}
