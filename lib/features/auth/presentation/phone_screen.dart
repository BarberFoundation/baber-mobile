import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/stripe_bar.dart';
import 'auth_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // segmentos coloridos do "G" do Google
    const segments = [
      (Color(0xFF4285F4), -0.1, 1.65), // azul
      (Color(0xFF34A853), 1.55, 3.25), // verde
      (Color(0xFFFBBC05), 3.15, 4.45), // amarelo
      (Color(0xFFEA4335), 4.35, 5.95), // vermelho
    ];

    for (final (color, start, end) in segments) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = size.width * 0.28
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.72),
        start,
        end - start,
        false,
        paint,
      );
    }

    // barra horizontal do "G"
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = size.width * 0.28
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius * 0.72, center.dy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Informe um telefone válido com DDD';
    return null;
  }

  void _submit(AuthState state) {
    if (state.isLoading) return;
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(PhoneSubmitted(_controller.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tenant-selection'),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            AppToast.show(context, state.errorMessage!);
          }
          // Android pode auto-verificar (SMS Retriever) antes mesmo do codeSent —
          // o login completa sem o usuário sair desta tela (C2 do review).
          if (state.userNeedingName != null) {
            context.go('/name');
          } else if (state.authenticatedUser != null) {
            context.go('/home');
          } else if (state.codeSentToPhone != null) {
            context.go('/otp');
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 56, child: StripeBar(height: 4)),
                    const SizedBox(height: 20),
                    Text('Seu próximo corte,', style: Theme.of(context).textTheme.displayMedium),
                    Text('em segundos', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppColors.brass)),
                    const SizedBox(height: 10),
                    Text(
                      'Informe seu telefone para receber o código de acesso.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      validator: _validatePhone,
                      onFieldSubmitted: (_) => _submit(state),
                      decoration: const InputDecoration(labelText: 'Telefone', hintText: '(11) 99999-9999'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.isLoading ? null : () => _submit(state),
                        child: state.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                              )
                            : const Text('Continuar'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('ou', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.steel)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: state.isLoading
                            ? null
                            : () => context.read<AuthBloc>().add(const GoogleSignInSubmitted()),
                        icon: const _GoogleLogo(),
                        label: const Text('Entrar com Google'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
