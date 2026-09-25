import 'place.dart';

/// 시간·장소 투표 후보 하나.
class VoteOption<T> {
  const VoteOption({required this.id, required this.value, this.voterIds = const []});

  final String id;
  final T value;
  final List<String> voterIds;

  int get voteCount => voterIds.length;
  bool votedBy(String userId) => voterIds.contains(userId);

  VoteOption<T> copyWith({List<String>? voterIds}) => VoteOption(id: id, value: value, voterIds: voterIds ?? this.voterIds);
}

typedef TimeOption = VoteOption<DateTime>;
typedef PlaceOption = VoteOption<Place>;
