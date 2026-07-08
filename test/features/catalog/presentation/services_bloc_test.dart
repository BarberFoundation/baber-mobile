import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/catalog/domain/service.dart';
import 'package:baber_mobile/features/catalog/domain/service_repository.dart';
import 'package:baber_mobile/features/catalog/presentation/services_bloc.dart';
import 'package:baber_mobile/features/catalog/presentation/services_event.dart';
import 'package:baber_mobile/features/catalog/presentation/services_state.dart';

class MockServiceRepository extends Mock implements ServiceRepository {}

void main() {
  late MockServiceRepository repository;

  setUp(() {
    repository = MockServiceRepository();
  });

  const service = Service(id: 's1', name: 'Corte', priceInCents: 4000, durationMinutes: 30);

  blocTest<ServicesBloc, ServicesState>(
    'emits [loading, loaded] when LoadServices succeeds',
    build: () {
      when(() => repository.listServices()).thenAnswer((_) async => const Right([service]));
      return ServicesBloc(repository: repository);
    },
    act: (bloc) => bloc.add(LoadServices()),
    expect: () => [
      const ServicesState.loading(),
      const ServicesState.loaded([service]),
    ],
  );

  blocTest<ServicesBloc, ServicesState>(
    'emits [loading, error] when LoadServices fails',
    build: () {
      when(() => repository.listServices())
          .thenAnswer((_) async => const Left(ApiFailure(statusCode: 500, message: 'erro interno')));
      return ServicesBloc(repository: repository);
    },
    act: (bloc) => bloc.add(LoadServices()),
    expect: () => [
      const ServicesState.loading(),
      const ServicesState.error('erro interno'),
    ],
  );
}
