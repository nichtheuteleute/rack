import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rack_example/main.dart';

void main() {
  testWidgets('shows loading, then the restored counter, then increments',
      (tester) async {
    await tester.pumpWidget(const App());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });
}
