import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/theme/app_colors.dart';
import 'booking_bloc.dart';
import 'booking_event.dart';
import 'booking_state.dart';

const _weekdays = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];

/// "Data e horário" step: a 4-day date strip above the slot grid, per the
/// redesign spec — combined into one step (dot 3 of 5) rather than two.
class ScheduleSelectionScreen extends StatelessWidget {
  const ScheduleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(4, (i) => today.add(Duration(days: i)));

    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: days.map((day) {
                  final iso = '${day.year.toString().padLeft(4, '0')}-'
                      '${day.month.toString().padLeft(2, '0')}-'
                      '${day.day.toString().padLeft(2, '0')}';
                  final selected = state.selectedDate == iso;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Card(
                        color: selected ? AppColors.brass : null,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => context.read<BookingBloc>().add(DateSelected(iso)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              children: [
                                Text(
                                  '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: selected ? AppColors.ink : null,
                                      ),
                                ),
                                Text(
                                  _weekdays[day.weekday % 7],
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: selected ? AppColors.ink : null,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(child: _SlotsArea(state: state)),
          ],
        );
      },
    );
  }
}

class _SlotsArea extends StatelessWidget {
  final BookingState state;

  const _SlotsArea({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.selectedDate == null) {
      return Center(
        child: Text(
          'Escolha uma data para ver os horários.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
        ),
      );
    }
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
              onPressed: () => context.read<BookingBloc>().add(DateSelected(state.selectedDate!)),
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
        final selected = state.selectedSlot == slot;
        return OutlinedButton(
          style: selected
              ? OutlinedButton.styleFrom(backgroundColor: AppColors.brass, foregroundColor: AppColors.ink)
              : null,
          onPressed: () => context.read<BookingBloc>().add(SlotSelected(slot)),
          child: Text(slot.startTime),
        );
      },
    );
  }
}
