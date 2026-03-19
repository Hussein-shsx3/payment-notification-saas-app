// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/main.dart';

void main() {
  testWidgets('App boots (smoke test)', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Avoid pumpAndSettle here: the app may have ongoing animations/timers
    // (e.g. auth initialization) which would never "settle" in a unit test.
    await tester.pump(const Duration(milliseconds: 100));

    // Ensures the widget tree builds without throwing.
    expect(find.byType(MyApp), findsOneWidget);
  });
}
