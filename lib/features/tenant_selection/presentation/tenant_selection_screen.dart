import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/stripe_bar.dart';
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StripeBar(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text('Escolha a barbearia', style: Theme.of(context).textTheme.displaySmall),
            ),
            Expanded(
              child: BlocConsumer<TenantSelectionBloc, TenantSelectionState>(
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
                  if (tenants.isEmpty) {
                    return Center(
                      child: Text(
                        'Nenhuma barbearia encontrada.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: tenants.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tenant = tenants[index];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => context.read<TenantSelectionBloc>().add(SelectTenant(tenant)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.brass.withValues(alpha: 0.15),
                                  ),
                                  child: const Icon(Icons.storefront_outlined, color: AppColors.brass),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(tenant.name, style: Theme.of(context).textTheme.titleMedium),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.steel),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
