import 'package:flutter_test/flutter_test.dart';
import 'package:onbuch/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OnBuchApp());
    expect(find.byType(OnBuchApp), findsOneWidget);
  });
}
