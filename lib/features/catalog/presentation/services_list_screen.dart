import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/barber_app_bar.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import 'services_bloc.dart';
import 'services_event.dart';
import 'services_state.dart';

class ServicesListScreen extends StatefulWidget {
  const ServicesListScreen({super.key});

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ServicesBloc>().add(LoadServices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarberAppBar(title: 'Serviços'),
      body: BlocConsumer<ServicesBloc, ServicesState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: 6,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => const ServiceSkeletonRow(),
            );
          }
          final services = state.services ?? [];
          if (services.isEmpty) {
            return Center(
              child: Text(
                'Nenhum serviço disponível no momento.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: services.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final service = services[index];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.push('/booking/date', extra: service),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(service.name, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text(
                                '${service.durationMinutes} min',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          service.formattedPrice,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.brass),
                        ),
                        const SizedBox(width: 8),
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
    );
  }
}
