import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/session_cubit.dart';
import '../../../core/validation/cpf_cnpj_validator.dart';
import '../../../shared/theme/theme_cubit.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/barber_app_bar.dart';
import '../domain/profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileRepository profileRepository;

  const ProfileScreen({super.key, required this.profileRepository});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfCnpjController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final result = await widget.profileRepository.getMe();
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _isLoading = false),
      (user) => setState(() {
        _nameController.text = user.name ?? '';
        _phoneController.text = user.phone ?? '';
        _emailController.text = user.email ?? '';
        _cpfCnpjController.text = user.cpf ?? '';
        _isLoading = false;
      }),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final result = await widget.profileRepository.updateProfile(
      name: _nameController.text,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      cpf: _cpfCnpjController.text.isEmpty ? null : _cpfCnpjController.text,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    result.fold(
      (_) => AppToast.show(context, 'Não foi possível salvar seus dados.'),
      (_) => AppToast.show(context, 'Dados salvos.'),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Você precisará entrar novamente com seu telefone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Sair')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<SessionCubit>().logout();
      if (context.mounted) context.go('/tenant-selection');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cpfCnpjController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarberAppBar(title: 'Perfil'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  Text('MEUS DADOS', style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(
                    'Preencha uma vez e a gente usa pra assinar o Clube sem pedir de novo.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator: (value) => (value ?? '').trim().isEmpty ? 'Informe seu nome' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Telefone'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cpfCnpjController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'CPF ou CNPJ'),
                    validator: (value) =>
                        (value ?? '').isEmpty ? null : (isValidCpfCnpj(value!) ? null : 'CPF ou CNPJ inválido'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar'),
                  ),
                  const SizedBox(height: 28),
                  BlocBuilder<ThemeCubit, ThemeMode>(
                    builder: (context, mode) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(mode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                      title: const Text('Alternar tema'),
                      trailing: Switch(
                        value: mode == ThemeMode.dark,
                        onChanged: (_) => context.read<ThemeCubit>().toggle(),
                      ),
                      onTap: () => context.read<ThemeCubit>().toggle(),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout),
                    title: const Text('Sair da conta'),
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
    );
  }
}
