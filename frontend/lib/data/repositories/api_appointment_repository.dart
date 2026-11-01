import '../api/api_client.dart';
import '../models/appointment.dart';
import '../models/decision_template.dart';
import '../models/geo_point.dart';
import '../models/participant.dart';
import '../models/place.dart';
import '../models/vote_option.dart';
import 'mock_appointment_repository.dart';

/// Spring Boot API를 읽는 기본 저장소입니다. 서버가 꺼져 있으면 목업 목록만 보여줍니다.
class ApiAppointmentRepository extends MockAppointmentRepository {
  ApiAppointmentRepository({ApiClient? client}) : client = client ?? ApiClient() {
    load();
  }

  final ApiClient client;

  /// 방 생성·초대 API가 붙기 전까지 로컬 서버가 제공하는 방은 이것 하나뿐이다.
  static const demoRoomId = 'demo-room';

  final _serverIds = <String>{};

  /// 서버에 있는 약속인지. 당일 지도는 서버 약속일 때만 위치 API를 부른다.
  bool isServerAppointment(String appointmentId) => _serverIds.contains(appointmentId);

  Future<void> load() async {
    try {
      final data = await client.get('/api/v1/appointments') as List<dynamic>;
      _merge(data.cast<Map<String, dynamic>>().map(_fromJson));
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
    final data = await client.post('/api/v1/rooms/$demoRoomId/appointments', {
      'name': name,
      'template': _templateName(template),
      'candidatesTime': template.votesTime ? times.map((time) => time.toUtc().toIso8601String()).toList() : [],
      'confirmedTime': template.votesTime ? null : times.firstOrNull?.toUtc().toIso8601String(),
      'candidatesPlace': template.votesPlace ? places.map(_placeJson).toList() : [],
      'confirmedPlace': template.votesPlace ? null : (places.isEmpty ? null : _placeJson(places.first)),
    });
    final appointment = _fromJson(data as Map<String, dynamic>);
    _merge([appointment]);
    return appointment;
  }

  void _merge(Iterable<Appointment> appointments) {
    final list = appointments.toList();
    _serverIds.addAll(list.map((a) => a.id));
    mergeServerAppointments(list);
  }

  Map<String, dynamic> _placeJson(Place place) => {
        'name': place.name,
        'latitude': place.location?.latitude,
        'longitude': place.location?.longitude,
      };

  /// 서버 user id 중 로그인한 나는 앱의 [me]로 바꿔 넣는다. 화면은 [me]의 id로 나를 찾는다.
  String _localId(String serverUserId) => serverUserId == client.user?.id ? me.id : serverUserId;

  Appointment _fromJson(Map<String, dynamic> json) {
    final candidatesTime = (json['candidatesTime'] as List<dynamic>? ?? []).cast<String>();
    final candidatesPlace = (json['candidatesPlace'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final members = (json['members'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final others = [
      for (final m in members)
        if (_localId(m['userId'] as String) != me.id) Participant(id: m['userId'] as String, name: m['name'] as String),
    ];
    final hostId = json['hostId'] as String?;
    return Appointment(
      id: json['id'] as String,
      name: json['name'] as String,
      template: _template(json['template'] as String),
      hostId: hostId == null ? me.id : _localId(hostId),
      inviteCode: json['inviteCode'] as String? ?? json['id'] as String,
      participants: [me, ...others],
      status: _status(json['status'] as String),
      timeOptions: [
        for (final (index, value) in candidatesTime.indexed)
          TimeOption(id: 't$index', value: DateTime.parse(value).toLocal()),
      ],
      placeOptions: [
        for (final (index, value) in candidatesPlace.indexed)
          PlaceOption(id: 'p$index', value: _place(value)),
      ],
      confirmedTime: json['confirmedTime'] == null ? null : DateTime.parse(json['confirmedTime'] as String).toLocal(),
      confirmedPlace: json['confirmedPlace'] == null ? null : _place(json['confirmedPlace'] as Map<String, dynamic>),
    );
  }

  Place _place(Map<String, dynamic> json) {
    final latitude = json['latitude'] as num?;
    final longitude = json['longitude'] as num?;
    return Place(
      name: json['name'] as String,
      location: latitude == null || longitude == null ? null : GeoPoint(latitude.toDouble(), longitude.toDouble()),
    );
  }

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
