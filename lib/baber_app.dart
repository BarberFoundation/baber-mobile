import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'core/auth/token_storage.dart';
import 'core/router/app_router.dart';
import 'core/tenancy/tenant_storage.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/tenant_selection/domain/tenant_repository.dart';
import 'shared/theme/app_theme.dart';

class BaberApp extends StatelessWidget {
  final TokenStorage tokenStorage;
  final TenantStorage tenantStorage;
  final AuthRepository authRepository;
  final TenantRepository tenantRepository;
  final AppLinks appLinks;

  const BaberApp({
    super.key,
    required this.tokenStorage,
    required this.tenantStorage,
    required this.authRepository,
    required this.tenantRepository,
    required this.appLinks,
  });

  @override
  Widget build(BuildContext context) {
    final router = buildAppRouter(
      tokenStorage: tokenStorage,
      tenantStorage: tenantStorage,
      authRepository: authRepository,
      tenantRepository: tenantRepository,
      appLinks: appLinks,
    );
    return MaterialApp.router(
      title: 'Baber',
      theme: appTheme,
      routerConfig: router,
    );
  }
}
