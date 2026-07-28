import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/shared/widgets/celebration_badge.dart';
import 'package:baber_mobile/shared/widgets/ring_confetti_overlay.dart';

void main() {
  testWidgets('renders the given child badge over the ring/confetti overlay', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: CelebrationBadge(child: Icon(Icons.check)))),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byType(RingConfettiOverlay), findsOneWidget);
  });

  testWidgets('bounce-in and overlay are one-shot and settle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: CelebrationBadge(child: Icon(Icons.check)))),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
