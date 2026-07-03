import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/tenant_selection/data/tenant_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late TenantRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = TenantRepositoryImpl(dio);
  });

  test('listTenants returns list of Tenant on 200', () async {
    when(() => dio.get('/tenants')).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/tenants'),
          statusCode: 200,
          data: [
            {'id': 't1', 'slug': 'barbearia-do-amigo', 'name': 'Barbearia do Amigo'},
          ],
        ));

    final result = await repository.listTenants();

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('expected right'), (tenants) {
      expect(tenants.length, 1);
      expect(tenants.first.slug, 'barbearia-do-amigo');
    });
  });

  test('findBySlug returns NetworkFailure on DioException', () async {
    when(() => dio.get('/tenants/unknown')).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/tenants/unknown')),
    );

    final result = await repository.findBySlug('unknown');

    expect(result.isLeft(), isTrue);
    result.fold((failure) => expect(failure, isA<NetworkFailure>()), (_) => fail('expected left'));
  });

  test('findBySlug returns ApiFailure with extracted message on 404', () async {
    when(() => dio.get('/tenants/unknown')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/tenants/unknown'),
        response: Response(
          requestOptions: RequestOptions(path: '/tenants/unknown'),
          statusCode: 404,
          data: {
            'message': 'Tenant não encontrado.',
            'statusCode': 404,
            'error': 'NOT_FOUND',
          },
        ),
      ),
    );

    final result = await repository.findBySlug('unknown');

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) {
        expect(failure, isA<ApiFailure>());
        final apiFailure = failure as ApiFailure;
        expect(apiFailure.statusCode, 404);
        expect(apiFailure.message, 'Tenant não encontrado.');
      },
      (_) => fail('expected left'),
    );
  });
}
