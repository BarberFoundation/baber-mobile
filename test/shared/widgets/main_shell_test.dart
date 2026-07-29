import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:baber_mobile/shared/theme/app_palette.dart';
import 'package:baber_mobile/shared/theme/app_theme.dart';
import 'package:baber_mobile/shared/widgets/main_shell.dart';

void main() {
  GoRouter buildRouter() => GoRouter(
        initialLocation: '/a',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(routes: [GoRoute(path: '/a', builder: (context, state) => const SizedBox())]),
              StatefulShellBranch(routes: [GoRoute(path: '/b', builder: (context, state) => const SizedBox())]),
              StatefulShellBranch(routes: [GoRoute(path: '/c', builder: (context, state) => const SizedBox())]),
            ],
          ),
        ],
      );

  Color navigationBarColor(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar)).backgroundColor ??
      Theme.of(tester.element(find.byType(NavigationBar))).navigationBarTheme.backgroundColor!;

  testWidgets('bottom nav follows the dark theme surface color', (tester) async {
    await tester.pumpWidget(MaterialApp.router(theme: AppTheme.dark, routerConfig: buildRouter()));

    expect(navigationBarColor(tester), AppPalette.dark.surface);
  });

  testWidgets('bottom nav follows the light theme surface color (not stuck dark)', (tester) async {
    await tester.pumpWidget(MaterialApp.router(theme: AppTheme.light, routerConfig: buildRouter()));

    expect(navigationBarColor(tester), AppPalette.light.surface);
  });

  testWidgets('labels the three tabs Início/Consultas/Perfil (no Avisos)', (tester) async {
    await tester.pumpWidget(MaterialApp.router(theme: AppTheme.dark, routerConfig: buildRouter()));

    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Consultas'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Avisos'), findsNothing);
  });
}
