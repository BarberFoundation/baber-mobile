/// Falha no boot se a base URL da API não for HTTPS em build de release.
/// Um release sem --dart-define=API_BASE_URL compila apontando para
/// http://localhost:3000 e só falha no primeiro request com erro genérico
/// de rede (S1 do review) — melhor quebrar no boot com mensagem clara.
///
/// [isRelease] é parâmetro (em vez de ler kReleaseMode aqui) para a regra
/// ser testável — kReleaseMode é sempre false em flutter test.
void assertSecureBaseUrl(String baseUrl, {required bool isRelease}) {
  if (isRelease && !baseUrl.startsWith('https://')) {
    throw StateError('API_BASE_URL deve usar HTTPS em release: $baseUrl');
  }
}
