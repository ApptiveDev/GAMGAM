class Place {
  const Place({required this.name, this.description = ''});

  final String name;

  /// 주소나 "홍대입구역 도보 6분" 같은 보조 설명.
  final String description;
}
