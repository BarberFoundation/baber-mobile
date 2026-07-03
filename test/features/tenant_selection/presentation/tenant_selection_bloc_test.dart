import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/core/tenancy/tenant_storage.dart';
import 'package:baber_mobile/features/tenant_selection/domain/tenant.dart';
import 'package:baber_mobile/features/tenant_selection/domain/tenant_repository.dart';
import 'package:baber_mobile/features/tenant_selection/presentation/tenant_selection_bloc.dart';
import 'package:baber_mobile/features/tenant_selection/presentation/tenant_selection_event.dart';
import 'package:baber_mobile/features/tenant_selection/presentation/tenant_selection_state.dart';

class MockTenantRepository extends Mock implements TenantRepository {}
class MockTenantStorage extends Mock implements TenantStorage {}

void main() {
  late MockTenantRepository repository;
  late MockTenantStorage storage;

  const tenant = Tenant(id: 't1', slug: 'barbearia-do-amigo', name: 'Barbearia do Amigo');

  setUp(() {
    repository = MockTenantRepository();
    storage = MockTenantStorage();
    when(() => storage.saveTenant(id: any(named: 'id'), slug: any(named: 'slug')))
        .thenAnswer((_) async {});
  });

  blocTest<TenantSelectionBloc, TenantSelectionState>(
    'emits [loading, loaded] when LoadTenants succeeds',
    build: () {
      when(() => repository.listTenants()).thenAnswer((_) async => const Right([tenant]));
      return TenantSelectionBloc(repository: repository, tenantStorage: storage);
    },
    act: (bloc) => bloc.add(LoadTenants()),
    expect: () => [
      const TenantSelectionState.loading(),
      const TenantSelectionState.loaded([tenant]),
    ],
  );

  blocTest<TenantSelectionBloc, TenantSelectionState>(
    'emits [loading, error] when LoadTenants fails',
    build: () {
      when(() => repository.listTenants())
          .thenAnswer((_) async => const Left(NetworkFailure('timeout')));
      return TenantSelectionBloc(repository: repository, tenantStorage: storage);
    },
    act: (bloc) => bloc.add(LoadTenants()),
    expect: () => [
      const TenantSelectionState.loading(),
      const TenantSelectionState.error('timeout'),
    ],
  );

  blocTest<TenantSelectionBloc, TenantSelectionState>(
    'emits [loading, resolved] when ResolveDeepLink succeeds, saves tenant',
    build: () {
      when(() => repository.findBySlug('barbearia-do-amigo'))
          .thenAnswer((_) async => const Right(tenant));
      return TenantSelectionBloc(repository: repository, tenantStorage: storage);
    },
    act: (bloc) => bloc.add(const ResolveDeepLink('barbearia-do-amigo')),
    expect: () => [
      const TenantSelectionState.loading(),
      const TenantSelectionState.resolved(tenant),
    ],
    verify: (_) {
      verify(() => storage.saveTenant(id: 't1', slug: 'barbearia-do-amigo')).called(1);
    },
  );

  blocTest<TenantSelectionBloc, TenantSelectionState>(
    'emits [loading, loaded] when SelectTenant is called, saves tenant',
    build: () {
      when(() => repository.listTenants()).thenAnswer((_) async => const Right([tenant]));
      return TenantSelectionBloc(repository: repository, tenantStorage: storage);
    },
    act: (bloc) => bloc.add(const SelectTenant(tenant)),
    expect: () => [
      const TenantSelectionState.selected(tenant),
    ],
    verify: (_) {
      verify(() => storage.saveTenant(id: 't1', slug: 'barbearia-do-amigo')).called(1);
    },
  );
}
