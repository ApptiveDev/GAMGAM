import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamgam/app.dart';
import 'package:gamgam/data/models/appointment.dart';
import 'package:gamgam/data/repositories/mock_appointment_repository.dart';
import 'package:gamgam/data/repositories/mock_live_location_repository.dart';

void main() {
  // Figma 기준 360×760
  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.physicalSize = const Size(360 * 3, 760 * 3);
    view.devicePixelRatio = 3;
  });

  Future<MockAppointmentRepository> open(WidgetTester tester, {String? at}) async {
    final repo = MockAppointmentRepository();
    final live = MockLiveLocationRepository(meId: repo.me.id);
    addTearDown(live.dispose);
    await tester.pumpWidget(GamgamApp(repository: repo, liveRepository: live, initialLocation: at));
    await tester.pump(const Duration(milliseconds: 300));
    return repo;
  }

  /// 목업 저장소의 쓰기에는 250ms 지연이 있다. pumpAndSettle은 타이머를 기다리지 않으므로 먼저 시간을 흘린다.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).first);
    await settle(tester);
  }

  testWidgets('홈: 인사, 가장 가까운 약속 카운트다운, 내 약속 카드', (tester) async {
    await open(tester);

    expect(find.text('Hello,\n예은.'), findsOneWidget);
    expect(find.text('약속까지'), findsNothing, reason: '약속 이름과 한 줄로 붙어 있다');
    expect(find.textContaining('홍대 저녁 모임'), findsWidgets);
    expect(find.text('토요일 등산'), findsOneWidget);
    // 내가 참여하지 않은 약속은 안 보인다.
    expect(find.text('금요일 보드게임'), findsNothing);
  });

  testWidgets('그룹 탭 → 앱티브 → 필터와 검색', (tester) async {
    await open(tester);

    await tester.tap(find.bySemanticsLabel('그룹'));
    await tester.pumpAndSettle();
    expect(find.text('약속 7건'), findsOneWidget);
    expect(find.text('test'), findsOneWidget);

    await tester.tap(find.text('앱티브'));
    await tester.pumpAndSettle();
    expect(find.text('전체  7'), findsOneWidget);
    expect(find.text('약속 전  5'), findsOneWidget);
    expect(find.text('약속 완료  2'), findsOneWidget);

    await tapText(tester, '약속 완료  2');
    expect(find.text('한강 피크닉'), findsOneWidget);
    expect(find.text('동기 모임'), findsNothing);

    await tester.tap(find.byTooltip('검색'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '야르');
    await tester.pumpAndSettle();
    expect(find.text('야르와(과) 일치하는 결과 없음'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '동기');
    await tester.pumpAndSettle();
    expect(find.text('동기 모임'), findsOneWidget);
  });

  testWidgets('그룹 만들기 → 약속 만들기 → 시간 후보 → 투표 → 투표 종료', (tester) async {
    final repo = await open(tester, at: '/groups');

    await tester.tap(find.byTooltip('그룹 만들기'));
    await tester.pumpAndSettle();
    expect(find.text('그룹 이름을 지정하세요'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '스터디');
    await tester.pump();
    await tester.tap(find.text('만들기'));
    await settle(tester);
    expect(find.text('스터디'), findsOneWidget);
    expect(find.text('전체  0'), findsOneWidget);

    await tester.tap(find.byTooltip('약속 만들기'));
    await tester.pumpAndSettle();
    expect(find.text('약속 이름을 지정하세요'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '중간고사 회의');
    await tester.pump();
    await tester.tap(find.text('만들기'));
    await settle(tester);

    // 약속 생성 초기화면
    expect(find.text('언제로 할까요?'), findsOneWidget);
    expect(find.text('어디서 만날까요?'), findsOneWidget);
    expect(find.text('조율중'), findsOneWidget);

    await tester.tap(find.text('시간 정하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('후보 추가'));
    await settle(tester);
    final created = repo.myAppointments.firstWhere((a) => a.name == '중간고사 회의');
    expect(created.timeOptions, hasLength(1));

    // 고르기 전에는 투표할 수 없다.
    await tester.tap(find.text('투표하기'));
    await tester.pump();
    expect(repo.findById(created.id)!.timeOptions.first.voteCount, 0);

    await tester.tap(find.textContaining('오후 7:00'));
    await tester.pump();
    await tester.tap(find.text('투표하기'));
    await tester.pumpAndSettle();
    expect(find.text('1명'), findsOneWidget);
    expect(find.text('모두 투표 완료했어요'), findsOneWidget);

    await tapText(tester, '투표 종료하기');
    final closed = repo.findById(created.id)!;
    expect(closed.confirmedTime, isNotNull);
    expect(closed.status, AppointmentStatus.coordinating, reason: '장소가 아직 안 정해졌다');
    expect(find.text('어디서 만날까요?'), findsOneWidget);
  });

  testWidgets('장소 투표 → 확정되면 확정 화면', (tester) async {
    final repo = await open(tester, at: '/appointments/a-donggi');

    await tester.scrollUntilVisible(find.text('추천 장소'), 300);
    expect(find.text('추천 장소'), findsOneWidget);
    await tapText(tester, '성수다락');
    await tapText(tester, '투표하기');
    expect(repo.findById('a-donggi')!.placeOptions.first.votedBy(repo.me.id), isTrue);

    // 시간 → 장소 순서로 투표를 끝낸다.
    await tapText(tester, '투표 종료하기');
    await tapText(tester, '투표 종료하기');

    final a = repo.findById('a-donggi')!;
    expect(a.isConfirmed, isTrue);
    expect(find.text('확정'), findsOneWidget);
    expect(find.text('대한민국 서울특별시 성동구 뚝섬로9길 20, 2층'), findsOneWidget);
    expect(find.text('추천 장소', skipOffstage: false), findsNothing);
  });

  testWidgets('위치 공유 시간이 된 약속은 지도 버튼과 남은 시간을 보여준다', (tester) async {
    await open(tester, at: '/appointments/a-hongdae');

    expect(find.text('지도에서 보기'), findsOneWidget);
    expect(find.text('Time Left'), findsOneWidget);
    expect(find.text('총 8명'), findsOneWidget);
    expect(find.text('이몸 도착 완료'), findsOneWidget);
  });

  testWidgets('약속 이름 변경', (tester) async {
    final repo = await open(tester, at: '/appointments/a-seongsu');

    await tester.tap(find.text('변경'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '성수 점심');
    await tester.pump();
    await tester.tap(find.text('변경'));
    await settle(tester);
    expect(repo.findById('a-seongsu')!.name, '성수 점심');
    expect(find.text('성수 점심'), findsOneWidget);
  });
}
