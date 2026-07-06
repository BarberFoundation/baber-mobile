import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'baber_app.dart';
import 'core/api/api_client.dart';
import 'core/auth/token_storage.dart';
import 'core/tenancy/tenant_storage.dart';
import 'features/auth/data/auth_repository_impl.dart';
import 'features/tenant_selection/data/tenant_repository_impl.dart';

void main() {
  const storage = FlutterSecureStorage();
  final tokenStorage = TokenStorage(storage);
  final tenantStorage = TenantStorage(storage);
  final apiClient = ApiClient(
    baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000'),
    tokenStorage: tokenStorage,
    tenantStorage: tenantStorage,
  );
  final authRepository = AuthRepositoryImpl(apiClient.dio, tenantStorage);
  final tenantRepository = TenantRepositoryImpl(apiClient.dio);

  runApp(BaberApp(
    tokenStorage: tokenStorage,
    tenantStorage: tenantStorage,
    authRepository: authRepository,
    tenantRepository: tenantRepository,
    appLinks: AppLinks(),
  ));
}
