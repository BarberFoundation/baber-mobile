import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/barber_app_bar.dart';
import '../domain/pix_payment.dart';
import 'pix_payment_bloc.dart';
import 'pix_payment_event.dart';
import 'pix_payment_state.dart';

class PixPaymentScreen extends StatefulWidget {
  final PixPayment payment;

  const PixPaymentScreen({super.key, required this.payment});

  @override
  State<PixPaymentScreen> createState() => _PixPaymentScreenState();
}

class _PixPaymentScreenState extends State<PixPaymentScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PixPaymentBloc>().add(const PixPaymentStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarberAppBar(title: 'Pagamento via PIX'),
      body: BlocConsumer<PixPaymentBloc, PixPaymentState>(
        listener: (context, state) {
          if (state.status == PixPaymentStatus.paid) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pagamento confirmado!')),
            );
          }
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (state.status == PixPaymentStatus.paid) ...[
                const Icon(Icons.check_circle, color: AppColors.brass, size: 64),
                const SizedBox(height: 12),
                Text(
                  'Pagamento confirmado!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go('/loyalty'),
                  child: const Text('Continuar'),
                ),
              ] else ...[
                Text(
                  'Escaneie o QR code no app do seu banco',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Image.memory(
                    base64Decode(widget.payment.encodedImage),
                    width: 220,
                    height: 220,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ou copie o código PIX:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.payment.payload));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código copiado.')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar código PIX'),
                ),
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 12),
                Text(
                  'Aguardando confirmação do pagamento…',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.steel),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => context.go('/loyalty'),
                  child: const Text('Pagar depois'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
