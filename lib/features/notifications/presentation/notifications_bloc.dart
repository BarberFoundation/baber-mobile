import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/failure_message.dart';
import '../domain/notifications_repository.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository repository;

  NotificationsBloc({required this.repository}) : super(const NotificationsState.initial()) {
    on<LoadNotifications>(_onLoad);
  }

  Future<void> _onLoad(LoadNotifications event, Emitter<NotificationsState> emit) async {
    emit(const NotificationsState.loading());
    final result = await repository.listMine();
    result.fold(
      (failure) => failure is UnauthorizedFailure
          ? emit(const NotificationsState(sessionExpired: true))
          : emit(NotificationsState.error(failureMessage(failure))),
      (items) => emit(NotificationsState.loaded(items)),
    );
  }
}
