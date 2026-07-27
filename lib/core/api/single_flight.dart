/// Garante uma única execução em voo por vez: chamadas concorrentes a [run]
/// recebem o mesmo Future da execução em andamento.
///
/// Usado pelo refresh de token do ApiClient: vários 401 simultâneos
/// (dashboard dispara 3 requests em paralelo) devem aguardar UM único
/// POST /auth/client/refresh — com rotação de refresh token no backend,
/// refreshes paralelos consomem o token uns dos outros e derrubam a sessão (C3).
///
/// Extraída como classe standalone para ser testável em isolamento,
/// seguindo o mesmo padrão de isRefreshRequestPath.
class SingleFlight<T> {
  Future<T>? _inFlight;

  Future<T> run(Future<T> Function() action) {
    return _inFlight ??= action().whenComplete(() => _inFlight = null);
  }
}
