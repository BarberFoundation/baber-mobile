import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/barber_app_bar.dart';
import 'booking_bloc.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class SlotSelectionScreen extends StatelessWidget {
  const SlotSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarberAppBar(title: 'Escolha o horário'),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Não foi possível carregar os horários.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      final date = state.selectedDate;
                      if (date != null) {
                        context.read<BookingBloc>().add(DateSelected(date));
                      }
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }
          final slots = state.slots ?? [];
          if (slots.isEmpty) {
            return Center(
              child: Text(
                'Nenhum horário disponível nesta data.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
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
