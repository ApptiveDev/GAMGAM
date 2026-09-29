import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/appointment.dart';
import '../models/decision_template.dart';
import '../models/place.dart';
import '../models/vote_option.dart';
import 'mock_appointment_repository.dart';

/// Spring Boot API를 읽는 기본 저장소입니다. 서버가 꺼져 있으면 빈 목록을 유지합니다.
class ApiAppointmentRepository extends MockAppointmentRepository {
  ApiAppointmentRepository({http.Client? client}) : _client = client ?? http.Client() {
    load();
  }

  final http.Client _client;

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    return Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
  }

  Future<void> load() async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/api/v1/appointments'));
      if (response.statusCode != 200) return;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>;
      mergeServerAppointments(data.cast<Map<String, dynamic>>().map(_fromJson));
    } catch (_) {
      // 개발 중 서버가 꺼져 있어도 앱 화면은 계속 열리도록 한다.
    }
  }

  @override
  Future<Appointment> create({
    required String name,
    required DecisionTemplate template,
    required List<DateTime> times,
    required List<Place> places,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/v1/appointments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'template': _templateName(template),
        'candidatesTime': template.votesTime ? times.map((time) => time.toUtc().toIso8601String()).toList() : [],
        'confirmedTime': template.votesTime ? null : times.firstOrNull?.toUtc().toIso8601String(),
        'candidatesPlace': template.votesPlace ? places.map(_placeJson).toList() : [],
        'confirmedPlace': template.votesPlace ? null : (places.isEmpty ? null : _placeJson(places.first)),
      }),
    );
    if (response.statusCode != 201) throw StateError('약속 생성에 실패했습니다. (${response.statusCode})');
    final appointment = _fromJson(
      (jsonDecode(response.body) as Map<String, dynamic>)['data']
          as Map<String, dynamic>,
    );
    mergeServerAppointments([appointment]);
    return appointment;
  }

  Map<String, dynamic> _placeJson(Place place) => {
        'name': place.name,
        'latitude': place.location?.latitude,
        'longitude': place.location?.longitude,
      };

  Appointment _fromJson(Map<String, dynamic> json) {
    final candidatesTime = (json['candidatesTime'] as List<dynamic>? ?? []).cast<String>();
    final candidatesPlace = (json['candidatesPlace'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return Appointment(
      id: json['id'] as String,
      name: json['name'] as String,
      template: _template(json['template'] as String),
      hostId: me.id,
      inviteCode: json['id'] as String,
      participants: [me],
      status: _status(json['status'] as String),
      timeOptions: [
        for (final (index, value) in candidatesTime.indexed)
          TimeOption(id: 't$index', value: DateTime.parse(value)),
      ],
      placeOptions: [
        for (final (index, value) in candidatesPlace.indexed)
          PlaceOption(id: 'p$index', value: _place(value)),
      ],
      confirmedTime: json['confirmedTime'] == null
          ? null
          : DateTime.parse(json['confirmedTime'] as String),
      confirmedPlace: json['confirmedPlace'] == null
          ? null
          : _place(json['confirmedPlace'] as Map<String, dynamic>),
    );
  }

  Place _place(Map<String, dynamic> json) => Place(name: json['name'] as String);
  DecisionTemplate _template(String value) => switch (value) {
        'TIME_ONLY' => DecisionTemplate.voteTime,
        'PLACE_ONLY' => DecisionTemplate.votePlace,
        'BOTH' => DecisionTemplate.voteBoth,
        _ => DecisionTemplate.hostDecides,
      };

  String _templateName(DecisionTemplate value) => switch (value) {
        DecisionTemplate.voteTime => 'TIME_ONLY',
        DecisionTemplate.votePlace => 'PLACE_ONLY',
        DecisionTemplate.voteBoth => 'BOTH',
        DecisionTemplate.hostDecides => 'ALL',
      };

  AppointmentStatus _status(String value) => switch (value) {
        'CONFIRMED' => AppointmentStatus.confirmed,
        'COMPLETED' => AppointmentStatus.completed,
        _ => AppointmentStatus.coordinating,
      };
}
