import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'booking_bloc.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final String initialName;
  final String initialPhone;

  const ConfirmBookingScreen({super.key, required this.initialName, required this.initialPhone});

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar agendamento')),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
          if (state.bookingSucceeded) {
            context.go('/booking/success');
          }
        },
        builder: (context, state) {
          final slot = state.selectedSlot;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Serviço: ${state.service.name}'),
                Text('Data: ${state.selectedDate ?? ''}'),
                Text('Horário: ${slot?.startTime ?? ''}'),
                Text('Preço: ${state.service.formattedPrice}'),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () => context.read<BookingBloc>().add(BookingConfirmed(
                            clientName: _nameController.text,
                            clientPhone: _phoneController.text,
                          )),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
