import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/auth/session_cubit.dart';
import 'package:baber_mobile/core/auth/token_storage.dart';
import 'package:baber_mobile/core/tenancy/tenant_storage.dart';
import 'package:baber_mobile/features/auth/domain/auth_repository.dart';
import 'package:baber_mobile/features/auth/domain/auth_user.dart';
import 'package:baber_mobile/features/profile/domain/profile_repository.dart';
import 'package:baber_mobile/features/profile/presentation/profile_screen.dart';
import 'package:baber_mobile/shared/theme/app_theme.dart';
import 'package:baber_mobile/shared/theme/theme_cubit.dart';
import 'package:baber_mobile/shared/theme/theme_storage.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockTokenStorage extends Mock implements TokenStorage {}
class MockTenantStorage extends Mock implements TenantStorage {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockThemeStorage extends Mock implements ThemeStorage {}

void main() {
  late MockProfileRepository profileRepository;
  late MockTokenStorage tokenStorage;
  late MockTenantStorage tenantStorage;
  late MockAuthRepository authRepository;
  late MockThemeStorage themeStorage;

  const user = AuthUser(id: 'u1', name: 'João', phone: '11999998888', email: 'joao@x.com', cpf: '11144477735');

  setUp(() {
    profileRepository = MockProfileRepository();
    tokenStorage = MockTokenStorage();
    tenantStorage = MockTenantStorage();
    authRepository = MockAuthRepository();
    themeStorage = MockThemeStorage();
    when(() => profileRepository.getMe()).thenAnswer((_) async => const Right(user));
    when(() => tokenStorage.clear()).thenAnswer((_) async {});
    when(() => tenantStorage.clear()).thenAnswer((_) async {});
    when(() => authRepository.signOut()).thenAnswer((_) async {});
    when(() => themeStorage.readMode()).thenAnswer((_) async => null);
    when(() => themeStorage.saveMode(any())).thenAnswer((_) async {});
  });

  Future<void> pumpProfile(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => SessionCubit(
                  tokenStorage: tokenStorage,
                  tenantStorage: tenantStorage,
                  authRepository: authRepository,
                ),
              ),
              BlocProvider(create: (_) => ThemeCubit(storage: themeStorage)),
            ],
            child: ProfileScreen(profileRepository: profileRepository),
          ),
        ),
        GoRoute(path: '/tenant-selection', builder: (context, state) => const Scaffold(body: Text('tenant selection'))),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router, theme: AppTheme.dark));
  }

  testWidgets('loads and shows the current profile data', (tester) async {
    await pumpProfile(tester);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Nome').evaluate().single.widget, isA<TextFormField>());
    expect(find.text('João'), findsOneWidget);
    expect(find.text('11999998888'), findsOneWidget);
    expect(find.text('joao@x.com'), findsOneWidget);
    expect(find.text('11144477735'), findsOneWidget);
  });

  testWidgets('saving submits the edited fields via updateProfile', (tester) async {
    when(() => profileRepository.updateProfile(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          email: any(named: 'email'),
          cpf: any(named: 'cpf'),
        )).thenAnswer((_) async => const Right(user));

    await pumpProfile(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome'), 'João Novo');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    verify(() => profileRepository.updateProfile(
          name: 'João Novo',
          phone: '11999998888',
          email: 'joao@x.com',
          cpf: '11144477735',
        )).called(1);
    expect(find.text('Dados salvos.'), findsOneWidget);
  });

  testWidgets('rejects an invalid CPF/CNPJ before saving', (tester) async {
    await pumpProfile(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'CPF ou CNPJ'), '123');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    verifyNever(() => profileRepository.updateProfile(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          email: any(named: 'email'),
          cpf: any(named: 'cpf'),
        ));
    expect(find.text('CPF ou CNPJ inválido'), findsOneWidget);
  });

  testWidgets('tapping logout clears storages and navigates to tenant-selection', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpProfile(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    verify(() => tokenStorage.clear()).called(1);
    verify(() => tenantStorage.clear()).called(1);
    expect(find.text('tenant selection'), findsOneWidget);
  });
}
