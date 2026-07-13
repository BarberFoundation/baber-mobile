import 'package:equatable/equatable.dart';
import '../domain/notification_item.dart';

class NotificationsState extends Equatable {
  final List<NotificationItem>? items;
  final String? errorMessage;
  final bool isLoading;
  final bool sessionExpired;

  const NotificationsState({this.items, this.errorMessage, this.isLoading = false, this.sessionExpired = false});

  const NotificationsState.initial() : this();
  const NotificationsState.loading() : this(isLoading: true);
  const NotificationsState.loaded(List<NotificationItem> items) : this(items: items);
  const NotificationsState.error(String message) : this(errorMessage: message);

  @override
  List<Object?> get props => [items, errorMessage, isLoading, sessionExpired];
}
