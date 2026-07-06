import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'auth_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controller = TextEditingController();
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Código')),
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
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Código enviado para $phone'),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: 'Código'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () => context.read<AuthBloc>().add(
                            CodeSubmitted(phone: phone, code: _controller.text),
                          ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar'),
                ),
                TextButton(
                  onPressed: _secondsLeft == 0
                      ? () {
                          context.read<AuthBloc>().add(PhoneSubmitted(phone));
                          _startCountdown();
                        }
                      : null,
                  child: Text(_secondsLeft == 0 ? 'Reenviar código' : 'Reenviar em $_secondsLeft s'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
