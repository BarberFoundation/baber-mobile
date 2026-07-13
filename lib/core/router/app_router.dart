import 'package:app_links/app_links.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../auth/session_cubit.dart';
import '../auth/token_storage.dart';
import '../error/failure.dart';
import '../tenancy/tenant_storage.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/auth_user.dart';
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
import '../../features/profile/domain/profile_repository.dart';
import '../../features/splash/presentation/initial_route_resolver.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/tenant_selection/domain/tenant_repository.dart';
import '../../features/tenant_selection/presentation/tenant_selection_bloc.dart';
import '../../features/tenant_selection/presentation/tenant_selection_screen.dart';
import '../../shared/widgets/main_shell.dart';

class _BookingShell extends StatefulWidget {
  final Service? initialService;
  final BookingRepository repository;
  final Widget child;

  const _BookingShell({required this.initialService, required this.repository, required this.child});

  @override
  State<_BookingShell> createState() => _BookingShellState();
}

class _BookingShellState extends State<_BookingShell> {
  BookingBloc? _bloc;

  @override
  void initState() {
    super.initState();
    final service = widget.initialService;
    if (service == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/services');
      });
    } else {
      _bloc = BookingBloc(repository: widget.repository, service: service);
    }
  }

  @override
  void dispose() {
    _bloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _bloc;
    if (bloc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return BlocProvider.value(value: bloc, child: widget.child);
  }
}

GoRouter buildAppRouter({
  required TokenStorage tokenStorage,
  required TenantStorage tenantStorage,
  required AuthRepository authRepository,
  required TenantRepository tenantRepository,
  required ServiceRepository serviceRepository,
  required BookingRepository bookingRepository,
  required AppointmentRepository appointmentRepository,
  required NotificationsRepository notificationsRepository,
  required ProfileRepository profileRepository,
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
              builder: (context, state) => MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => HomeBloc(
                      profileRepository: profileRepository,
                      appointmentRepository: appointmentRepository,
                      serviceRepository: serviceRepository,
                    ),
                  ),
                  BlocProvider(
                    create: (_) => SessionCubit(tokenStorage: tokenStorage, tenantStorage: tenantStorage),
                  ),
                ],
                child: const HomeScreen(),
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
        builder: (context, state, child) {
          // Só o push de entrada (/booking/date) carrega o Service; pushes
          // internos (slots/confirm/success) re-rodam este builder com extra
          // null, então o shell captura o service do PRIMEIRO build e o
          // mantém pelo fluxo. Sem service no primeiro build = restore de
          // processo (go_router não serializa objetos) → volta pro catálogo
          // em vez de TypeError (C8).
          final extra = state.extra;
          return _BookingShell(
            initialService: extra is Service ? extra : null,
            repository: bookingRepository,
            child: child,
          );
        },
        routes: [
          GoRoute(path: '/booking/date', builder: (context, state) => const DateSelectionScreen()),
          GoRoute(path: '/booking/slots', builder: (context, state) => const SlotSelectionScreen()),
          GoRoute(
            path: '/booking/confirm',
            builder: (context, state) => FutureBuilder<Either<Failure, AuthUser>>(
              future: profileRepository.getMe(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                // Best-effort prefill: qualquer falha (sessão, rede) cai em campos
                // vazios — o usuário ainda digita nome/telefone na mão, e sessão
                // realmente morta aparece quando BookingConfirmed falhar.
                return snapshot.data!.fold(
                  (_) => const ConfirmBookingScreen(initialName: '', initialPhone: ''),
                  (user) => ConfirmBookingScreen(initialName: user.name ?? '', initialPhone: user.phone),
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
