import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/shared/widgets/stamp_grid.dart';

void main() {
  testWidgets('fills the given number of dots and leaves the rest empty', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StampGrid(filled: 3, total: 10))),
    );

    for (var i = 0; i < 10; i++) {
      expect(find.byKey(ValueKey('stamp-dot-$i')), findsOneWidget);
    }

    Container dotAt(int i) => tester.widget<Container>(find.byKey(ValueKey('stamp-dot-$i')));
    BoxDecoration decorationAt(int i) => dotAt(i).decoration as BoxDecoration;

    expect(decorationAt(2).gradient, isNotNull);
    expect(decorationAt(3).gradient, isNull);
  });

  testWidgets('clamps filled dots to the grid total', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StampGrid(filled: 12, total: 10))),
    );

    expect(find.byKey(const ValueKey('stamp-dot-9')), findsOneWidget);
    expect(find.byKey(const ValueKey('stamp-dot-10')), findsNothing);
  });
}
