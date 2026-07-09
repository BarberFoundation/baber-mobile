import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/stripe_bar.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: AppColors.brass, size: 64),
              const SizedBox(height: 20),
              const SizedBox(width: 64, child: StripeBar(height: 4)),
              const SizedBox(height: 20),
              Text('Agendamento confirmado!', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/appointments'),
                  child: const Text('Ver minhas consultas'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
