import '../api/api_client.dart';
import '../models/appointment.dart';
import '../models/decision_template.dart';
import '../models/geo_point.dart';
import '../models/participant.dart';
import '../models/place.dart';
import '../models/vote_option.dart';
import 'mock_appointment_repository.dart';

/// Spring Boot API를 읽는 기본 저장소입니다. 서버가 꺼져 있으면 목업 목록만 보여줍니다.
///
/// 서버에 있는 기능(약속 목록·상세, 시간·장소 투표, 후보 추가, 초대 참여)만 서버로 보내고,
/// 그룹·이름 바꾸기·투표 종료·벌칙처럼 아직 API가 없는 기능은 목업이 맡는다.
/// 표 현황은 약속 응답이 아니라 투표 API(GET /votes)에서 읽는다.
class ApiAppointmentRepository extends MockAppointmentRepository {
  ApiAppointmentRepository({ApiClient? client}) : client = client ?? ApiClient() {
    load();
  }

  final ApiClient client;

  /// 화면은 [me]의 id로 나를 찾으므로 id는 목업 그대로 두고, 이름만 로그인한 사용자로 바꾼다.
  @override
  Participant get me {
    final user = client.user;
    return user == null ? super.me : Participant(id: super.me.id, name: user.name);
  }

  /// 방 생성·초대 API가 붙기 전까지 로컬 서버가 제공하는 방은 이것 하나뿐이다.
  static const demoRoomId = 'demo-room';

  final _serverIds = <String>{};

  /// 서버는 장소를 이름과 좌표로만 돌려준다. 후보로 올릴 때 들고 있던 분류·사진은 여기 두었다가 다시 붙인다.
  final _placeDetails = <String, Place>{};

  /// 서버에 있는 약속인지. 당일 지도는 서버 약속일 때만 위치 API를 부른다.
  bool isServerAppointment(String appointmentId) => _serverIds.contains(appointmentId);

  Future<void> load() async {
    try {
      final data = await client.get('/api/v1/appointments') as List<dynamic>;
      final list = data.cast<Map<String, dynamic>>().map(_fromJson).toList();
      final ids = list.map((a) => a.id).toSet();
      removeAppointments(_serverIds.difference(ids));
      _serverIds.retainAll(ids);
      _merge(list);
      await Future.wait([for (final a in list) if (a.isCoordinating) _refreshVotes(a.id)]);
    } catch (_) {
      // 개발 중 서버가 꺼져 있어도 앱 화면은 계속 열리도록 한다.
    }
  }

