import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/auth/token_storage.dart';
import 'package:baber_mobile/core/tenancy/tenant_storage.dart';
import 'package:baber_mobile/features/splash/presentation/initial_route_resolver.dart';
import 'package:baber_mobile/features/splash/presentation/splash_screen.dart';
import 'package:baber_mobile/features/tenant_selection/domain/tenant_repository.dart';
import 'package:baber_mobile/shared/widgets/stripe_bar.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

class MockTenantStorage extends Mock implements TenantStorage {}

class MockTenantRepository extends Mock implements TenantRepository {}

class MockAppLinks extends Mock implements AppLinks {}

void main() {
  testWidgets('renders wordmark, stripe mark, and three loading dots', (tester) async {
    final tenantStorage = MockTenantStorage();
    // Never resolves — keeps the splash visuals on screen for the assertions below.
    when(() => tenantStorage.readTenantId()).thenAnswer((_) => Completer<String?>().future);

    final resolver = InitialRouteResolver(
      tokenStorage: MockTokenStorage(),
      tenantStorage: tenantStorage,
      tenantRepository: MockTenantRepository(),
      appLinks: MockAppLinks(),
    );

    await tester.pumpWidget(MaterialApp(home: SplashScreen(resolver: resolver)));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('BABER'), findsOneWidget);
    expect(find.byType(StripeBar), findsOneWidget);
    expect(find.byKey(const ValueKey('splash-dot-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('splash-dot-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('splash-dot-2')), findsOneWidget);
  });
}
