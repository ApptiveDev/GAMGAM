import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/appointment.dart';
import '../models/geo_point.dart';
import '../models/live_location.dart';
import 'mock_live_location_repository.dart';

class ApiLiveLocationRepository extends MockLiveLocationRepository {
  ApiLiveLocationRepository({super.meId, http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final _timers = <String, Timer>{};

  @override
  bool usesDeviceLocationFor(String appointmentId) => appointmentId == 'a-donggi';

  String get _baseUrl => kIsWeb ? 'http://localhost:8080' : (Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080');

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

  Future<void> _sync(String roomId) async {
    final mine = await _currentPosition();
    if (mine == null) return;
    try {
      final transport = Transport.fromSpeedKmh(mine.speed * 3.6);
      setTransport(roomId, 'u-yeeun', transport);
      final point = GeoPoint(mine.latitude, mine.longitude);
      final destination = session(roomId)?.destination;
      if (destination != null) {
        final eta = _etaMinutes(point, destination, mine.speed);
        setMeasuredLocation(roomId, 'u-yeeun', point, transport, eta);
      }
      await _client.put(Uri.parse('$_baseUrl/api/v1/rooms/$roomId/location'), headers: {'Content-Type': 'application/json', 'X-User-Id': 'u-yeeun'}, body: jsonEncode({'latitude': mine.latitude, 'longitude': mine.longitude, 'sharingEnabled': true, 'shareLevel': 'BASIC', 'speedKmh': mine.speed * 3.6, 'transport': transport.name.toUpperCase()}));
      final response = await _client.get(Uri.parse('$_baseUrl/api/v1/rooms/$roomId/map?latitude=${mine.latitude}&longitude=${mine.longitude}'));
      if (response.statusCode != 200) return;
      final participants = ((jsonDecode(response.body) as Map<String, dynamic>)['data'] as Map<String, dynamic>)['participants'] as List<dynamic>;
      applyServerPositions(roomId, {
        for (final item in participants.cast<Map<String, dynamic>>())
          item['id'] as String: GeoPoint(
            (item['latitude'] as num).toDouble(),
            (item['longitude'] as num).toDouble(),
          ),
      });
    } catch (_) {}
  }

  Future<Position?> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;
    final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
    return position;
  }

  int _etaMinutes(GeoPoint from, GeoPoint to, double speedMetersPerSecond) {
    const earthRadius = 6371000.0;
    final lat1 = from.latitude * 3.141592653589793 / 180;
    final lat2 = to.latitude * 3.141592653589793 / 180;
    final dLat = (to.latitude - from.latitude) * 3.141592653589793 / 180;
    final dLon = (to.longitude - from.longitude) * 3.141592653589793 / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) + math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final distance = earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final speed = speedMetersPerSecond < 0.8 ? 1.4 : speedMetersPerSecond;
    return (distance / speed / 60).ceil();
  }
}
