import 'package:equatable/equatable.dart';
import '../domain/tenant.dart';

sealed class TenantSelectionEvent extends Equatable {
  const TenantSelectionEvent();
  @override
  List<Object?> get props => [];
}

class LoadTenants extends TenantSelectionEvent {}

class ResolveDeepLink extends TenantSelectionEvent {
  final String slug;
  const ResolveDeepLink(this.slug);
  @override
  List<Object?> get props => [slug];
}

class SelectTenant extends TenantSelectionEvent {
  final Tenant tenant;
  const SelectTenant(this.tenant);
  @override
  List<Object?> get props => [tenant];
}
