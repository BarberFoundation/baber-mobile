import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        return Colors.amber;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.completed:
        return Colors.grey;
      case AppointmentStatus.cancelled:
        return Colors.red;
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
    return ListTile(
      title: Text(serviceName),
      subtitle: Text('${appointment.date} ${appointment.startTime}'),
      leading: CircleAvatar(backgroundColor: _statusColor(appointment.status), radius: 6),
      trailing: appointment.isCancellable
          ? TextButton(
              onPressed: () => _confirmCancel(context, appointment.id),
              child: const Text('Cancelar'),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Consultas')),
      body: BlocConsumer<MyAppointmentsBloc, MyAppointmentsState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
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

          return RefreshIndicator(
            onRefresh: () async => context.read<MyAppointmentsBloc>().add(LoadMyAppointments()),
            child: ListView(
              children: [
                const Padding(padding: EdgeInsets.all(16), child: Text('Próximas', style: TextStyle(fontWeight: FontWeight.bold))),
                ...upcoming.map((a) => _buildItem(context, a, state.serviceNames)),
                const Padding(padding: EdgeInsets.all(16), child: Text('Histórico', style: TextStyle(fontWeight: FontWeight.bold))),
                ...history.map((a) => _buildItem(context, a, state.serviceNames)),
              ],
            ),
          );
        },
      ),
    );
  }
}
