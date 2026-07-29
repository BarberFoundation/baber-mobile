import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/barber_app_bar.dart';
import 'auth_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Informe seu nome';
    return null;
  }

  void _submit(AuthState state) {
    if (state.isLoading) return;
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(NameSubmitted(_controller.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BarberAppBar(
        title: 'Seu nome',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/phone'),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            AppToast.show(context, state.errorMessage!);
          }
          if (state.authenticatedUser != null) {
            context.go('/home', extra: state.authenticatedUser!.name);
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Como podemos te chamar?', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    validator: _validateName,
                    onFieldSubmitted: (_) => _submit(state),
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 16),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
