import 'package:app_links/app_links.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../auth/token_storage.dart';
import '../tenancy/tenant_storage.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/presentation/auth_bloc.dart';
import '../../features/auth/presentation/name_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/phone_screen.dart';
import '../../features/appointments/domain/appointment_repository.dart';
import '../../features/appointments/presentation/my_appointments_bloc.dart';
import '../../features/appointments/presentation/my_appointments_screen.dart';
import '../../features/booking/domain/booking_repository.dart';
import '../../features/booking/presentation/booking_bloc.dart';
import '../../features/booking/presentation/booking_success_screen.dart';
import '../../features/booking/presentation/confirm_booking_screen.dart';
import '../../features/booking/presentation/date_selection_screen.dart';
import '../../features/booking/presentation/slot_selection_screen.dart';
import '../../features/catalog/domain/service.dart';
import '../../features/catalog/domain/service_repository.dart';
import '../../features/catalog/presentation/services_bloc.dart';
import '../../features/catalog/presentation/services_list_screen.dart';
import '../../features/home/presentation/home_bloc.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/notifications/domain/notifications_repository.dart';
import '../../features/notifications/presentation/notifications_bloc.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/splash/presentation/initial_route_resolver.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/tenant_selection/domain/tenant_repository.dart';
import '../../features/tenant_selection/presentation/tenant_selection_bloc.dart';
import '../../features/tenant_selection/presentation/tenant_selection_screen.dart';
import '../../shared/widgets/main_shell.dart';

GoRouter buildAppRouter({
  required TokenStorage tokenStorage,
  required TenantStorage tenantStorage,
  required AuthRepository authRepository,
  required TenantRepository tenantRepository,
  required ServiceRepository serviceRepository,
  required BookingRepository bookingRepository,
  required AppointmentRepository appointmentRepository,
  required NotificationsRepository notificationsRepository,
  required Dio dio,
  required AppLinks appLinks,
}) {
  final resolver = InitialRouteResolver(
    tokenStorage: tokenStorage,
    tenantStorage: tenantStorage,
    tenantRepository: tenantRepository,
    appLinks: appLinks,
  );

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => SplashScreen(resolver: resolver),
      ),
      GoRoute(
        path: '/tenant-selection',
        builder: (context, state) => BlocProvider(
          create: (_) => TenantSelectionBloc(repository: tenantRepository, tenantStorage: tenantStorage),
          child: const TenantSelectionScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => BlocProvider(
          create: (_) => AuthBloc(repository: authRepository, tokenStorage: tokenStorage),
          child: child,
        ),
        routes: [
          GoRoute(path: '/phone', builder: (context, state) => const PhoneScreen()),
          GoRoute(path: '/otp', builder: (context, state) => const OtpScreen()),
          GoRoute(path: '/name', builder: (context, state) => const NameScreen()),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => BlocProvider(
                create: (_) => HomeBloc(
                  dio: dio,
                  appointmentRepository: appointmentRepository,
                  serviceRepository: serviceRepository,
                ),
                child: HomeScreen(tokenStorage: tokenStorage, tenantStorage: tenantStorage),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/appointments',
              builder: (context, state) => BlocProvider(
                create: (_) => MyAppointmentsBloc(
                  appointmentRepository: appointmentRepository,
                  serviceRepository: serviceRepository,
                ),
                child: const MyAppointmentsScreen(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/notifications',
              builder: (context, state) => BlocProvider(
                create: (_) => NotificationsBloc(repository: notificationsRepository),
                child: const NotificationsScreen(),
              ),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/services',
        builder: (context, state) => BlocProvider(
          create: (_) => ServicesBloc(repository: serviceRepository),
          child: const ServicesListScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => BlocProvider(
          create: (_) => BookingBloc(repository: bookingRepository, service: state.extra as Service),
          child: child,
        ),
        routes: [
          GoRoute(path: '/booking/date', builder: (context, state) => const DateSelectionScreen()),
          GoRoute(path: '/booking/slots', builder: (context, state) => const SlotSelectionScreen()),
          GoRoute(
            path: '/booking/confirm',
            builder: (context, state) => FutureBuilder<Response>(
              future: dio.get('/me'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                final data = snapshot.data!.data as Map<String, dynamic>;
                return ConfirmBookingScreen(
                  initialName: (data['name'] as String?) ?? '',
                  initialPhone: (data['phone'] as String?) ?? '',
                );
              },
            ),
          ),
          GoRoute(path: '/booking/success', builder: (context, state) => const BookingSuccessScreen()),
        ],
      ),
    ],
  );
}