  @override
  Future<void> refresh(String appointmentId) async {
    if (!isServerAppointment(appointmentId)) return;
    _merge([_fromJson(await client.get('/api/v1/appointments/$appointmentId') as Map<String, dynamic>)]);
    await _refreshVotes(appointmentId);
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
      'candidatesTime': template.votesTime ? times.map(_timeJson).toList() : [],
      'confirmedTime': template.votesTime ? null : times.map(_timeJson).firstOrNull,
      'candidatesPlace': template.votesPlace ? places.map(_placeJson).toList() : [],
      'confirmedPlace': template.votesPlace ? null : (places.isEmpty ? null : _placeJson(places.first)),
    });
    final appointment = _fromJson(data as Map<String, dynamic>);
    _merge([appointment]);
    return appointment;
  }

  @override
  Future<void> join(String appointmentId) async {
    if (!isServerAppointment(appointmentId)) return super.join(appointmentId);
    await joinByInviteCode(findById(appointmentId)!.inviteCode);
  }

  @override
  Future<Appointment> joinByInviteCode(String code) async {
    final local = findByInviteCode(code);
    if (local != null && !isServerAppointment(local.id)) return super.joinByInviteCode(code);
    final String id;
    try {
      final appointment = _fromJson(await client.post('/api/v1/appointments/join', {'inviteCode': code.trim()}) as Map<String, dynamic>);
      _merge([appointment]);
      id = appointment.id;
    } on ApiException catch (e) {
      // 다른 기기에서 이미 들어간 약속이면 내 목록에 있으니 다시 읽어서 찾는다.
      if (e.code != 'ALREADY_JOINED') rethrow;
      await load();
      final joined = findByInviteCode(code);
      if (joined == null) rethrow;
      return joined;
    }
    await _refreshVotes(id);
    return findById(id)!;
  }

  @override
  Future<void> voteTimes(String appointmentId, Set<String> optionIds) async {
    if (!isServerAppointment(appointmentId)) return super.voteTimes(appointmentId, optionIds);
    await _vote(appointmentId, 'time', optionIds);
  }

  @override
  Future<void> votePlace(String appointmentId, String optionId) async {
    if (!isServerAppointment(appointmentId)) return super.votePlace(appointmentId, optionId);
    await _vote(appointmentId, 'place', {optionId});
  }

  @override
  Future<void> clearMyPlaceVotes(String appointmentId) async {
    if (!isServerAppointment(appointmentId)) return super.clearMyPlaceVotes(appointmentId);
    await _vote(appointmentId, 'place', const {});
  }

  @override
  Future<void> addTimeOption(String appointmentId, DateTime time) async {
    if (!isServerAppointment(appointmentId)) return super.addTimeOption(appointmentId, time);
    await _addCandidate(appointmentId, 'time-candidates', {'time': _timeJson(time)});
  }

  @override
  Future<void> addPlaceOption(String appointmentId, Place place) async {
    if (!isServerAppointment(appointmentId)) return super.addPlaceOption(appointmentId, place);
    _placeDetails[place.name] = place;
    await _addCandidate(appointmentId, 'place-candidates', _placeJson(place));
  }

  /// 같은 후보가 이미 있으면 목업처럼 조용히 넘어간다.
  Future<void> _addCandidate(String appointmentId, String path, Map<String, dynamic> body) async {
    try {
      _applyVoting(appointmentId, await client.post('/api/v1/appointments/$appointmentId/$path', body));
    } on ApiException catch (e) {
      if (e.code != 'DUPLICATE_CANDIDATE') rethrow;
      await _refreshVotes(appointmentId);
    }
  }

  /// 서버는 고른 후보 전체를 받아 내 표를 바꾼다. 빈 집합이면 내 표를 모두 취소한다.
  Future<void> _vote(String appointmentId, String kind, Set<String> optionIds) async {
    final indexes = optionIds.map((id) => int.parse(id.substring(1))).toList();
    _applyVoting(appointmentId, await client.put('/api/v1/appointments/$appointmentId/votes/$kind', {'optionIndexes': indexes}));
  }

  Future<void> _refreshVotes(String appointmentId) async =>
      _applyVoting(appointmentId, await client.get('/api/v1/appointments/$appointmentId/votes'));

  /// 투표 API 응답으로 후보와 표를 통째로 바꾼다. 후보 id는 서버의 후보 순서(t0, p1 …)다.
  void _applyVoting(String appointmentId, Object? data) {
    final json = data as Map<String, dynamic>;
    final times = (json['timeOptions'] as List<dynamic>).cast<Map<String, dynamic>>();
    final places = (json['placeOptions'] as List<dynamic>).cast<Map<String, dynamic>>();
    List<String> voters(Map<String, dynamic> option) => [for (final id in option['voterIds'] as List<dynamic>) _localId(id as String)];
    update(appointmentId, (a) => a.copyWith(
          timeOptions: [
            for (final o in times)
              TimeOption(id: 't${o['index']}', value: DateTime.parse(o['time'] as String).toLocal(), voterIds: voters(o)),
          ],
          placeOptions: [
            for (final o in places) PlaceOption(id: 'p${o['index']}', value: _place(o['place'] as Map<String, dynamic>), voterIds: voters(o)),
          ],
        ));
  }

  void _merge(Iterable<Appointment> appointments) {
    final list = appointments.toList();
    _serverIds.addAll(list.map((a) => a.id));
    mergeServerAppointments(list);
  }

  String _timeJson(DateTime time) => time.toUtc().toIso8601String();

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
    final name = json['name'] as String;
    final known = _placeDetails[name];
    if (known != null) return known;
    final latitude = json['latitude'] as num?;
    final longitude = json['longitude'] as num?;
    return Place(
      name: name,
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
