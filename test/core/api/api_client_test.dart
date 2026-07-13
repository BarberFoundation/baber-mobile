import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/api/api_client.dart';
import 'package:baber_mobile/core/auth/token_storage.dart';
import 'package:baber_mobile/core/tenancy/tenant_storage.dart';

class MockTokenStorage extends Mock implements TokenStorage {}
class MockTenantStorage extends Mock implements TenantStorage {}
class MockDio extends Mock implements Dio {}
class MockErrorHandler extends Mock implements ErrorInterceptorHandler {}
class MockRequestHandler extends Mock implements RequestInterceptorHandler {}

void main() {
  late MockTokenStorage tokenStorage;
  late MockTenantStorage tenantStorage;
  late ApiClient client;

  setUp(() {
    tokenStorage = MockTokenStorage();
    tenantStorage = MockTenantStorage();
    client = ApiClient(
      baseUrl: 'https://baber-api.fly.dev/api/v1',
      tokenStorage: tokenStorage,
      tenantStorage: tenantStorage,
    );
  });

  test('dio instance has baseUrl configured', () {
    expect(client.dio.options.baseUrl, 'https://baber-api.fly.dev/api/v1');
  });

  test('request interceptor attaches Authorization header when access token present', () async {
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'abc');
    when(() => tenantStorage.readTenantId()).thenAnswer((_) async => 't1');

    final result = await client.buildAuthHeaders();

    expect(result['Authorization'], 'Bearer abc');
    expect(result['X-Tenant-Id'], 't1');
  });

  group('authInterceptor.onRequest', () {
    test('skips auth headers when the request is marked with skipAuth (S2)', () async {
      final options = RequestOptions(path: '/auth/refresh', extra: {'skipAuth': true});
      final handler = MockRequestHandler();

      (client.authInterceptor as InterceptorsWrapper).onRequest(options, handler);
      await untilCalled(() => handler.next(options));

      expect(options.headers.containsKey('Authorization'), isFalse);
      verifyNever(() => tokenStorage.readAccessToken());
    });

    test('attaches auth headers on ordinary requests', () async {
      when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'abc');
      when(() => tenantStorage.readTenantId()).thenAnswer((_) async => 't1');
      final options = RequestOptions(path: '/appointments');
      final handler = MockRequestHandler();

      (client.authInterceptor as InterceptorsWrapper).onRequest(options, handler);
      await untilCalled(() => handler.next(options));

      expect(options.headers['Authorization'], 'Bearer abc');
    });
  });

  group('isRefreshRequestPath (recursion guard)', () {
    // Directly exercising Dio's onError pipeline to prove "no infinite
    // recursion" is awkward: the recursive call is internal to the
    // interceptor and Dio does not expose hooks to count re-entrant
    // invocations without a much heavier fake HTTP adapter setup. Instead,
    // the "is this the refresh request" predicate that the onError guard
    // relies on (see authInterceptor's onError in api_client.dart) is
    // extracted into the standalone isRefreshRequestPath function and
    // unit tested here in isolation. This directly proves the condition
    // that prevents a 401 from /auth/refresh from re-triggering
    // _tryRefresh(), which is what stops the unbounded recursion.
    test('returns true for the refresh endpoint path', () {
      expect(isRefreshRequestPath('/auth/refresh'), isTrue);
    });

    test('returns false for other request paths, including 401-prone ones', () {
      expect(isRefreshRequestPath('/appointments'), isFalse);
      expect(isRefreshRequestPath('/auth/login'), isFalse);
      expect(isRefreshRequestPath('/auth/refreshx'), isFalse);
      expect(isRefreshRequestPath(''), isFalse);
    });
  });

  group('authInterceptor.onError (recursion guard, wired through Dio)', () {
    test('refresh-request failure clears tokens and does not recurse into _tryRefresh', () async {
      when(() => tokenStorage.clear()).thenAnswer((_) async {});

      final err = DioException(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          statusCode: 401,
        ),
      );
      final handler = MockErrorHandler();

      client.authInterceptor.onError(err, handler);
      await untilCalled(() => handler.next(err));

      verify(() => tokenStorage.clear()).called(1);
      verifyNever(() => tokenStorage.readRefreshToken());
      verify(() => handler.next(err)).called(1);
    });

    test('non-refresh-path 401 triggers _tryRefresh via readRefreshToken', () async {
      when(() => tokenStorage.readRefreshToken()).thenAnswer((_) async => null);
      when(() => tokenStorage.clear()).thenAnswer((_) async {});

      final err = DioException(
        requestOptions: RequestOptions(path: '/appointments'),
        response: Response(
          requestOptions: RequestOptions(path: '/appointments'),
          statusCode: 401,
        ),
      );
      final handler = MockErrorHandler();

      client.authInterceptor.onError(err, handler);
      await untilCalled(() => handler.next(err));

      verify(() => tokenStorage.readRefreshToken()).called(1);
      verify(() => tokenStorage.clear()).called(1);
      verify(() => handler.next(err)).called(1);
    });
  });
}
