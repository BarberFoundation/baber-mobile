import 'package:equatable/equatable.dart';
import '../domain/tenant.dart';

class TenantSelectionState extends Equatable {
  final List<Tenant>? tenants;
  final Tenant? resolvedTenant;
  final Tenant? selectedTenant;
  final String? errorMessage;
  final bool isLoading;

  const TenantSelectionState({
    this.tenants,
    this.resolvedTenant,
    this.selectedTenant,
    this.errorMessage,
    this.isLoading = false,
  });

  const TenantSelectionState.initial() : this();

  const TenantSelectionState.loading() : this(isLoading: true);

  const TenantSelectionState.loaded(List<Tenant> tenants) : this(tenants: tenants);

  const TenantSelectionState.error(String message) : this(errorMessage: message);

  const TenantSelectionState.resolved(Tenant tenant) : this(resolvedTenant: tenant);

  const TenantSelectionState.selected(Tenant tenant) : this(selectedTenant: tenant);

  @override
  List<Object?> get props => [tenants, resolvedTenant, selectedTenant, errorMessage, isLoading];
}
