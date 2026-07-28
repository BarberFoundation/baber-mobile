import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/failure.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/barber_app_bar.dart';
import '../../auth/domain/auth_user.dart';
import '../../profile/domain/profile_repository.dart';
import '../domain/barber_repository.dart';
import 'barber_selection_screen.dart';
import 'booking_bloc.dart';
import 'booking_state.dart';
import 'booking_success_screen.dart';
import 'confirm_booking_screen.dart';
import 'schedule_selection_screen.dart';

const _stepTitles = ['Escolha o barbeiro', 'Data e horário', 'Confirmar agendamento', 'Agendamento concluído'];

/// Single swipeable-feel container for the booking flow (Serviço is chosen
/// before entering; this covers Barbeiro → Horário → Confirmar → Sucesso).
/// Step transitions are driven by "Continuar" (and the Confirmar step's own
/// submit), not raw finger-drag — [PageView] physics are locked so a step
/// can't be skipped by swiping past a disabled "Continuar".
class BookingFlowScreen extends StatefulWidget {
  final BarberRepository barberRepository;
  final ProfileRepository profileRepository;

  const BookingFlowScreen({super.key, required this.barberRepository, required this.profileRepository});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  final _pageController = PageController();
  int _step = 0;
  late final Future<Either<Failure, AuthUser>> _profileFuture = widget.profileRepository.getMe();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _canContinue(BookingState state) {
    switch (_step) {
      case 0:
        return true; // "qualquer barbeiro disponível" is a valid default
      case 1:
        return state.selectedSlot != null;
      default:
        return false;
    }
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 480),
      curve: const Cubic(0.65, 0, 0.35, 1),
    );
  }

  void _handleBack(BuildContext context) {
    if (_step == 0) {
      context.go('/services');
    } else {
      _goToStep(_step - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        return Scaffold(
          appBar: BarberAppBar(
            title: _stepTitles[_step],
            leading: _step == 3
                ? null
                : IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _handleBack(context)),
          ),
          body: Column(
            children: [
              if (_step < 3) _StepDots(current: _step),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    BarberSelectionScreen(repository: widget.barberRepository),
                    const ScheduleSelectionScreen(),
                    FutureBuilder<Either<Failure, AuthUser>>(
                      future: _profileFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        // Best-effort prefill: any failure falls back to empty
                        // fields — the user still types name/phone by hand.
                        return snapshot.data!.fold(
                          (_) => ConfirmBookingScreen(
                            initialName: '',
                            initialPhone: '',
                            onBookingSucceeded: () => _goToStep(3),
                          ),
                          (user) => ConfirmBookingScreen(
                            initialName: user.name ?? '',
                            initialPhone: user.phone ?? '',
                            onBookingSucceeded: () => _goToStep(3),
                          ),
                        );
                      },
                    ),
                    const BookingSuccessScreen(),
                  ],
                ),
              ),
              if (_step < 2)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canContinue(state) ? () => _goToStep(_step + 1) : null,
                      child: const Text('Continuar'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StepDots extends StatelessWidget {
  /// Current dynamic step, 0-3 (Barbeiro..Sucesso). Dot 0 (Serviço) is
  /// always shown as done — that step happens before this flow is entered.
  final int current;

  const _StepDots({required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final done = i <= current + 1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              key: ValueKey('booking-step-dot-$i'),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.brass : AppColors.divider,
              ),
            ),
          );
        }),
      ),
    );
  }
}
