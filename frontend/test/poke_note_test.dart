import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamgam/data/models/poke_note.dart';
import 'package:gamgam/features/poke/poke_note_page.dart';

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.physicalSize = const Size(390 * 3, 844 * 3);
    view.devicePixelRatio = 3;
  });

  /// 쪽지 화면을 열고, 보내면 돌려받은 쪽지를 [sent]에 담는다.
  Future<List<PokeNote?>> open(WidgetTester tester) async {
    final sent = <PokeNote?>[];
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(onPressed: () async => sent.add(await showPokeNotePage(context)), child: const Text('열기')),
      ),
    ));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    return sent;
  }

  Future<void> tapLabel(WidgetTester tester, String label) async {
    await tester.tap(find.bySemanticsLabel(label));
    await tester.pumpAndSettle();
  }

  testWidgets('카드·문구·스티커를 고르면 그대로 보낸다', (tester) async {
    final sent = await open(tester);
    expect(find.text('보내기'), findsNothing);

    await tapLabel(tester, '카드 디자인');
    await tapLabel(tester, '하트');
    await tapLabel(tester, '문구');
    await tapLabel(tester, '너 지금 납치됐어?');
    await tapLabel(tester, '이모지');
    await tapLabel(tester, '네잎클로버');

    await tester.tap(find.text('보내기'));
    await tester.pumpAndSettle();
    final note = sent.single!;
    expect(note.card, NoteCard.heart);
    expect(note.text, '너 지금\n납치됐어?');
    expect(note.stickers.single.sticker, NoteSticker.clover);
    expect(note.stickers.single.scale, closeTo(0.7, 0.001));
  });

  testWidgets('스티커를 끌면 옮겨지고, 휴지통을 누르면 지워진다', (tester) async {
    final sent = await open(tester);
    await tapLabel(tester, '이모지');
    await tapLabel(tester, '무지개');
    expect(find.text('x 0.7'), findsOneWidget);
    expect(find.text('보내기'), findsOneWidget);

    // 빈 곳을 누르면 선택이 풀리고, 스티커를 누르면 다시 선택된다.
    await tester.tapAt(const Offset(20, 400));
    await tester.pumpAndSettle();
    expect(find.text('x 0.7'), findsNothing);

    await tester.drag(find.bySemanticsLabel('무지개 스티커'), const Offset(-40, 0));
    await tester.pumpAndSettle();
    expect(find.text('x 0.7'), findsOneWidget);

    await tapLabel(tester, '스티커 삭제');
    expect(find.text('x 0.7'), findsNothing);
    expect(find.text('보내기'), findsNothing);

    // 다시 붙여서 옮긴 뒤 보내면 옮긴 위치가 담긴다.
    await tapLabel(tester, '이모지');
    await tapLabel(tester, '무지개');
    await tester.tapAt(const Offset(20, 400));
    await tester.pumpAndSettle();
    await tester.drag(find.bySemanticsLabel('무지개 스티커'), const Offset(-47.4, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('보내기'));
    await tester.pumpAndSettle();
    // 처음 자리 0.74에서 카드 폭(237)의 1/5만큼 왼쪽으로. 끌기 시작 판정 거리만큼은 덜 움직일 수 있다.
    expect(sent.single!.stickers.single.dx, closeTo(0.54, 0.06));
  });

  testWidgets('이모지 시트는 위로 밀면 끝까지 펼쳐지고, 아래로 밀면 내려간다', (tester) async {
    await open(tester);
    await tapLabel(tester, '이모지');
    final sheet = find.bySemanticsLabel('이모지');
    final collapsedTop = tester.getTopLeft(sheet).dy;

    await tester.fling(sheet, const Offset(0, -200), 1500);
    await tester.pumpAndSettle();
    final expandedTop = tester.getTopLeft(sheet).dy;
    expect(expandedTop, lessThan(collapsedTop - 200));

    await tester.fling(sheet, const Offset(0, 200), 1500);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(sheet).dy, closeTo(collapsedTop, 1));
  });

  testWidgets('X를 누르면 아무것도 보내지 않는다', (tester) async {
    final sent = await open(tester);
    await tapLabel(tester, '문구');
    await tapLabel(tester, '어디쯤이야?');
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(sent.single, isNull);
  });
}
