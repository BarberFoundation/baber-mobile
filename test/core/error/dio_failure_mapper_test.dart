import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/core/error/dio_failure_mapper.dart';
import 'package:baber_mobile/core/error/failure.dart';

DioException _dioError({int? statusCode, dynamic data, String? message}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    message: message,
    response: statusCode == null
        ? null
        : Response(requestOptions: options, statusCode: statusCode, data: data),
  );
}

void main() {
  test('maps missing response to NetworkFailure with dio message', () {
    expect(mapDioError(_dioError(message: 'timeout')), const NetworkFailure('timeout'));
  });

  test('maps missing response and null message to generic NetworkFailure', () {
    expect(mapDioError(_dioError()), const NetworkFailure('network error'));
  });

  test('maps 401 to UnauthorizedFailure regardless of body', () {
    expect(
      mapDioError(_dioError(statusCode: 401, data: {'message': 'Unauthorized'})),
      const UnauthorizedFailure(),
    );
  });

  test('maps other status codes to ApiFailure with backend message', () {
    expect(
      mapDioError(_dioError(statusCode: 409, data: {'message': 'conflito'})),
      const ApiFailure(statusCode: 409, message: 'conflito'),
    );
  });

  test('falls back to generic message when body is not a map', () {
    expect(
      mapDioError(_dioError(statusCode: 500, data: 'oops')),
      const ApiFailure(statusCode: 500, message: 'api error'),
    );
  });
}
