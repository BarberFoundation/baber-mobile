import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/utils/relative_time.dart';
import '../domain/notification_item.dart';
import 'notifications_bloc.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(LoadNotifications());
  }

  IconData _iconFor(NotificationItemType type) {
    switch (type) {
      case NotificationItemType.confirmation:
        return Icons.check_circle_outline;
      case NotificationItemType.cancellation:
        return Icons.cancel_outlined;
      case NotificationItemType.reminder:
        return Icons.alarm;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: BlocConsumer<NotificationsBloc, NotificationsState>(
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
          final items = state.items ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Nenhuma notificação ainda.'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Icon(_iconFor(item.type)),
                title: Text(item.message),
                subtitle: Text(relativeTime(item.createdAt)),
              );
            },
          );
        },
      ),
    );
  }
}
