import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/session_cubit.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/barber_app_bar.dart';
import 'loyalty_bloc.dart';
import 'loyalty_event.dart';
import 'loyalty_state.dart';

class LoyaltyHubScreen extends StatelessWidget {
  const LoyaltyHubScreen({super.key});

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar assinatura?'),
        content: const Text('Você perde o acesso aos benefícios do clube ao final do ciclo atual.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Voltar')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<LoyaltyBloc>().add(CancelSubscriptionRequested());
    }
  }

  Future<void> _confirmRedeem(BuildContext context, String formattedBalance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Usar crédito?'),
        content: Text('Isso zera seu saldo de $formattedBalance. Combine o desconto com o barbeiro no balcão.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Voltar')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<LoyaltyBloc>().add(RedeemAllCreditRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarberAppBar(title: 'Clube'),
      body: BlocConsumer<LoyaltyBloc, LoyaltyState>(
        listener: (context, state) {
          if (state.actionErrorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.actionErrorMessage!)),
            );
          }
          if (state.sessionExpired) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sessão expirada. Faça login novamente.')),
            );
            context.read<SessionCubit>().expireTokens();
            context.go('/phone');
          }
        },
        builder: (context, state) {
          if (state.sessionExpired) {
            return const SizedBox.shrink();
          }
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null) {
            return Center(
              child: Text(
                state.errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
              ),
            );
          }

          final subscription = state.subscription;
          if (subscription != null) {
            final tierName = state.tierNameFor(subscription.tierId) ?? 'Clube';
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (subscription.isPastDue)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Pagamento atrasado — regularize para manter os benefícios.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.barberRed),
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PLANO $tierName',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.brass, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ciclo: ${subscription.currentCycleStart} – ${subscription.currentCycleEnd}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Divider(height: 24),
                        for (final quota in subscription.quotas)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '${state.serviceNameFor(quota.serviceId) ?? quota.serviceId}: '
                              '${quota.quantityConsumed}/${quota.quantityTotal} usado no ciclo',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: state.actionInProgress ? null : () => _confirmCancel(context),
                  child: const Text('Cancelar assinatura'),
                ),
              ],
            );
          }

          final stampCard = state.stampCard!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CARTÃO FIDELIDADE',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.brass, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${stampCard.currentStamps} / ${stampCard.stampsRequired ?? '-'}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text('Saldo de crédito: ${stampCard.formattedCreditBalance}'),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: stampCard.creditBalanceInCents <= 0 || state.actionInProgress
                            ? null
                            : () => _confirmRedeem(context, stampCard.formattedCreditBalance),
                        child: const Text('Usar crédito'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.push('/loyalty/plans'),
                child: const Text('Ver planos'),
              ),
            ],
          );
        },
      ),
    );
  }
}
