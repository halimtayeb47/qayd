import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/main.dart';

void main() {
  testWidgets('QaydApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QaydApp());
    expect(find.byType(QaydApp), findsOneWidget);
  });
}
