import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/barber_app_bar.dart';
import '../../../shared/widgets/status_pill.dart';
import '../domain/appointment.dart';
import 'my_appointments_bloc.dart';
import 'my_appointments_event.dart';
import 'my_appointments_state.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MyAppointmentsBloc>().add(LoadMyAppointments());
  }

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return AppColors.brass;
      case AppointmentStatus.confirmed:
        return const Color(0xFF6FA37A);
      case AppointmentStatus.completed:
        return AppColors.steel;
      case AppointmentStatus.cancelled:
        return AppColors.barberRed;
    }
  }

  String _statusLabel(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'PENDENTE';
      case AppointmentStatus.confirmed:
        return 'CONFIRMADO';
      case AppointmentStatus.completed:
        return 'CONCLUÍDO';
      case AppointmentStatus.cancelled:
        return 'CANCELADO';
    }
  }

  Future<void> _confirmCancel(BuildContext context, String appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar agendamento?'),
        content: const Text('Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Voltar')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Sim, cancelar')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<MyAppointmentsBloc>().add(CancelAppointmentRequested(appointmentId));
    }
  }

  Widget _buildItem(BuildContext context, Appointment appointment, Map<String, String> serviceNames) {
    final serviceName = serviceNames[appointment.serviceId] ?? appointment.serviceId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(serviceName, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${appointment.date} · ${appointment.startTime}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    StatusPill(label: _statusLabel(appointment.status), color: _statusColor(appointment.status)),
                  ],
                ),
              ),
              if (appointment.isCancellable)
                TextButton(
                  onPressed: () => _confirmCancel(context, appointment.id),
                  child: const Text('Cancelar'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarberAppBar(title: 'Minhas Consultas'),
      body: BlocConsumer<MyAppointmentsBloc, MyAppointmentsState>(
        listener: (context, state) {
          if (state.sessionExpired) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sessão expirada. Faça login novamente.')),
            );
            context.go('/phone');
            return;
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          // Durante cancelamento a lista continua visível; spinner cheio só sem dados.
          if (state.isLoading && state.appointments == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final appointments = state.appointments ?? [];
          final upcoming = appointments
              .where((a) =>
                  a.status != AppointmentStatus.cancelled &&
                  a.status != AppointmentStatus.completed &&
                  DateTime.parse('${a.date}T${a.startTime}:00').isAfter(DateTime.now()))
              .toList();
          final history = appointments.where((a) => !upcoming.contains(a)).toList();

          if (appointments.isEmpty) {
            return RefreshIndicator(
              color: AppColors.brass,
              backgroundColor: AppColors.surfaceHigh,
              onRefresh: () async => context.read<MyAppointmentsBloc>().add(LoadMyAppointments()),
              child: ListView(
                children: [
                  SizedBox(
                    height: 400,
                    child: Center(
                      child: Text(
                        'Você ainda não tem consultas.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.brass,
            backgroundColor: AppColors.surfaceHigh,
            onRefresh: () async => context.read<MyAppointmentsBloc>().add(LoadMyAppointments()),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _sectionHeader(context, 'Próximas'),
                if (upcoming.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Nenhuma consulta agendada.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ...upcoming.map((a) => _buildItem(context, a, state.serviceNames)),
                const SizedBox(height: 16),
                _sectionHeader(context, 'Histórico'),
                if (history.isEmpty)
                  Text(
                    'Nenhum histórico ainda.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ...history.map((a) => _buildItem(context, a, state.serviceNames)),
              ],
            ),
          );
        },
      ),
    );
  }
}
