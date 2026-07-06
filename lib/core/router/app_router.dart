import 'package:app_links/app_links.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../auth/token_storage.dart';
import '../tenancy/tenant_storage.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/presentation/auth_bloc.dart';
import '../../features/auth/presentation/name_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/phone_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/splash/presentation/initial_route_resolver.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/tenant_selection/domain/tenant_repository.dart';
import '../../features/tenant_selection/presentation/tenant_selection_bloc.dart';
import '../../features/tenant_selection/presentation/tenant_selection_screen.dart';

GoRouter buildAppRouter({
  required TokenStorage tokenStorage,
  required TenantStorage tenantStorage,
  required AuthRepository authRepository,
  required TenantRepository tenantRepository,
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
      GoRoute(
        path: '/home',
        builder: (context, state) => HomeScreen(
          tokenStorage: tokenStorage,
          tenantStorage: tenantStorage,
          userName: state.extra as String?,
        ),
      ),
    ],
  );
}
