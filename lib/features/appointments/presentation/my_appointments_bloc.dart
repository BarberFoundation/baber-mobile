import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/failure_message.dart';
import '../../catalog/domain/service_repository.dart';
import '../domain/appointment.dart';
import '../domain/appointment_repository.dart';
import 'my_appointments_event.dart';
import 'my_appointments_state.dart';

class MyAppointmentsBloc extends Bloc<MyAppointmentsEvent, MyAppointmentsState> {
  final AppointmentRepository appointmentRepository;
  final ServiceRepository serviceRepository;

  MyAppointmentsBloc({required this.appointmentRepository, required this.serviceRepository})
      : super(const MyAppointmentsState.initial()) {
    on<LoadMyAppointments>(_onLoad);
    on<CancelAppointmentRequested>(_onCancel);
  }

  Future<void> _onLoad(LoadMyAppointments event, Emitter<MyAppointmentsState> emit) async {
    emit(const MyAppointmentsState.loading());
    final appointmentsResult = await appointmentRepository.listMine();
    final servicesResult = await serviceRepository.listServices();

    final failure = appointmentsResult.fold<Failure?>((f) => f, (_) => null);
    if (failure is UnauthorizedFailure) {
      emit(const MyAppointmentsState(sessionExpired: true));
      return;
    }
    if (failure != null) {
      emit(MyAppointmentsState.error(failureMessage(failure)));
      return;
    }

    final appointments = appointmentsResult.fold((_) => <Appointment>[], (a) => a);
    final serviceNames = servicesResult.fold(
      (_) => <String, String>{},
      (services) => {for (final s in services) s.id: s.name},
    );

    emit(MyAppointmentsState.loaded(appointments: appointments, serviceNames: serviceNames));
  }

  Future<void> _onCancel(CancelAppointmentRequested event, Emitter<MyAppointmentsState> emit) async {
    emit(const MyAppointmentsState.loading());
    final result = await appointmentRepository.cancel(event.appointmentId);
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(MyAppointmentsState.error(failureMessage(failure)));
      return;
    }
    add(LoadMyAppointments());
  }
}
