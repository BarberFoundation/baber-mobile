import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'booking_bloc.dart';
import 'booking_event.dart';

class DateSelectionScreen extends StatelessWidget {
  const DateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(30, (i) => today.add(Duration(days: i)));

    return Scaffold(
      appBar: AppBar(title: const Text('Escolha a data')),
      body: ListView.builder(
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final iso = '${day.year.toString().padLeft(4, '0')}-'
              '${day.month.toString().padLeft(2, '0')}-'
              '${day.day.toString().padLeft(2, '0')}';
          return ListTile(
            title: Text('${day.day}/${day.month}/${day.year}'),
            onTap: () {
              context.read<BookingBloc>().add(DateSelected(iso));
              context.push('/booking/slots');
            },
          );
        },
      ),
    );
  }
}
