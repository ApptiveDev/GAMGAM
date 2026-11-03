import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamgam/app.dart';
import 'package:gamgam/data/api/api_client.dart';
import 'package:gamgam/data/repositories/api_appointment_repository.dart';
import 'package:gamgam/data/repositories/mock_live_location_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.physicalSize = const Size(360 * 3, 760 * 3);
    view.devicePixelRatio = 3;
  });

  /// 가입된 계정은 a@gamgam.dev / password1 하나뿐인 가짜 서버.
  MockClient fakeServer(List<String> calls) {
    final users = {'a@gamgam.dev': ('password1', '예은')};
    http.Response ok(Object? data, [int status = 200]) =>
        http.Response.bytes(utf8.encode(jsonEncode({'success': true, 'data': data})), status, headers: {'content-type': 'application/json'});
    http.Response fail(int status, String code) => http.Response(jsonEncode({'success': false, 'code': code}), status);

    return MockClient((request) async {
      calls.add('${request.method} ${request.url.path}');
      final body = request.body.isEmpty ? const <String, dynamic>{} : jsonDecode(request.body) as Map<String, dynamic>;
      switch (request.url.path) {
        case '/api/v1/auth/login':
          final user = users[body['email']];
          if (user == null || user.$1 != body['password']) return fail(401, 'INVALID_CREDENTIALS');
          return ok({
            'accessToken': 'token',
            'user': {'id': 'u-${body['email']}', 'name': user.$2},
          });
        case '/api/v1/auth/signup':
          if (users.containsKey(body['email'])) return fail(409, 'EMAIL_ALREADY_EXISTS');
          users[body['email'] as String] = (body['password'] as String, body['name'] as String);
          return ok({'id': 'u-${body['email']}', 'email': body['email'], 'name': body['name']}, 201);
        case '/api/v1/appointments':
          if (request.headers['Authorization'] != 'Bearer token') return fail(401, 'AUTHENTICATION_REQUIRED');
          return ok(<Object>[]);
      }
      return fail(404, 'NOT_FOUND');
    });
  }

  Future<List<String>> open(WidgetTester tester, {String? at}) async {
    final calls = <String>[];
    final repo = ApiAppointmentRepository(client: ApiClient(client: fakeServer(calls)));
    final live = MockLiveLocationRepository(meId: repo.me.id);
    addTearDown(live.dispose);
    await tester.pumpWidget(GamgamApp(repository: repo, liveRepository: live, initialLocation: at));
    await tester.pumpAndSettle();
    return calls;
  }

  Finder field(String label) => find.descendant(of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first, matching: find.byType(TextField));

  /// 칸에 쓰면 그 칸이 보이도록 스크롤된다. 스크롤 중의 탭은 무시되므로 끝날 때까지 기다린다.
  Future<void> type(WidgetTester tester, Finder finder, String text) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  testWidgets('로그인하지 않았으면 로그인 화면, 틀리면 안내, 맞으면 홈', (tester) async {
    final calls = await open(tester);
    expect(find.text('Hello,\nthere.'), findsOneWidget);
    expect(calls, isNot(contains('GET /api/v1/appointments')), reason: '로그인 전에는 서버에 요청하지 않는다');

    await type(tester, field('이메일'), 'not-email');
    await type(tester, field('비밀번호'), 'password1');
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();
    expect(find.text('이메일 형식을 한 번 더 확인해 주세요'), findsOneWidget);

    await type(tester, field('이메일'), 'a@gamgam.dev');
    await type(tester, field('비밀번호'), 'wrong-pass');
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();
    expect(find.text('이메일이나 비밀번호를 다시 확인해 주세요'), findsOneWidget);

    await type(tester, field('비밀번호'), 'password1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Hello,\nthere.'), findsNothing);
    expect(find.text('Hello,\n예은.'), findsOneWidget);
    expect(calls.where((c) => c == 'GET /api/v1/appointments'), isNotEmpty, reason: '로그인하면 약속을 다시 읽는다');
  });

  testWidgets('가입하면 바로 로그인하고, 초대 링크로 왔으면 초대 화면으로 돌아간다', (tester) async {
    final calls = await open(tester, at: '/invite/BOARD');
    expect(find.text('Hello,\nthere.'), findsOneWidget);

    await tester.tap(find.textContaining('가입하기', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.text('Nice to\nmeet you.'), findsOneWidget);

    await type(tester, field('이름'), '가');
    await type(tester, field('이메일'), 'a@gamgam.dev');
    await type(tester, field('비밀번호'), 'short');
    await tester.tap(find.text('가입하기'));
    await tester.pumpAndSettle();
    expect(find.text('이름은 2자 이상으로 정해 주세요'), findsOneWidget);
    expect(find.text('비밀번호는 8자 이상으로 정해 주세요'), findsOneWidget);

    await type(tester, field('이름'), '감감');
    await type(tester, field('비밀번호'), 'password2');
    await tester.tap(find.text('가입하기'));
    await tester.pumpAndSettle();
    expect(find.text('이미 가입된 이메일이에요. 로그인해 볼까요?'), findsOneWidget);

    await type(tester, field('이메일'), 'b@gamgam.dev');
    await tester.tap(find.text('가입하기'));
    await tester.pumpAndSettle();
    expect(calls, containsAllInOrder(['POST /api/v1/auth/signup', 'POST /api/v1/auth/login']));
    expect(find.text('Nice to\nmeet you.'), findsNothing);
    expect(find.text('Hello,\nthere.'), findsNothing);
  });
}
