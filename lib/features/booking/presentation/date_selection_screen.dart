import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/barber_app_bar.dart';
import 'booking_bloc.dart';
import 'booking_event.dart';

const _weekdays = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];

class DateSelectionScreen extends StatelessWidget {
  const DateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(30, (i) => today.add(Duration(days: i)));

    return Scaffold(
      appBar: const BarberAppBar(title: 'Escolha a data'),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final day = days[index];
          final iso = '${day.year.toString().padLeft(4, '0')}-'
              '${day.month.toString().padLeft(2, '0')}-'
              '${day.day.toString().padLeft(2, '0')}';
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                context.read<BookingBloc>().add(DateSelected(iso));
                context.push('/booking/slots');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Text(
                      '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _weekdays[day.weekday % 7],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: AppColors.steel),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
