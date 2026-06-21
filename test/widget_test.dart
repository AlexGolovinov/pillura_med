import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('test harness smoke test', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('Pillura')));

    expect(find.text('Pillura'), findsOneWidget);
  });
}
