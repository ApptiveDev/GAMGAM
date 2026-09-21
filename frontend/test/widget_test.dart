import 'package:flutter_test/flutter_test.dart';
import 'package:gamgam/app.dart';

void main() {
  testWidgets('shows the app title', (tester) async {
    await tester.pumpWidget(const GamgamApp());

    expect(find.text('GAMGAM'), findsOneWidget);
  });
}
