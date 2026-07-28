import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/stripe_bar.dart';
import 'initial_route_resolver.dart';

/// Cold-start splash: logo wipe-reveal + brass glow pulse + scrolling stripe
/// mark + tagline fade + sequenced loading dots, while [resolver] resolves
/// the initial route. Dark theme only, regardless of the user's saved
/// theme preference — this screen renders before that preference matters.
class SplashScreen extends StatefulWidget {
  final InitialRouteResolver resolver;

  const SplashScreen({super.key, required this.resolver});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _revealController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final AnimationController _loopController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  late final Animation<double> _logoWipe = CurvedAnimation(parent: _revealController, curve: Curves.easeOut);
  late final Animation<double> _taglineOpacity = CurvedAnimation(
    parent: _revealController,
    curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
  );

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final route = await widget.resolver.resolve();
    if (mounted) context.go(route);
  }

  @override
  void dispose() {
    _revealController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _loopController,
              builder: (context, child) {
                final glow = 0.35 + 0.35 * (math.sin(_loopController.value * 2 * math.pi) + 1) / 2;
                return Container(
                  width: 140,
                  height: 140,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.brass.withValues(alpha: glow * 0.4),
                        AppColors.brass.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: child,
                );
              },
              child: AnimatedBuilder(
                animation: _logoWipe,
                builder: (context, child) => ClipRect(clipper: _WipeClipper(_logoWipe.value), child: child),
                child: Text(
                  'BABER',
                  style: GoogleFonts.bebasNeue(fontSize: 40, letterSpacing: 4, color: AppColors.brass),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _loopController,
              builder: (context, child) => ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1,
                  child: Transform.translate(
                    offset: Offset(-_loopController.value * 28, 0),
                    child: SizedBox(width: 96 + 28, child: const StripeBar(height: 4)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _taglineOpacity,
              child: Text(
                'Seu próximo corte, em segundos',
                style: GoogleFonts.karla(fontSize: 13, color: AppColors.steel),
              ),
            ),
            const SizedBox(height: 28),
            AnimatedBuilder(
              animation: _loopController,
              builder: (context, child) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final phase = i / 3;
                  final localT = ((_loopController.value - phase) % 1.0 + 1.0) % 1.0;
                  final active = localT < 0.35;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      key: ValueKey('splash-dot-$i'),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brass.withValues(alpha: active ? 1.0 : 0.25),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WipeClipper extends CustomClipper<Rect> {
  final double t;
  _WipeClipper(this.t);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * t, size.height);

  @override
  bool shouldReclip(covariant _WipeClipper oldClipper) => oldClipper.t != t;
}
