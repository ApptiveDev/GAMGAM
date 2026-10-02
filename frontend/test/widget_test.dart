import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamgam/app.dart';
import 'package:gamgam/data/repositories/mock_appointment_repository.dart';

void main() {
  // 와이어프레임 기준 iPhone 세로 390×844
  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.physicalSize = const Size(390 * 3, 844 * 3);
    view.devicePixelRatio = 3;
  });
  testWidgets('홈에 내 약속이 보인다', (tester) async {
    await tester.pumpWidget(GamgamApp(repository: MockAppointmentRepository()));
    await tester.pump();

    expect(find.text('내 약속'), findsOneWidget);
    expect(find.text('홍대 저녁 모임'), findsOneWidget);
    expect(find.text('동기 모임'), findsOneWidget);
    // 내가 참여하지 않은 방은 안 보인다.
    expect(find.text('금요일 보드게임'), findsNothing);
  });

  testWidgets('약속 만들기 → 방 → 벌칙 → 확정', (tester) async {
    final repo = MockAppointmentRepository();
    await tester.pumpWidget(GamgamApp(repository: repo));
    await tester.pump();

    await tester.tap(find.text('약속 만들기'));
    await tester.pumpAndSettle();
    expect(find.text('어떻게 정할까요?'), findsOneWidget);

    await tester.tap(find.text('장소만 투표'));
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '테스트 모임');
    await tester.pump();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    // 날짜·시간 피커는 기본값 그대로 확인.
    await tester.tap(find.text('+ 날짜·시간 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    for (final place in ['연남동', '망원동']) {
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), place);
      await tester.tap(find.text('추가'));
      await tester.pump();
    }

    // 투표가 있으면 마감 기한이 있어야 방을 만들 수 있다. 기본값(첫 시간 2시간 전) 그대로.
    await tester.ensureVisible(find.text('+ 마감 기한 선택'));
    await tester.tap(find.text('+ 마감 기한 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.textContaining('까지'), findsOneWidget);

    await tester.tap(find.text('방 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('테스트 모임'), findsOneWidget);
    expect(find.text('장소 투표'), findsOneWidget);

    await tester.ensureVisible(find.text('연남동'));
    await tester.tap(find.text('연남동'));
    await tester.pump();
    await tester.tap(find.text('확정하기'));
    await tester.pumpAndSettle();
    expect(find.text('늦으면 어떻게 할까요?'), findsOneWidget);

    await tester.tap(find.text('이대로 확정'));
    await tester.pumpAndSettle();
    expect(find.text('약속이 확정됐어요'), findsOneWidget);

    final created = repo.myAppointments.firstWhere((a) => a.name == '테스트 모임');
    expect(created.isConfirmed, isTrue);
    expect(created.place?.name, '연남동');
    expect(created.voteDeadline!.isBefore(created.time!), isTrue);
  });

  testWidgets('초대 코드로 방에 참여한다', (tester) async {
    final repo = MockAppointmentRepository();
    await tester.pumpWidget(GamgamApp(repository: repo, initialLocation: '/invite/BOARD'));
    await tester.pumpAndSettle();

    expect(find.text('금요일 보드게임'), findsOneWidget);
    await tester.tap(find.text('참여하기'));
    await tester.pumpAndSettle();

    expect(find.text('시간 투표'), findsOneWidget);
    expect(repo.findById('a-board')!.hasMember(repo.me.id), isTrue);
  });

  testWidgets('웹 초대 링크: 이름 입력 → 같은 이름이면 번호 → 투표', (tester) async {
    final repo = MockAppointmentRepository();
    await tester.pumpWidget(GamgamApp(repository: repo, initialLocation: '/invite/DONGGI', webInvite: true));
    await tester.pumpAndSettle();

    expect(find.text('예은님이\n약속에 초대했어요'), findsOneWidget);
    expect(find.text('참여자 4명'), findsOneWidget);

    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '도윤');
    await tester.pump();
    await tester.tap(find.text('참여하고 투표하기'));
    await tester.pumpAndSettle();

    final guest = repo.guestOf('a-donggi')!;
    expect(guest.name, '도윤(2)');
    expect(guest.hasApp, isFalse);
    expect(find.text('도윤(2)님으로 참여 중'), findsOneWidget);
    expect(find.text('같은 이름이 있어서 도윤(2)(으)로 참여했어요'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('망원 시장 골목'), 200);
    await tester.tap(find.text('망원 시장 골목'));
    await tester.pump();
    final a = repo.findById('a-donggi')!;
    expect(a.placeOptions.firstWhere((o) => o.id == 'p2').votedBy(guest.id), isTrue);
    // 로그인한 나(예은)의 표는 그대로.
    expect(a.placeOptions.firstWhere((o) => o.id == 'p1').votedBy(repo.me.id), isTrue);
  });

  testWidgets('웹 초대 링크: 확정된 약속은 확정 정보와 앱 설치 버튼', (tester) async {
    final repo = MockAppointmentRepository();
    await tester.pumpWidget(GamgamApp(repository: repo, initialLocation: '/invite/HONGDAE', webInvite: true));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '지수');
    await tester.pump();
    await tester.tap(find.text('참여하기'));
    await tester.pumpAndSettle();

    expect(find.text('약속이 확정됐어요'), findsOneWidget);
    expect(find.text('연남동 소금집 델리 · 홍대입구역 3번 출구'), findsOneWidget);
    expect(find.text('참여자 6명'), findsOneWidget);
    await tester.tap(find.text('앱 설치하러 가기'));
    await tester.pump();
    expect(find.text('아직 스토어에 출시 전이에요. 조금만 기다려주세요'), findsOneWidget);
  });

  testWidgets('투표 마감이 지나면 방에서 투표가 막힌다', (tester) async {
    // 목업 날짜를 5일 전 기준으로 만들면 동기 모임 마감(+3일)이 이미 지나 있다.
    final repo = MockAppointmentRepository(now: DateTime.now().subtract(const Duration(days: 5)));
    await tester.pumpWidget(GamgamApp(repository: repo, initialLocation: '/appointments/a-donggi'));
    await tester.pumpAndSettle();

    expect(find.text('투표가 마감됐어요. 방장이 확정하면 알려드릴게요'), findsOneWidget);
    expect(find.text('+ 다른 시간 제안하기'), findsNothing);
    await tester.scrollUntilVisible(find.text('망원 시장 골목'), 200);
    await tester.tap(find.text('망원 시장 골목'));
    await tester.pump();
    expect(repo.findById('a-donggi')!.placeOptions.firstWhere((o) => o.id == 'p2').voteCount, 0);
  });

  test('같은 이름은 (2), (3) 순서로 번호를 붙인다', () async {
    final repo = MockAppointmentRepository();
    final first = await repo.joinAsGuest('a-board', '서아');
    expect(first.name, '서아(2)');
    // 다른 브라우저에서 들어온 것처럼 목록에 같은 이름이 하나 더 있을 때.
    final a = repo.findById('a-board')!;
    expect(a.uniqueName('서아'), '서아(3)');
    expect(a.uniqueName('민수'), '민수');
  });
}
