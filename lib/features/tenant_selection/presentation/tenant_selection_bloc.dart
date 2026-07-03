import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failure_message.dart';
import '../../../core/tenancy/tenant_storage.dart';
import '../domain/tenant_repository.dart';
import 'tenant_selection_event.dart';
import 'tenant_selection_state.dart';

class TenantSelectionBloc extends Bloc<TenantSelectionEvent, TenantSelectionState> {
  final TenantRepository repository;
  final TenantStorage tenantStorage;

  TenantSelectionBloc({required this.repository, required this.tenantStorage})
      : super(const TenantSelectionState.initial()) {
    on<LoadTenants>(_onLoadTenants);
    on<ResolveDeepLink>(_onResolveDeepLink);
    on<SelectTenant>(_onSelectTenant);
  }

  Future<void> _onLoadTenants(LoadTenants event, Emitter<TenantSelectionState> emit) async {
    emit(const TenantSelectionState.loading());
    final result = await repository.listTenants();
    result.fold(
      (failure) => emit(TenantSelectionState.error(failureMessage(failure))),
      (tenants) => emit(TenantSelectionState.loaded(tenants)),
    );
  }

  Future<void> _onResolveDeepLink(ResolveDeepLink event, Emitter<TenantSelectionState> emit) async {
    emit(const TenantSelectionState.loading());
    final result = await repository.findBySlug(event.slug);
    await result.fold(
      (failure) async => emit(TenantSelectionState.error(failureMessage(failure))),
      (tenant) async {
        await tenantStorage.saveTenant(id: tenant.id, slug: tenant.slug);
        emit(TenantSelectionState.resolved(tenant));
      },
    );
  }

  Future<void> _onSelectTenant(SelectTenant event, Emitter<TenantSelectionState> emit) async {
    await tenantStorage.saveTenant(id: event.tenant.id, slug: event.tenant.slug);
    emit(TenantSelectionState.selected(event.tenant));
  }
}
