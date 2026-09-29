import 'geo_point.dart';

class Place {
  const Place({required this.name, this.description = '', this.location});

  final String name;

  /// 주소나 "홍대입구역 도보 6분" 같은 보조 설명.
  final String description;

  /// 지도에 찍을 좌표. 장소 검색이 붙기 전까지 직접 입력한 장소는 null.
  final GeoPoint? location;
}
