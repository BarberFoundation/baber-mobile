import 'package:dio/dio.dart';
import '../auth/token_storage.dart';
import '../tenancy/tenant_storage.dart';
import 'single_flight.dart';

/// Returns true if [path] is the token-refresh endpoint's request path.
///
/// Extracted as a standalone function so the recursion guard in
/// [ApiClient]'s `authInterceptor` `onError` handler can be unit tested
/// in isolation, without needing to simulate Dio's interceptor pipeline.
bool isRefreshRequestPath(String path) => path == '/auth/client/refresh';

class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;
  final TenantStorage tenantStorage;
  late final Interceptor authInterceptor;
  final SingleFlight<bool> _refreshFlight = SingleFlight<bool>();

  ApiClient({
    required String baseUrl,
    required this.tokenStorage,
    required this.tenantStorage,
  }) : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    authInterceptor = InterceptorsWrapper(
      onRequest: (options, handler) async {
        // O refresh marca skipAuth: mandar o access token expirado no
        // Authorization do próprio /auth/client/refresh é credencial morta (S2).
        if (options.extra['skipAuth'] == true) {
          handler.next(options);
          return;
        }
        final headers = await buildAuthHeaders();
        options.headers.addAll(headers);
        handler.next(options);
      },
      onError: (error, handler) async {
        // Guard against infinite recursion: the /auth/client/refresh call itself
        // goes through this same Dio instance (and thus this same
        // interceptor). If the refresh token is expired/revoked, that
        // request will also fail with a 401, which would otherwise
        // re-enter this handler and call _tryRefresh() again, forever.
        // Any failure of the refresh request itself (401 or otherwise,
        // e.g. a network error) is treated as "refresh failed": clear
        // tokens once and propagate the error without recursing.
        final isRefreshRequest = isRefreshRequestPath(error.requestOptions.path);
        if (isRefreshRequest) {
          await tokenStorage.clear();
        } else if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            final headers = await buildAuthHeaders();
            error.requestOptions.headers.addAll(headers);
            final response = await dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
          await tokenStorage.clear();
        }
        handler.next(error);
      },
    );
    dio.interceptors.add(authInterceptor);
  }

  Future<Map<String, String>> buildAuthHeaders() async {
    final headers = <String, String>{};
    final accessToken = await tokenStorage.readAccessToken();
    final tenantId = await tenantStorage.readTenantId();
    if (accessToken != null) headers['Authorization'] = 'Bearer $accessToken';
    if (tenantId != null) headers['X-Tenant-Id'] = tenantId;
    return headers;
  }

  Future<bool> _tryRefresh() => _refreshFlight.run(_doRefresh);

  Future<bool> _doRefresh() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null) return false;
    try {
      // Mobile has no cookie jar, so it hits the client-specific refresh
      // endpoint that returns the rotated refresh token in the body —
      // POST /auth/refresh (web) only sets it as an httpOnly cookie.
      final response = await dio.post(
        '/auth/client/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );
      final accessToken = response.data['accessToken'] as String;
      final newRefreshToken = response.data['refreshToken'] as String;
      await tokenStorage.saveTokens(accessToken: accessToken, refreshToken: newRefreshToken);
      return true;
    } catch (_) {
      return false;
    }
  }
}
