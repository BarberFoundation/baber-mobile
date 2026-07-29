import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/appointment_date.dart';
import '../../../shared/widgets/app_toast.dart';
import 'booking_bloc.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final VoidCallback onBookingSucceeded;

  const ConfirmBookingScreen({
    super.key,
    required this.initialName,
    required this.initialPhone,
    required this.onBookingSucceeded,
  });

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Informe seu nome';
    return null;
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Informe um telefone válido com DDD';
    return null;
  }

  void _submit(BookingState state) {
    if (state.isLoading) return;
    if (_formKey.currentState!.validate()) {
      context.read<BookingBloc>().add(BookingConfirmed(
            clientName: _nameController.text,
            clientPhone: _phoneController.text,
          ));
    }
  }

  Widget _summaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppToast.show(context, state.errorMessage!);
        }
        if (state.bookingSucceeded) {
          widget.onBookingSucceeded();
        }
      },
      builder: (context, state) {
        final slot = state.selectedSlot;
        return Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.brass, AppColors.brassDim],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  state.selectedDate == null ? '' : formatChipMonth(state.selectedDate!),
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.ink),
                                ),
                                Text(
                                  state.selectedDate == null ? '' : formatChipDay(state.selectedDate!),
                                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${state.selectedDate == null ? '' : formatWeekdayFull(state.selectedDate!).toUpperCase()} · ${slot?.startTime ?? ''}',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                if (state.selectedBarber != null)
                                  Text(
                                    'com ${state.selectedBarber!.name}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.steel),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _summaryRow(context, 'Serviço', state.service.name),
                      _summaryRow(context, 'Preço', state.service.formattedPrice),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: _validateName,
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_phoneFocusNode),
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                validator: _validatePhone,
                onFieldSubmitted: (_) => _submit(state),
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: state.isLoading ? null : () => _submit(state),
                child: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                      )
                    : const Text('Confirmar'),
              ),
            ],
          ),
        );
      },
    );
  }
}
