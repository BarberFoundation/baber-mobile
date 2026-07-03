import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
