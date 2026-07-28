import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failure.dart';
import '../../appointments/domain/appointment.dart';
import '../../appointments/domain/appointment_repository.dart';
import '../../catalog/domain/service_repository.dart';
import '../../loyalty/domain/loyalty_repository.dart';
import '../../profile/domain/profile_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ProfileRepository profileRepository;
  final AppointmentRepository appointmentRepository;
  final ServiceRepository serviceRepository;
  final LoyaltyRepository loyaltyRepository;

  HomeBloc({
    required this.profileRepository,
    required this.appointmentRepository,
    required this.serviceRepository,
    required this.loyaltyRepository,
  }) : super(const HomeState()) {
    on<LoadHome>(_onLoad);
  }

  Future<void> _onLoad(LoadHome event, Emitter<HomeState> emit) async {
    emit(const HomeState(isLoading: true));

    // The 4 calls are independent — fire them all before any await instead
    // of waiting on profile before even starting the others.
    final profileFuture = profileRepository.getMe();
    final appointmentsFuture = appointmentRepository.listMine();
    final servicesFuture = serviceRepository.listServices();
    final subscriptionFuture = loyaltyRepository.getMySubscription();

    final profileResult = await profileFuture;
    final unauthorized = profileResult.fold((f) => f is UnauthorizedFailure, (_) => false);
    if (unauthorized) {
      emit(const HomeState(sessionExpired: true));
      return;
    }
    // Falha não-auth (ex.: rede): segue sem nome em vez de travar o dashboard.
    final userName = profileResult.fold((_) => null, (user) => user.name);

    final appointmentsResult = await appointmentsFuture;
    final servicesResult = await servicesFuture;
    final subscriptionResult = await subscriptionFuture;

    final appointments = appointmentsResult.fold((_) => <Appointment>[], (a) => a);
    final upcoming = appointments.where((a) => a.isUpcoming).toList()
      ..sort((a, b) => a.startDateTime!.compareTo(b.startDateTime!));

    final next = upcoming.isEmpty ? null : upcoming.first;
    final serviceNames = servicesResult.fold(
      (_) => <String, String>{},
      (services) => {for (final s in services) s.id: s.name},
    );
    final hasActiveSubscription = subscriptionResult.fold((_) => false, (sub) => sub != null);

    emit(HomeState(
      userName: userName,
      nextAppointment: next,
      nextAppointmentServiceName: next == null ? null : serviceNames[next.serviceId],
      hasActiveSubscription: hasActiveSubscription,
    ));
  }
}
