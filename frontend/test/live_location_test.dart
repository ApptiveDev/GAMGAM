import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamgam/app.dart';
import 'package:gamgam/data/models/live_location.dart';
import 'package:gamgam/data/models/poke_note.dart';
import 'package:gamgam/data/repositories/mock_appointment_repository.dart';
import 'package:gamgam/data/repositories/mock_live_location_repository.dart';
import 'package:gamgam/features/live_map/widgets/person_card.dart';
import 'package:gamgam/features/poke/widgets/received_note.dart';

/// 테스트는 "1초 = 1분" 기준으로 시간을 흘린다. (목업 기본값은 2초 = 1분)
const _tick = Duration(milliseconds: 500);

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
    final live = MockLiveLocationRepository(meId: repo.me.id, tick: _tick);
    addTearDown(live.dispose);
    await tester.pumpWidget(GamgamApp(repository: repo, liveRepository: live, initialLocation: '/appointments/a-hongdae'));
    await tester.pumpAndSettle();

    // 처음 들어가면 06 위치 공유 설정을 먼저 보여준다.
    await tester.tap(find.text('지도에서 보기'));
    await tester.pumpAndSettle();
    expect(find.text('이 방에서 내 위치를\n어디까지 보여줄까요?'), findsOneWidget);
    await tester.tap(find.text('친한 방'));
    await tester.tap(find.text('이걸로 할게요'));
    await advance(tester);
    expect(live.shareLevelOf('a-hongdae'), ShareLevel.close);

    // 07 — 하단 도착 현황. 지도에 없는 사람(출발 전·공유 꺼짐)도 목록에 상태로 보인다.
    expect(find.text('약속까지'), findsOneWidget);
    expect(find.text('총 ${live.session('a-hongdae')!.participants.length}명'), findsOneWidget);
    expect(find.text('집에 있음'), findsWidgets);
    expect(find.text('위치 공유 꺼짐'), findsOneWidget);
    expect(find.text('1등 🎉'), findsOneWidget);

    // 08 보내는 쪽 — 목록에서 도윤에게 콕 찌르면 5분 쿨다운.
    final pokeDoyun = find.descendant(of: find.ancestor(of: find.text('도윤'), matching: find.byType(Row)), matching: find.text('콕 찌르기')).first;
    await tester.ensureVisible(pokeDoyun);
    await tester.pump();
    await tester.tap(pokeDoyun);
    await tester.pumpAndSettle();

    // 쪽지 꾸미기 — 문구를 고르면 보내기가 생긴다.
    expect(find.text('보내기'), findsNothing);
    await tester.tap(find.bySemanticsLabel('문구'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('어디쯤이야?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('보내기'));
    // pumpAndSettle은 "완료하는 중" 막대가 끝날 때까지 기다리므로 화면 전환만큼만 흘린다.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // "완료하는 중" 동안은 아직 안 보냈고, 막대가 다 차면 보낸다.
    expect(find.text('완료하는 중'), findsOneWidget);
    expect(live.pokeCooldownOf('a-hongdae', 'u-doyun'), Duration.zero);
    await advance(tester, seconds: 4);
    expect(find.text('콕 찌르기를 전송했습니다'), findsOneWidget);
    expect(live.pokeCooldownOf('a-hongdae', 'u-doyun'), greaterThan(const Duration(minutes: 4)));

    // 08 받는 쪽 — 친구가 나를 콕 찌르면 봉투가 떨어져 열리고 쪽지가 보인다. 누르면 닫힌다.
    final received = find.byType(ReceivedNoteOverlay);
    expect(find.bySemanticsLabel(RegExp('님이 보낸 쪽지')), findsOneWidget);
    await advance(tester, seconds: 2);
    expect(find.text('어디쯤이야?'), findsOneWidget);
    await tester.tap(received);
    await advance(tester);
    expect(received, findsNothing);

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
    final live = MockLiveLocationRepository(meId: repo.me.id, tick: _tick);
    addTearDown(live.dispose);
    await tester.pumpWidget(GamgamApp(repository: repo, liveRepository: live, initialLocation: '/appointments/a-hongdae'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('지도에서 보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('나중에 정하기'));
    await advance(tester);
    expect(find.text('약속까지'), findsOneWidget);
    expect(live.shareLevelOf('a-hongdae'), isNull);

    await tester.tap(find.byTooltip('닫기'));
    await advance(tester);
    await tester.tap(find.text('지도에서 보기'));
    await tester.pumpAndSettle();
    expect(find.text('이 방에서 내 위치를\n어디까지 보여줄까요?'), findsOneWidget);
  });

  /// 공유 범위를 고른 채로 당일 지도를 바로 연다. 시간은 흐르지 않게 멈춰 둔다.
  Future<MockLiveLocationRepository> openFrozenMap(WidgetTester tester) async {
    final repo = MockAppointmentRepository();
    final live = MockLiveLocationRepository(meId: repo.me.id, tick: const Duration(hours: 1));
    addTearDown(live.dispose);
    await live.setShareLevel('a-hongdae', ShareLevel.close);
    await tester.pumpWidget(GamgamApp(repository: repo, liveRepository: live, initialLocation: '/appointments/a-hongdae/live'));
    await advance(tester);
    return live;
  }

  testWidgets('지도에서 마커를 누르면 그 사람 카드가 뜨고, 빈 곳을 누르면 닫힌다', (tester) async {
    await openFrozenMap(tester);
    expect(find.byType(PersonCard), findsNothing);

    // 지도가 Stack 맨 아래라 첫 번째 '도윤'이 마커 라벨이다.
    await tester.tap(find.text('도윤').first);
    await advance(tester);
    expect(find.descendant(of: find.byType(PersonCard), matching: find.text('도윤')), findsOneWidget);
    // 상태 메시지는 카드와 프로필 줄 말풍선 두 곳에 보인다.
    expect(find.text('오는 길에 음료 사줄사람 사례해드림'), findsNWidgets(2));

    await tester.tapAt(const Offset(30, 420));
    await advance(tester);
    expect(find.byType(PersonCard), findsNothing);
    expect(find.text('오는 길에 음료 사줄사람 사례해드림'), findsOneWidget);
  });

  testWidgets('시트를 끝까지 올리면 전체 화면이 되고, ←를 누르면 지도로 돌아온다', (tester) async {
    await openFrozenMap(tester);
    expect(find.byTooltip('지도 보기'), findsNothing);

    await tester.fling(find.text('약속까지'), const Offset(0, -2000), 3000);
    await advance(tester, seconds: 2);
    expect(find.byTooltip('지도 보기'), findsOneWidget);
    expect(find.byTooltip('닫기').hitTestable(), findsNothing);

    await tester.tap(find.byTooltip('지도 보기'));
    await advance(tester);
    expect(find.byTooltip('지도 보기'), findsNothing);
    expect(find.byTooltip('닫기').hitTestable(), findsOneWidget);
    expect(find.text('약속까지').hitTestable(), findsOneWidget);
  });

  testWidgets('쪽지를 보낸 뒤 "완료하는 중"에 취소하면 보내지 않는다', (tester) async {
    final live = await openFrozenMap(tester);
    final pokeDoyun = find.descendant(of: find.ancestor(of: find.text('도윤'), matching: find.byType(Row)), matching: find.text('콕 찌르기')).first;
    await tester.ensureVisible(pokeDoyun);
    await tester.pump();
    await tester.tap(pokeDoyun);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('문구'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('어디쯤이야?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('보내기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('취소'));
    await advance(tester, seconds: 4);
    expect(find.text('완료하는 중'), findsNothing);
    expect(find.text('콕 찌르기를 전송했습니다'), findsNothing);
    expect(live.pokeCooldownOf('a-hongdae', 'u-doyun'), Duration.zero);
  });

  test('이미 도착한 사람에게는 콕 찌르기가 가지 않는다', () async {
    final repo = MockAppointmentRepository();
    final live = MockLiveLocationRepository(meId: repo.me.id, tick: _tick);
    addTearDown(live.dispose);
    live.start(repo.findById('a-hongdae')!);
    live.stop('a-hongdae');

    // 서아는 시작할 때 이미 도착해 있다.
    final before = live.session('a-hongdae')!.totalPokes;
    await live.poke('a-hongdae', 'u-seoa', const PokeNote(text: '어디쯤이야?'));
    expect(live.pokeCooldownOf('a-hongdae', 'u-seoa'), Duration.zero);
    expect(live.session('a-hongdae')!.totalPokes, before);
  });

  testWidgets('위치 공유 시간 전인 약속은 지도를 열지 않는다', (tester) async {
    final repo = MockAppointmentRepository();
    final live = MockLiveLocationRepository(meId: repo.me.id, tick: _tick);
    addTearDown(live.dispose);
    await live.setShareLevel('a-hiking', ShareLevel.basic);
    await tester.pumpWidget(GamgamApp(repository: repo, liveRepository: live, initialLocation: '/appointments/a-hiking/live'));
    await tester.pumpAndSettle();

    expect(find.text('아직 위치 공유 전이에요'), findsOneWidget);
    expect(live.session('a-hiking'), isNull);
  });
}
