import 'package:flutter_test/flutter_test.dart';
import 'package:ingon_care/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(const IngonCareApp());
    expect(find.text('IngonCare'), findsOneWidget);
  });
}
