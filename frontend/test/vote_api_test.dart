import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamgam/app.dart';
import 'package:gamgam/data/api/api_client.dart';
import 'package:gamgam/data/models/place.dart';
import 'package:gamgam/data/repositories/api_appointment_repository.dart';
import 'package:gamgam/data/repositories/mock_live_location_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// 약속 하나(시간 후보 2개, 장소 후보 1개)가 있는 가짜 서버. 투표는 #20 API(PUT /votes/time …)처럼 동작한다.
/// 친구(u-friend)는 처음부터 첫 시간 후보에 투표해 두었다.
class FakeServer {
  final calls = <String>[];
  final bodies = <String, Object?>{};

  var joined = true;
  final times = ['2099-05-01T19:00:00+09:00', '2099-05-02T19:00:00+09:00'];
  final places = <Map<String, Object?>>[
    {'name': '성수다락', 'latitude': 37.54, 'longitude': 127.05},
  ];
  final votes = <String, Set<String>>{'time:0': {'u-friend'}};

  late final client = MockClient((request) async {
    final key = '${request.method} ${request.url.path}';
    calls.add(key);
    final body = request.body.isEmpty ? null : jsonDecode(request.body);
    bodies[key] = body;
    const base = '/api/v1/appointments/a1';
    switch (key) {
      case 'POST /api/v1/auth/login':
        return _ok({
          'accessToken': 'token',
          'user': {'id': 'u-me', 'name': '감자'},
        });
      case 'GET /api/v1/appointments':
        return _ok(joined ? [_appointment()] : <Object>[]);
      case 'GET $base':
        return _ok(_appointment());
      case 'POST /api/v1/appointments/join':
        if ((body as Map)['inviteCode'] != 'ABC123') return _fail(404, 'INVALID_INVITE_CODE');
        joined = true;
        return _ok(_appointment());
      case 'GET $base/votes':
        return _ok(_voting());
      case 'PUT $base/votes/time' || 'PUT $base/votes/place':
        final kind = key.endsWith('time') ? 'time' : 'place';
        votes.forEach((k, voters) => k.startsWith(kind) ? voters.remove('u-me') : null);
        for (final i in (body as Map)['optionIndexes'] as List) {
          votes.putIfAbsent('$kind:$i', () => {}).add('u-me');
        }
        return _ok(_voting());
      case 'POST $base/time-candidates':
        times.add((body as Map)['time'] as String);
        return _ok(_voting());
      case 'POST $base/place-candidates':
        if (places.any((p) => p['name'] == (body as Map)['name'])) return _fail(409, 'DUPLICATE_CANDIDATE');
        places.add((body as Map).cast());
        return _ok(_voting());
    }
    return _fail(404, 'NOT_FOUND');
  });

  Map<String, Object?> _appointment() => {
        'id': 'a1',
        'name': '저녁 약속',
        'template': 'BOTH',
        'status': 'COORDINATING',
        'hostId': 'u-friend',
        'inviteCode': 'ABC123',
        'candidatesTime': times,
        'candidatesPlace': places,
        'members': [
          {'userId': 'u-friend', 'name': '도윤'},
          if (joined) {'userId': 'u-me', 'name': '감자'},
        ],
      };

  Map<String, Object?> _voting() {
    List<String> voters(String key) => (votes[key] ?? {}).toList()..sort();
    return {
      'timeOptions': [
        for (final (i, t) in times.indexed) {'index': i, 'time': t, 'voterIds': voters('time:$i')},
      ],
      'placeOptions': [
        for (final (i, p) in places.indexed) {'index': i, 'place': p, 'voterIds': voters('place:$i')},
      ],
    };
  }

  static http.Response _ok(Object? data) =>
      http.Response.bytes(utf8.encode(jsonEncode({'success': true, 'data': data})), 200, headers: {'content-type': 'application/json'});
  static http.Response _fail(int status, String code) => http.Response(jsonEncode({'success': false, 'code': code}), status);
}

