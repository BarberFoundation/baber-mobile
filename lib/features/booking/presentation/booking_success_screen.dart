import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Agendamento confirmado!'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/appointments'),
              child: const Text('Ver minhas consultas'),
            ),
          ],
        ),
      ),
    );
  }
}
