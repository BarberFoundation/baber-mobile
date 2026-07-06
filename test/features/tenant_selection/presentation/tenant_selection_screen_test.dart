import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/features/tenant_selection/domain/tenant.dart';
import 'package:baber_mobile/features/tenant_selection/presentation/tenant_selection_bloc.dart';
import 'package:baber_mobile/features/tenant_selection/presentation/tenant_selection_event.dart';
import 'package:baber_mobile/features/tenant_selection/presentation/tenant_selection_screen.dart';
import 'package:baber_mobile/features/tenant_selection/presentation/tenant_selection_state.dart';

class MockTenantSelectionBloc extends MockBloc<TenantSelectionEvent, TenantSelectionState>
    implements TenantSelectionBloc {}

void main() {
  late MockTenantSelectionBloc bloc;

  setUpAll(() {
    registerFallbackValue(LoadTenants());
    registerFallbackValue(
      const SelectTenant(Tenant(id: 't1', slug: 's', name: 'n')),
    );
  });

  setUp(() {
    bloc = MockTenantSelectionBloc();
  });

  Widget wrap(Widget child) => MaterialApp(
        home: BlocProvider<TenantSelectionBloc>.value(value: bloc, child: child),
      );

  testWidgets('dispatches LoadTenants on init', (tester) async {
    whenListen(bloc, const Stream<TenantSelectionState>.empty(), initialState: const TenantSelectionState.initial());

    await tester.pumpWidget(wrap(const TenantSelectionScreen()));

    verify(() => bloc.add(LoadTenants())).called(1);
  });

  testWidgets('shows spinner while loading', (tester) async {
    whenListen(bloc, const Stream<TenantSelectionState>.empty(), initialState: const TenantSelectionState.loading());

    await tester.pumpWidget(wrap(const TenantSelectionScreen()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders tenant list and dispatches SelectTenant on tap', (tester) async {
    const tenant = Tenant(id: 't1', slug: 'barbearia-do-amigo', name: 'Barbearia do Amigo');
    whenListen(
      bloc,
      const Stream<TenantSelectionState>.empty(),
      initialState: const TenantSelectionState.loaded([tenant]),
    );

    await tester.pumpWidget(wrap(const TenantSelectionScreen()));
    await tester.tap(find.text('Barbearia do Amigo'));

    verify(() => bloc.add(const SelectTenant(tenant))).called(1);
  });

  testWidgets('shows error SnackBar when errorMessage present', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable([const TenantSelectionState.error('falha ao carregar')]),
      initialState: const TenantSelectionState.initial(),
    );

    await tester.pumpWidget(wrap(const TenantSelectionScreen()));
    await tester.pump();

    expect(find.text('falha ao carregar'), findsOneWidget);
  });
}
