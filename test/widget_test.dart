// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:attendancepro/main.dart';

import 'test_constants.dart';

void main() {
  testWidgets(TestStrings.counterTestDescription, (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text(TestStrings.counterInitialValue), findsOneWidget);
    expect(find.text(TestStrings.counterAfterIncrement), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text(TestStrings.counterInitialValue), findsNothing);
    expect(find.text(TestStrings.counterAfterIncrement), findsOneWidget);
  });
}
