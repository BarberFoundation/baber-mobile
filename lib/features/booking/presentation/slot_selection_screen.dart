import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'booking_bloc.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class SlotSelectionScreen extends StatelessWidget {
  const SlotSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escolha o horário')),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final slots = state.slots ?? [];
          if (slots.isEmpty) {
            return const Center(child: Text('Nenhum horário disponível nesta data.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              return OutlinedButton(
                onPressed: () {
                  context.read<BookingBloc>().add(SlotSelected(slot));
                  context.push('/booking/confirm');
                },
                child: Text(slot.startTime),
              );
            },
          );
        },
      ),
    );
  }
}
