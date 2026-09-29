/// 02 템플릿 선택 — 무엇을 투표로 정할지.
enum DecisionTemplate {
  hostDecides('내가 다 정할게요', '투표 없이 바로 확정', votesTime: false, votesPlace: false),
  voteTime('시간만 투표', '장소는 내가 지정', votesTime: true, votesPlace: false),
  votePlace('장소만 투표', '시간은 내가 지정', votesTime: false, votesPlace: true),
  voteBoth('시간·장소 둘 다', '친구들과 함께 투표', votesTime: true, votesPlace: true);

  const DecisionTemplate(this.title, this.description, {required this.votesTime, required this.votesPlace});

  final String title;
  final String description;
  final bool votesTime;
  final bool votesPlace;

  bool get hasVote => votesTime || votesPlace;
}
