import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/barber_app_bar.dart';
import '../../../shared/widgets/otp_box_input.dart';
import 'auth_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _code = '';
  Timer? _timer;
  int _secondsLeft = 30;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _secondsLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _submit(AuthState state, String phone) {
    if (state.isLoading || _code.length != 6) return;
    context.read<AuthBloc>().add(CodeSubmitted(phone: phone, code: _code));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BarberAppBar(
        title: 'Código',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/phone'),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
          if (state.userNeedingName != null) {
            context.go('/name');
          } else if (state.authenticatedUser != null) {
            context.go('/home', extra: state.authenticatedUser!.name);
          }
        },
        builder: (context, state) {
          final phone = state.codeSentToPhone ?? '';
          final canSubmit = !state.isLoading && _code.length == 6;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Digite o código', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 6),
                Text(
                  'Enviado para $phone',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                ),
                const SizedBox(height: 24),
                OtpBoxInput(onChanged: (code) => setState(() => _code = code)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canSubmit ? () => _submit(state, phone) : null,
                    child: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                          )
                        : const Text('Confirmar'),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: _secondsLeft == 0
                        ? () {
                            context.read<AuthBloc>().add(PhoneSubmitted(phone));
                            _startCountdown();
                          }
                        : null,
                    child: Text(_secondsLeft == 0 ? 'Reenviar código' : 'Reenviar em $_secondsLeft s'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
