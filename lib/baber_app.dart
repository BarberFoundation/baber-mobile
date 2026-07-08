import 'package:app_links/app_links.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'core/auth/token_storage.dart';
import 'core/router/app_router.dart';
import 'core/tenancy/tenant_storage.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/booking/domain/booking_repository.dart';
import 'features/catalog/domain/service_repository.dart';
import 'features/tenant_selection/domain/tenant_repository.dart';
import 'shared/theme/app_theme.dart';

class BaberApp extends StatelessWidget {
  final TokenStorage tokenStorage;
  final TenantStorage tenantStorage;
  final AuthRepository authRepository;
  final TenantRepository tenantRepository;
  final ServiceRepository serviceRepository;
  final BookingRepository bookingRepository;
  final Dio dio;
  final AppLinks appLinks;

  const BaberApp({
    super.key,
    required this.tokenStorage,
    required this.tenantStorage,
    required this.authRepository,
    required this.tenantRepository,
    required this.serviceRepository,
    required this.bookingRepository,
    required this.dio,
    required this.appLinks,
  });

  @override
  Widget build(BuildContext context) {
    final router = buildAppRouter(
      tokenStorage: tokenStorage,
      tenantStorage: tenantStorage,
      authRepository: authRepository,
      tenantRepository: tenantRepository,
      serviceRepository: serviceRepository,
      bookingRepository: bookingRepository,
      dio: dio,
      appLinks: appLinks,
    );
    return MaterialApp.router(
      title: 'Baber',
      theme: appTheme,
      routerConfig: router,
    );
  }
}
