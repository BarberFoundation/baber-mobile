import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/session_cubit.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/theme_cubit.dart';
import '../../../shared/widgets/barber_app_bar.dart';
import '../../../shared/widgets/stripe_bar.dart';
import 'home_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(LoadHome());
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Você precisará entrar novamente com seu telefone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Sair')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<SessionCubit>().logout();
      if (context.mounted) context.go('/tenant-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BarberAppBar(
        title: 'Início',
        actions: [
          // Foundation-phase UI home for the dark/light toggle — the
          // redesign's own settings surface (Phase 3a) will replace this
          // with the spec's pill switch once that screen lands.
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) => IconButton(
              icon: Icon(mode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
              tooltip: 'Alternar tema',
              onPressed: () => context.read<ThemeCubit>().toggle(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state.sessionExpired) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sessão expirada. Faça login novamente.')),
            );
            // Sessão expirada não apaga o tenant: o usuário volta pro login do
            // mesmo salão. Logout manual continua indo para /tenant-selection.
            context.read<SessionCubit>().expireTokens();
            context.go('/phone');
          }
        },
        builder: (context, state) {
          if (state.sessionExpired) {
            return const SizedBox.shrink();
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Text(
                'Bem-vindo,',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
              ),
              Text(
                state.userName ?? '',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 20),
              if (state.nextAppointment != null) _NextAppointmentCard(state: state),
              if (state.nextAppointment != null) const SizedBox(height: 28),
              Text(
                'ATALHOS',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ShortcutTile(
                      icon: Icons.content_cut,
                      label: 'Serviços',
                      onTap: () => context.push('/services'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ShortcutTile(
                      icon: Icons.event_outlined,
                      label: 'Consultas',
                      onTap: () => context.go('/appointments'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ShortcutTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notificações',
                      onTap: () => context.go('/notifications'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ShortcutTile(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Clube',
                      onTap: () => context.push('/loyalty'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox.shrink()),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  final HomeState state;

  const _NextAppointmentCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StripeBar(height: 4),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRÓXIMA CONSULTA',
                    style: textTheme.labelMedium?.copyWith(color: AppColors.brass, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(state.nextAppointmentServiceName ?? '', style: textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    '${state.nextAppointment!.date} · ${state.nextAppointment!.startTime}',
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShortcutTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: AppColors.brass, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.cream),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
