import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/stripe_bar.dart';
import 'initial_route_resolver.dart';

class SplashScreen extends StatefulWidget {
  final InitialRouteResolver resolver;

  const SplashScreen({super.key, required this.resolver});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.content_cut, color: AppColors.brass, size: 40),
            const SizedBox(height: 16),
            const SizedBox(width: 72, child: StripeBar(height: 4)),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.brass),
          ],
        ),
      ),
    );
  }
}
