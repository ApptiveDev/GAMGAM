import 'dart:math';

/// 위도·경도. 지도 SDK 타입(LatLng 등)에 묶이지 않도록 데이터 계층은 이것만 쓴다.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);


  final double latitude;
  final double longitude;

  /// 홍대입구역. 좌표가 없는 장소의 기본 목적지.
  static const hongikUniv = GeoPoint(37.5572, 126.9245);

  /// [other] 쪽으로 [t](0~1)만큼 이동한 지점.
  GeoPoint lerp(GeoPoint other, double t) =>
      GeoPoint(latitude + (other.latitude - latitude) * t, longitude + (other.longitude - longitude) * t);

  /// 북쪽으로 [northMeters], 동쪽으로 [eastMeters] 떨어진 지점. 목업 좌표를 만들 때 쓴다.
  GeoPoint offset({double northMeters = 0, double eastMeters = 0}) => GeoPoint(
        latitude + northMeters / 111320,
        longitude + eastMeters / (111320 * cos(latitude * pi / 180)),
      );
}
