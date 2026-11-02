import 'participant.dart';

/// 그룹 = 폴더 = 방. 약속은 하나의 그룹 안에 만들어진다.
class Group {
  const Group({required this.id, required this.name, required this.members, required this.createdAt});

  final String id;
  final String name;
  final List<Participant> members;
  final DateTime createdAt;

  Group copyWith({String? name, List<Participant>? members}) =>
      Group(id: id, name: name ?? this.name, members: members ?? this.members, createdAt: createdAt);
}
