import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/auth/session_cubit.dart';
import 'core/auth/token_storage.dart';
import 'core/router/app_router.dart';
import 'core/tenancy/tenant_storage.dart';
import 'features/appointments/domain/appointment_repository.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/booking/domain/booking_repository.dart';
import 'features/catalog/domain/service_repository.dart';
import 'features/loyalty/domain/loyalty_repository.dart';
import 'features/notifications/domain/notifications_repository.dart';
import 'features/profile/domain/profile_repository.dart';
import 'features/tenant_selection/domain/tenant_repository.dart';
import 'shared/theme/app_theme.dart';

class BaberApp extends StatelessWidget {
  final TokenStorage tokenStorage;
  final TenantStorage tenantStorage;
  final AuthRepository authRepository;
  final TenantRepository tenantRepository;
  final ServiceRepository serviceRepository;
  final BookingRepository bookingRepository;
  final LoyaltyRepository loyaltyRepository;
  final AppointmentRepository appointmentRepository;
  final NotificationsRepository notificationsRepository;
  final ProfileRepository profileRepository;
  final AppLinks appLinks;

  const BaberApp({
    super.key,
    required this.tokenStorage,
    required this.tenantStorage,
    required this.authRepository,
    required this.tenantRepository,
    required this.serviceRepository,
    required this.bookingRepository,
    required this.loyaltyRepository,
    required this.appointmentRepository,
    required this.notificationsRepository,
    required this.profileRepository,
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
      loyaltyRepository: loyaltyRepository,
      appointmentRepository: appointmentRepository,
      notificationsRepository: notificationsRepository,
      profileRepository: profileRepository,
      appLinks: appLinks,
    );
    // Provided at the app root — not scoped to a single route — so every
    // screen/bloc that hits a 401 can consistently clear the Firebase/Google
    // session alongside the tokens (see SessionCubit.expireTokens).
    return BlocProvider(
      create: (_) => SessionCubit(
        tokenStorage: tokenStorage,
        tenantStorage: tenantStorage,
        authRepository: authRepository,
      ),
      child: MaterialApp.router(
        title: 'Baber',
        theme: appTheme,
        routerConfig: router,
      ),
    );
  }
}
