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

    IconButton reset() =>
        tester.widget(find.widgetWithIcon(IconButton, Icons.restart_alt));
    expect(reset().onPressed, isNull);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    expect(reset().onPressed, isNotNull);

    await tester.tap(find.byTooltip('Reset'));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    expect(reset().onPressed, isNull);
  });
}
