import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamgam/app.dart';
import 'package:gamgam/data/models/live_location.dart';
import 'package:gamgam/data/repositories/mock_appointment_repository.dart';
import 'package:gamgam/data/repositories/mock_live_location_repository.dart';

void main() {
  // 와이어프레임 기준 iPhone 세로 390×844
  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.physicalSize = const Size(390 * 3, 844 * 3);
    view.devicePixelRatio = 3;
  });

  /// 당일 지도는 계속 움직이므로 pumpAndSettle 대신 시간을 조금씩 흘린다.
  Future<void> advance(WidgetTester tester, {int seconds = 1}) async {
    for (var i = 0; i < seconds * 2; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets('방 → 06 공유 범위 → 07 지도 → 08 콕 찌르기 → 09 도착 → 정산', (tester) async {
    final repo = MockAppointmentRepository();
    final live = MockLiveLocationRepository(meId: repo.me.id);
    addTearDown(live.dispose);
    await tester.pumpWidget(GamgamApp(repository: repo, liveRepository: live, initialLocation: '/appointments/a-hongdae'));
    await tester.pumpAndSettle();

    // 처음 들어가면 06 위치 공유 설정을 먼저 보여준다.
    await tester.tap(find.text('당일 지도 열기'));
    await tester.pumpAndSettle();
    expect(find.text('이 방에서 내 위치를\n어디까지 보여줄까요?'), findsOneWidget);
    await tester.tap(find.text('친한 방'));
    await tester.tap(find.text('이걸로 할게요'));
    await advance(tester);
    expect(live.shareLevelOf('a-hongdae'), ShareLevel.close);

    // 07 — 지도 밖 칩과 참여자 시트.
    expect(find.text('참여자 5명'), findsOneWidget);
    expect(find.text('민준 집에 있음 · 40분'), findsOneWidget);
    expect(find.text('하린 위치 공유 꺼짐'), findsOneWidget);
    expect(find.text('1등 🎉'), findsOneWidget);

    // 08 보내는 쪽 — 도윤에게 콕 찌르면 5분 쿨다운.
    await tester.tap(find.text('콕 찌르기').first);
    await tester.pumpAndSettle();
    expect(find.text('도윤에게 콕 찌르기'), findsOneWidget);
    await tester.tap(find.text('빨리와'));
    await advance(tester);
    expect(live.pokeCooldownOf('a-hongdae', 'u-doyun'), greaterThan(const Duration(minutes: 4)));

    // 08 받는 쪽 — 도윤이 나를 콕 찌르면 배너에서 바로 답장.
    await advance(tester, seconds: 2);
    expect(find.text('도윤님이 콕 찔렀어요 — 빨리와!'), findsOneWidget);
    await tester.tap(find.text('5분 뒤 도착'));
    await advance(tester);
    expect(find.text('도윤님이 콕 찔렀어요 — 빨리와!'), findsNothing);

    // 1초 = 1분. 약 1분 뒤 모두 도착하면 09로 넘어간다.
    await advance(tester, seconds: 60);
    await tester.pumpAndSettle();
    expect(find.text('다 모였어요!'), findsOneWidget);
    expect(find.text('민준님 12분 늦음'), findsOneWidget);
    expect(find.text('커피 사기'), findsOneWidget);

    await tester.tap(find.text('정산 완료'));
    await tester.pumpAndSettle();
    final done = repo.findById('a-hongdae')!;
    expect(done.isCompleted, isTrue);
    expect(done.lateCount, 1);
  });

  testWidgets('나중에 정하기를 누르면 저장하지 않고 지도로 가고, 다음에 다시 묻는다', (tester) async {
    final repo = MockAppointmentRepository();
    final live = MockLiveLocationRepository(meId: repo.me.id);
    addTearDown(live.dispose);
    await tester.pumpWidget(GamgamApp(repository: repo, liveRepository: live, initialLocation: '/appointments/a-hongdae'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('당일 지도 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('나중에 정하기'));
    await advance(tester);
    expect(find.text('참여자 5명'), findsOneWidget);
    expect(live.shareLevelOf('a-hongdae'), isNull);

    await tester.tap(find.byTooltip('뒤로'));
    await advance(tester);
    await tester.tap(find.text('당일 지도 열기'));
    await tester.pumpAndSettle();
    expect(find.text('이 방에서 내 위치를\n어디까지 보여줄까요?'), findsOneWidget);
  });

  test('이미 도착한 사람에게는 콕 찌르기가 가지 않는다', () async {
    final repo = MockAppointmentRepository();
    final live = MockLiveLocationRepository(meId: repo.me.id);
    addTearDown(live.dispose);
    live.start(repo.findById('a-hongdae')!);
    live.stop('a-hongdae');

    // 서아는 시작할 때 이미 도착해 있다.
    final before = live.session('a-hongdae')!.totalPokes;
    await live.poke('a-hongdae', 'u-seoa', PokeMessage.hurry);
    expect(live.pokeCooldownOf('a-hongdae', 'u-seoa'), Duration.zero);
    expect(live.session('a-hongdae')!.totalPokes, before);
  });

  testWidgets('위치 공유 시간 전인 약속은 지도를 열지 않는다', (tester) async {
    final repo = MockAppointmentRepository();
    final live = MockLiveLocationRepository(meId: repo.me.id);
    addTearDown(live.dispose);
    await live.setShareLevel('a-hiking', ShareLevel.basic);
    await tester.pumpWidget(GamgamApp(repository: repo, liveRepository: live, initialLocation: '/appointments/a-hiking/live'));
    await tester.pumpAndSettle();

    expect(find.text('아직 위치 공유 전이에요'), findsOneWidget);
    expect(live.session('a-hiking'), isNull);
  });
}
