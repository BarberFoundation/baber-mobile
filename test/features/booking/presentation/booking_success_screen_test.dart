import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:baber_mobile/features/booking/presentation/booking_success_screen.dart';
import 'package:baber_mobile/shared/widgets/celebration_badge.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (context, state) => child),
            GoRoute(path: '/appointments', builder: (context, state) => const Scaffold(body: Text('appointments'))),
          ],
        ),
      );

  testWidgets('shows the celebration badge and success copy', (tester) async {
    await tester.pumpWidget(wrap(const BookingSuccessScreen()));

    expect(find.byType(CelebrationBadge), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Agendamento confirmado!'), findsOneWidget);
  });

  testWidgets('tapping "Ver minhas consultas" navigates to /appointments', (tester) async {
    await tester.pumpWidget(wrap(const BookingSuccessScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver minhas consultas'));
    await tester.pumpAndSettle();

    expect(find.text('appointments'), findsOneWidget);
  });
}
