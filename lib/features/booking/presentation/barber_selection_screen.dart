import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/theme/app_colors.dart';
import '../domain/barber.dart';
import '../domain/barber_repository.dart';
import 'booking_bloc.dart';
import 'booking_event.dart';
import 'booking_state.dart';

/// "Escolher barbeiro" step: name-only for v1 (no specialty/rating — no
/// backend support for that yet). Selection is optional — leaving "Qualquer
/// barbeiro disponível" selected (the default) means no preference.
class BarberSelectionScreen extends StatefulWidget {
  final BarberRepository repository;

  const BarberSelectionScreen({super.key, required this.repository});

  @override
  State<BarberSelectionScreen> createState() => _BarberSelectionScreenState();
}

class _BarberSelectionScreenState extends State<BarberSelectionScreen> {
  List<Barber>? _barbers;

  @override
  void initState() {
    super.initState();
    widget.repository.listBarbers().then((result) {
      if (!mounted) return;
      setState(() => _barbers = result.fold((_) => const [], (barbers) => barbers));
    });
  }

  @override
  Widget build(BuildContext context) {
    final barbers = _barbers;
    if (barbers == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _BarberCard(
              name: 'Qualquer barbeiro disponível',
              selected: state.selectedBarber == null,
              onTap: () => context.read<BookingBloc>().add(const BarberSelected(null)),
            ),
            for (final barber in barbers)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _BarberCard(
                  name: barber.name,
                  selected: state.selectedBarber?.id == barber.id,
                  onTap: () => context.read<BookingBloc>().add(BarberSelected(barber)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BarberCard extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _BarberCard({required this.name, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? AppColors.brass : AppColors.divider, width: selected ? 1.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.person_outline, color: selected ? AppColors.brass : AppColors.steel),
              const SizedBox(width: 12),
              Expanded(child: Text(name, style: Theme.of(context).textTheme.titleMedium)),
              if (selected) const Icon(Icons.check_circle, color: AppColors.brass),
            ],
          ),
        ),
      ),
    );
  }
}
