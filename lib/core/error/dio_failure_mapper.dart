import 'package:dio/dio.dart';
import 'failure.dart';

/// Mapeamento único de DioException → Failure para todos os repositórios.
/// 401 vira UnauthorizedFailure para que as telas possam reagir a sessão
/// expirada de forma uniforme (ver C4 do review).
Failure mapDioError(DioException e) {
  final statusCode = e.response?.statusCode;
  if (statusCode == null) return NetworkFailure(e.message ?? 'network error');
  if (statusCode == 401) return const UnauthorizedFailure();
  final data = e.response?.data;
  final message = (data is Map) ? (data['message']?.toString() ?? 'api error') : 'api error';
  return ApiFailure(statusCode: statusCode, message: message);
}
