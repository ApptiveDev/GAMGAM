import 'geo_point.dart';

class Place {
  const Place({
    required this.name,
    this.description = '',
    this.location,
    this.category = '',
    this.walkMinutes,
    this.imageAsset,
    this.address = '',
  });

  final String name;

  /// 주소나 "홍대입구역 도보 6분" 같은 보조 설명.
  final String description;

  /// 지도에 찍을 좌표. 장소 검색이 붙기 전까지 직접 입력한 장소는 null.
  final GeoPoint? location;

  /// "양식", "한식" 같은 분류.
  final String category;

  /// 약속 기준 도보 시간(분).
  final int? walkMinutes;

  /// 장소 썸네일 (앱 번들 이미지).
  final String? imageAsset;

  /// 확정 화면에 보여줄 전체 주소. 없으면 [description].
  final String address;

  /// "양식 · 도보 8분"
  List<String> get metaParts => [
        if (category.isNotEmpty) category,
        if (walkMinutes != null) '도보 $walkMinutes분',
        if (category.isEmpty && walkMinutes == null && description.isNotEmpty) description,
      ];
}
