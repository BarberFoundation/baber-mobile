import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'tenant_selection_bloc.dart';
import 'tenant_selection_event.dart';
import 'tenant_selection_state.dart';

class TenantSelectionScreen extends StatefulWidget {
  const TenantSelectionScreen({super.key});

  @override
  State<TenantSelectionScreen> createState() => _TenantSelectionScreenState();
}

class _TenantSelectionScreenState extends State<TenantSelectionScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TenantSelectionBloc>().add(LoadTenants());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escolha a barbearia')),
      body: BlocConsumer<TenantSelectionBloc, TenantSelectionState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
          if (state.selectedTenant != null) {
            context.go('/phone');
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final tenants = state.tenants ?? [];
          return ListView.builder(
            itemCount: tenants.length,
            itemBuilder: (context, index) {
              final tenant = tenants[index];
              return ListTile(
                title: Text(tenant.name),
                onTap: () => context.read<TenantSelectionBloc>().add(SelectTenant(tenant)),
              );
            },
          );
        },
      ),
    );
  }
}
