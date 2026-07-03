import 'package:dio/dio.dart';
import '../auth/token_storage.dart';
import '../tenancy/tenant_storage.dart';

class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;
  final TenantStorage tenantStorage;
  late final Interceptor authInterceptor;

  ApiClient({
    required String baseUrl,
    required this.tokenStorage,
    required this.tenantStorage,
  }) : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    authInterceptor = InterceptorsWrapper(
      onRequest: (options, handler) async {
        final headers = await buildAuthHeaders();
        options.headers.addAll(headers);
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
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

  Future<bool> _tryRefresh() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null) return false;
    try {
      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {}),
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
