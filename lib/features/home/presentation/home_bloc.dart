import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../appointments/domain/appointment.dart';
import '../../appointments/domain/appointment_repository.dart';
import '../../catalog/domain/service_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final Dio dio;
  final AppointmentRepository appointmentRepository;
  final ServiceRepository serviceRepository;

  HomeBloc({required this.dio, required this.appointmentRepository, required this.serviceRepository})
      : super(const HomeState()) {
    on<LoadHome>(_onLoad);
  }

  Future<void> _onLoad(LoadHome event, Emitter<HomeState> emit) async {
    emit(const HomeState(isLoading: true));

    String? userName;
    try {
      final profileResponse = await dio.get('/me');
      userName = (profileResponse.data as Map<String, dynamic>)['name'] as String?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        emit(const HomeState(sessionExpired: true));
        return;
      }
      // Non-auth failure (e.g. network blip): keep going without a name
      // rather than blocking the whole dashboard on this one call.
    }

    final appointmentsResult = await appointmentRepository.listMine();
    final servicesResult = await serviceRepository.listServices();

    final appointments = appointmentsResult.fold((_) => <Appointment>[], (a) => a);
    final now = DateTime.now();
    final upcoming = appointments
        .where((a) =>
            a.status != AppointmentStatus.cancelled &&
            a.status != AppointmentStatus.completed &&
            DateTime.parse('${a.date}T${a.startTime}:00').isAfter(now))
        .toList()
      ..sort((a, b) =>
          DateTime.parse('${a.date}T${a.startTime}:00').compareTo(DateTime.parse('${b.date}T${b.startTime}:00')));

    final next = upcoming.isEmpty ? null : upcoming.first;
    final serviceNames = servicesResult.fold(
      (_) => <String, String>{},
      (services) => {for (final s in services) s.id: s.name},
    );

    emit(HomeState(
      userName: userName,
      nextAppointment: next,
      nextAppointmentServiceName: next == null ? null : serviceNames[next.serviceId],
    ));
  }
}
