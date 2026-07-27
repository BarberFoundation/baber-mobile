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

/// A response from the server means it explicitly rejected the request
/// (expired/revoked refresh token, etc.) — a real reason to log out. No
/// response at all (timeout, no connectivity, DNS failure, ...) just means
/// the server was unreachable, which says nothing about the token's validity.
bool isAuthRejection(DioException error) => error.response != null;

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
        // Only an explicit rejection from the server clears tokens here — a
        // connectivity blip on the refresh call itself leaves the session
        // intact so the app can retry later instead of forcing a logout.
        final isRefreshRequest = isRefreshRequestPath(error.requestOptions.path);
        if (isRefreshRequest) {
          if (isAuthRejection(error)) {
            await tokenStorage.clear();
          }
        } else if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            final headers = await buildAuthHeaders();
            error.requestOptions.headers.addAll(headers);
            final response = await dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
          // _tryRefresh() already cleared tokens above if the refresh call
          // was itself rejected; a transient failure there leaves them
          // intact, so nothing to do here either way.
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
    if (refreshToken == null) {
      // Nothing to refresh with — a definitive dead session, not a
      // transient failure, so clear here same as an explicit rejection.
      await tokenStorage.clear();
      return false;
    }
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
      // The refresh POST goes through this same interceptor, so an explicit
      // rejection (401/403 response) was already cleared by the
      // isRefreshRequest branch in onError above; a transient failure
      // (no response) intentionally leaves tokens untouched here.
      return false;
    }
  }
}
