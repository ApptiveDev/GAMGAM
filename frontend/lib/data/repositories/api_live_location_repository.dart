import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../api/api_client.dart';
import '../models/appointment.dart';
import '../models/geo_point.dart';
import '../models/live_location.dart';
import 'mock_live_location_repository.dart';

/// 서버 약속은 위치 API(PUT location, GET map)로 그리고, 나머지는 목업 시뮬레이션을 쓴다.
///
/// 서버가 아직 주지 않는 것: 친구의 ETA·상태·도착 시각·이동수단·공유 범위, 콕 찌르기.
class ApiLiveLocationRepository extends MockLiveLocationRepository {
  ApiLiveLocationRepository({super.meId, required ApiClient client, bool Function(String appointmentId)? isServerAppointment})
      : _client = client,
        _isServerAppointment = isServerAppointment ?? ((_) => false);

  final ApiClient _client;
  final bool Function(String) _isServerAppointment;
  final _timers = <String, Timer>{};

  /// 목업 데모 약속. 서버에는 없지만 내 위치만 기기 GPS로 보여준다.
  static const _gpsDemoId = 'a-donggi';

  @override
  bool usesDeviceLocationFor(String appointmentId) => appointmentId == _gpsDemoId || isLiveFromServer(appointmentId);

  @override
  bool isLiveFromServer(String appointmentId) => _isServerAppointment(appointmentId);

  @override
  void start(Appointment appointment) {
    super.start(appointment);
    if (usesDeviceLocationFor(appointment.id)) {
      _sync(appointment.id);
      _timers.putIfAbsent(appointment.id, () => Timer.periodic(const Duration(seconds: 3), (_) => _sync(appointment.id)));
    }
  }

  @override
  void stop(String appointmentId) {
    _timers.remove(appointmentId)?.cancel();
    super.stop(appointmentId);
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<void> _sync(String roomId) async {
    final mine = await _currentPosition();
    if (mine == null) return;
    final speedKmh = math.max(0.0, mine.speed * 3.6);
    final transport = Transport.fromSpeedKmh(speedKmh);
    final point = GeoPoint(mine.latitude, mine.longitude);
    final destination = session(roomId)?.destination;
    if (destination != null) setMeasuredLocation(roomId, meId, point, transport, _etaMinutes(point, destination, mine.speed));
    if (!isLiveFromServer(roomId)) return;

    try {
      final level = shareLevelOf(roomId) ?? ShareLevel.recommended;
      await _client.put('/api/v1/rooms/$roomId/location', {
        'latitude': mine.latitude,
        'longitude': mine.longitude,
        'sharingEnabled': level != ShareLevel.off,
        'shareLevel': level.name.toUpperCase(),
        'speedKmh': math.min(speedKmh, 500),
        'transport': transport.name.toUpperCase(),
      });
      final data = await _client.get('/api/v1/rooms/$roomId/map?latitude=${mine.latitude}&longitude=${mine.longitude}') as Map<String, dynamic>;
      final participants = (data['participants'] as List<dynamic>).cast<Map<String, dynamic>>();
      // 내 위치는 위에서 기기 GPS로 넣었다. 여기서는 친구들만 반영한다.
      applyServerPositions(roomId, {
        for (final item in participants)
          if (item['self'] != true)
            item['id'] as String: GeoPoint((item['latitude'] as num).toDouble(), (item['longitude'] as num).toDouble()),
      });
    } catch (_) {
      // 공유 시간(약속 30분 전 ~ 30분 후) 밖이거나 서버가 꺼져 있으면 다음 주기에 다시 시도한다.
    }
  }

  Future<Position?> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;
    return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
  }

  int _etaMinutes(GeoPoint from, GeoPoint to, double speedMetersPerSecond) {
    const earthRadius = 6371000.0;
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLat = (to.latitude - from.latitude) * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) + math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final distance = earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final speed = speedMetersPerSecond < 0.8 ? 1.4 : speedMetersPerSecond;
    return (distance / speed / 60).ceil();
  }
}
