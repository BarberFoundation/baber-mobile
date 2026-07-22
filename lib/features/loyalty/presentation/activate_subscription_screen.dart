import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../domain/subscription_tier_view.dart';
import '../../../shared/widgets/barber_app_bar.dart';
import 'activate_subscription_bloc.dart';
import 'activate_subscription_event.dart';
import 'activate_subscription_state.dart';

class ActivateSubscriptionScreen extends StatefulWidget {
  final SubscriptionTierView tier;
  final String initialName;
  final String initialPhone;

  const ActivateSubscriptionScreen({
    super.key,
    required this.tier,
    required this.initialName,
    required this.initialPhone,
  });

  @override
  State<ActivateSubscriptionScreen> createState() => _ActivateSubscriptionScreenState();
}

class _ActivateSubscriptionScreenState extends State<ActivateSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cpfCnpjController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _cpfCnpjController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfCnpjController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Informe seu nome';
    return null;
  }

  String? _validateCpfCnpj(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11 && digits.length != 14) return 'Informe um CPF ou CNPJ válido';
    return null;
  }

  void _submit(ActivateSubscriptionState state) {
    if (state.isLoading) return;
    if (_formKey.currentState!.validate()) {
      context.read<ActivateSubscriptionBloc>().add(ActivateSubmitted(
            name: _nameController.text,
            cpfCnpj: _cpfCnpjController.text,
            email: _emailController.text.isEmpty ? null : _emailController.text,
            phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BarberAppBar(title: 'Assinar ${widget.tier.tier}'),
      body: BlocConsumer<ActivateSubscriptionBloc, ActivateSubscriptionState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
          if (state.activated) {
            context.go('/loyalty');
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('${widget.tier.formattedMonthlyPrice} / mês', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  validator: _validateName,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cpfCnpjController,
                  keyboardType: TextInputType.number,
                  validator: _validateCpfCnpj,
                  decoration: const InputDecoration(labelText: 'CPF ou CNPJ'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail (opcional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone (opcional)'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: state.isLoading ? null : () => _submit(state),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Assinar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
