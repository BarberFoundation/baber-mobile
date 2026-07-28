import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/shared/widgets/ring_confetti_overlay.dart';

void main() {
  testWidgets('renders two CustomPaint layers (rings + confetti) sized to the given box', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: RingConfettiOverlay(size: 160))),
    );

    expect(find.byType(CustomPaint), findsWidgets);
    final size = tester.getSize(find.byType(RingConfettiOverlay));
    expect(size.width, 160);
    expect(size.height, 160);
  });

  testWidgets('is a one-shot animation that settles (does not hang pumpAndSettle)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: RingConfettiOverlay(size: 160))),
    );

    await tester.pumpAndSettle();

    expect(find.byType(RingConfettiOverlay), findsOneWidget);
  });

  testWidgets('does not intercept taps (ignores pointer events)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: RingConfettiOverlay(size: 160))),
    );

    final ignorePointer = tester.widget<IgnorePointer>(
      find.descendant(of: find.byType(RingConfettiOverlay), matching: find.byType(IgnorePointer)),
    );
    expect(ignorePointer.ignoring, isTrue);
  });
}
