import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/auth/token_storage.dart';
import 'package:baber_mobile/core/tenancy/tenant_storage.dart';
import 'package:baber_mobile/features/home/presentation/home_screen.dart';

class MockTokenStorage extends Mock implements TokenStorage {}
class MockTenantStorage extends Mock implements TenantStorage {}

void main() {
  late MockTokenStorage tokenStorage;
  late MockTenantStorage tenantStorage;

  setUp(() {
    tokenStorage = MockTokenStorage();
    tenantStorage = MockTenantStorage();
    when(() => tokenStorage.clear()).thenAnswer((_) async {});
    when(() => tenantStorage.clear()).thenAnswer((_) async {});
  });

  Future<GoRouter> pumpHome(WidgetTester tester, {String? userName}) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => HomeScreen(
            tokenStorage: tokenStorage,
            tenantStorage: tenantStorage,
            userName: userName,
          ),
        ),
        GoRoute(
          path: '/tenant-selection',
          builder: (context, state) => const Scaffold(body: Text('tenant selection')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    return router;
  }

  testWidgets('renders welcome text with user name', (tester) async {
    await pumpHome(tester, userName: 'João');

    expect(find.text('Bem-vindo, João'), findsOneWidget);
  });

  testWidgets('tapping logout clears storages and navigates to tenant-selection', (tester) async {
    await pumpHome(tester, userName: 'João');

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    verify(() => tokenStorage.clear()).called(1);
    verify(() => tenantStorage.clear()).called(1);
    expect(find.text('tenant selection'), findsOneWidget);
  });
}
