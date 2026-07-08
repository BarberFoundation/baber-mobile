import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
      appBar: AppBar(title: const Text('Serviços')),
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
            return const Center(child: CircularProgressIndicator());
          }
          final services = state.services ?? [];
          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return ListTile(
                title: Text(service.name),
                subtitle: Text('${service.durationMinutes} min · ${service.formattedPrice}'),
                onTap: () => context.push('/booking/date', extra: service),
              );
            },
          );
        },
      ),
    );
  }
}
