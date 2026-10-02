import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamgam/data/models/decision_template.dart';
import 'package:gamgam/data/models/place.dart';
import 'package:gamgam/data/repositories/api_appointment_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Future<void> create(ApiAppointmentRepository repo) => repo.create(
        name: '테스트 모임',
        template: DecisionTemplate.hostDecides,
        times: [DateTime.now().add(const Duration(days: 1))],
        places: [const Place(name: '연남동')],
      );

  test('서버가 꺼져 있으면 이 기기에만 방을 만든다', () async {
    final repo = ApiAppointmentRepository(client: MockClient((_) async => throw http.ClientException('Connection refused')));
    await create(repo);
    expect(repo.myAppointments.where((a) => a.name == '테스트 모임'), hasLength(1));
  });

  test('서버가 거절하면 에러를 던진다', () async {
    final repo = ApiAppointmentRepository(client: MockClient((request) async => http.Response('{}', request.method == 'GET' ? 200 : 400)));
    await expectLater(create(repo), throwsStateError);
    expect(repo.myAppointments.where((a) => a.name == '테스트 모임'), isEmpty);
  });

  test('서버 시각은 기기 시간대로 바꾸고, 서버 약속도 초대 코드로 찾을 수 있다', () async {
    const id = '7e3fc2b8-1d84-498e-b980-d515da50f62a';
    const body = '{"success":true,"data":{"id":"$id","name":"동기 모임","template":"ALL","candidatesTime":[],'
        '"confirmedTime":"2030-01-01T19:00:00+09:00","candidatesPlace":[],"confirmedPlace":{"name":"연남동"},"status":"CONFIRMED"}}';
    final repo = ApiAppointmentRepository(
      client: MockClient((request) async => request.method == 'GET'
          ? http.Response('{"success":true,"data":[]}', 200)
          : http.Response.bytes(utf8.encode(body), 201, headers: {'content-type': 'application/json; charset=utf-8'})),
    );
    await create(repo);

    final a = repo.findById(id)!;
    expect(a.time!.isUtc, isFalse);
    expect(a.time!.isAtSameMomentAs(DateTime.parse('2030-01-01T19:00:00+09:00')), isTrue);
    expect(repo.findByInviteCode(id)?.id, id);
    expect(repo.findByInviteCode(id.toUpperCase())?.id, id);
  });
}