void main() {
  Future<(FakeServer, ApiAppointmentRepository)> loggedIn({bool joined = true}) async {
    final server = FakeServer()..joined = joined;
    final repo = ApiAppointmentRepository(client: ApiClient(client: server.client));
    await repo.client.login('me@gamgam.dev', 'password1');
    await repo.load();
    return (server, repo);
  }

  test('약속 목록을 읽으면 표 현황을 투표 API에서 가져오고, 서버 user id 중 나는 앱의 나로 바꾼다', () async {
    final (server, repo) = await loggedIn();
    final a = repo.findById('a1')!;

    expect(repo.me.name, '감자');
    expect(server.calls, contains('GET /api/v1/appointments/a1/votes'));
    expect(a.timeOptions.map((o) => o.id), ['t0', 't1']);
    expect(a.timeOptions.first.voterIds, ['u-friend']);
    expect(a.isHost(repo.me.id), isFalse);
    expect(a.hasMember(repo.me.id), isTrue);
  });

  test('시간은 고른 후보 전체를, 다시 투표는 빈 목록을 보낸다', () async {
    final (server, repo) = await loggedIn();

    await repo.voteTimes('a1', {'t0', 't1'});
    expect(server.bodies['PUT /api/v1/appointments/a1/votes/time'], {
      'optionIndexes': [0, 1],
    });
    expect(repo.findById('a1')!.timeOptions.map((o) => o.votedBy(repo.me.id)), [true, true]);
    expect(repo.findById('a1')!.timeOptions.first.voteCount, 2);

    await repo.clearMyTimeVotes('a1');
    expect(server.bodies['PUT /api/v1/appointments/a1/votes/time'], {'optionIndexes': <int>[]});
    expect(repo.findById('a1')!.timeOptions.map((o) => o.votedBy(repo.me.id)), [false, false]);

    await repo.votePlace('a1', 'p0');
    expect(repo.findById('a1')!.placeOptions.single.votedBy(repo.me.id), isTrue);
    await repo.clearMyPlaceVotes('a1');
    expect(repo.findById('a1')!.placeOptions.single.voteCount, 0);
  });

  test('후보를 올리면 서버 후보 목록으로 바뀌고, 이미 있는 장소는 조용히 넘어간다', () async {
    final (server, repo) = await loggedIn();

    await repo.addTimeOption('a1', DateTime.utc(2099, 5, 3, 10));
    expect(server.bodies['POST /api/v1/appointments/a1/time-candidates'], {'time': '2099-05-03T10:00:00.000Z'});
    expect(repo.findById('a1')!.timeOptions.map((o) => o.id), ['t0', 't1', 't2']);

    await repo.addPlaceOption('a1', const Place(name: '난포', category: '한식'));
    final added = repo.findById('a1')!.placeOptions.last;
    expect(added.id, 'p1');
    expect(added.value.category, '한식', reason: '서버가 모르는 분류는 앱에 있던 값을 다시 붙인다');

    await repo.addPlaceOption('a1', const Place(name: '난포'));
    expect(repo.findById('a1')!.placeOptions, hasLength(2));
  });

  test('앱에 없는 약속은 초대 코드로 바로 참여한다', () async {
    final (server, repo) = await loggedIn(joined: false);
    expect(repo.findById('a1'), isNull);

    await expectLater(repo.joinByInviteCode('WRONG1'), throwsA(isA<ApiException>()));
    final a = await repo.joinByInviteCode('ABC123');
    expect(a.id, 'a1');
    expect(a.hasMember(repo.me.id), isTrue);
    expect(server.calls, contains('GET /api/v1/appointments/a1/votes'));
  });

  testWidgets('초대 링크를 열고 참여하면 약속 화면으로 간다', (tester) async {
    final view = tester.view
      ..physicalSize = const Size(360 * 3, 760 * 3)
      ..devicePixelRatio = 3;
    addTearDown(view.reset);

    final (_, repo) = await loggedIn(joined: false);
    final live = MockLiveLocationRepository(meId: repo.me.id);
    addTearDown(live.dispose);
    await tester.pumpWidget(GamgamApp(repository: repo, liveRepository: live, initialLocation: '/invite/ABC123'));
    await tester.pumpAndSettle();
    expect(find.text('초대 코드 ABC123'), findsOneWidget);

    await tester.tap(find.text('참여하기'));
    await tester.pumpAndSettle();
    expect(find.text('참여하기'), findsNothing);
    expect(find.text('조율중'), findsOneWidget, reason: '약속 상세 화면의 상태 표시');
    expect(find.text('저녁 약속'), findsOneWidget);
  });
}
