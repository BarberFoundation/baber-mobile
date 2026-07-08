import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failure_message.dart';
import '../domain/service_repository.dart';
import 'services_event.dart';
import 'services_state.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final ServiceRepository repository;

  ServicesBloc({required this.repository}) : super(const ServicesState.initial()) {
    on<LoadServices>(_onLoadServices);
  }

  Future<void> _onLoadServices(LoadServices event, Emitter<ServicesState> emit) async {
    emit(const ServicesState.loading());
    final result = await repository.listServices();
    result.fold(
      (failure) => emit(ServicesState.error(failureMessage(failure))),
      (services) => emit(ServicesState.loaded(services)),
    );
  }
}
