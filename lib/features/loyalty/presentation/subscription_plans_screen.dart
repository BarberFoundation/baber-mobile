import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/barber_app_bar.dart';
import 'subscription_plans_bloc.dart';
import 'subscription_plans_event.dart';
import 'subscription_plans_state.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SubscriptionPlansBloc>().add(LoadSubscriptionPlans());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarberAppBar(title: 'Planos do clube'),
      body: BlocConsumer<SubscriptionPlansBloc, SubscriptionPlansState>(
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
          final tiers = state.tiers ?? [];
          if (tiers.isEmpty) {
            return Center(
              child: Text(
                'Nenhum plano disponível no momento.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: tiers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tier = tiers[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tier.name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${tier.formattedMonthlyPrice} / mês',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.brass),
                      ),
                      const SizedBox(height: 12),
                      for (final item in tier.services)
                        Text('${item.quantity}x serviço incluso', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.push('/loyalty/activate', extra: tier),
                        child: const Text('Assinar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
