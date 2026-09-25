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
}
