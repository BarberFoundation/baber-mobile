import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/tenancy/tenant_storage.dart';
import 'home_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeScreen extends StatefulWidget {
  final TokenStorage tokenStorage;
  final TenantStorage tenantStorage;

  const HomeScreen({super.key, required this.tokenStorage, required this.tenantStorage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(LoadHome());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await widget.tokenStorage.clear();
              await widget.tenantStorage.clear();
              if (context.mounted) context.go('/tenant-selection');
            },
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Bem-vindo, ${state.userName ?? ''}', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              if (state.nextAppointment != null)
                Card(
                  child: ListTile(
                    title: Text('Próxima consulta: ${state.nextAppointmentServiceName ?? ''}'),
                    subtitle: Text('${state.nextAppointment!.date} ${state.nextAppointment!.startTime}'),
                  ),
                ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.content_cut),
                title: const Text('Serviços'),
                onTap: () => context.push('/services'),
              ),
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Minhas Consultas'),
                onTap: () => context.go('/appointments'),
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notificações'),
                onTap: () => context.go('/notifications'),
              ),
            ],
          );
        },
      ),
    );
  }
}
