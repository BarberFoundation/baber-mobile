import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../tenancy/tenant_storage.dart';
import 'token_storage.dart';

enum SessionStatus { active, loggedOut, expired }

/// Dono do encerramento de sessão — telas disparam os métodos e reagem ao
/// estado, sem tocar nos storages diretamente (A5 do review).
class SessionCubit extends Cubit<SessionStatus> {
  final TokenStorage tokenStorage;
  final TenantStorage tenantStorage;
  final AuthRepository authRepository;

  SessionCubit({
    required this.tokenStorage,
    required this.tenantStorage,
    required this.authRepository,
  }) : super(SessionStatus.active);

  /// Logout manual: limpa tudo; usuário volta a escolher a barbearia.
  Future<void> logout() async {
    await authRepository.signOut();
    await tokenStorage.clear();
    await tenantStorage.clear();
    emit(SessionStatus.loggedOut);
  }

  /// Sessão expirada: preserva o tenant — usuário loga de novo no mesmo salão.
  Future<void> expireTokens() async {
    // Sem isso, o próximo login com Google no mesmo device reaproveitava a
    // conta Google em cache silenciosamente (sem passar pelo account picker).
    await authRepository.signOut();
    await tokenStorage.clear();
    emit(SessionStatus.expired);
  }
}
