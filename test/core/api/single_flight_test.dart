import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/core/api/single_flight.dart';

void main() {
  test('chamadas concorrentes compartilham a mesma execução', () async {
    final flight = SingleFlight<int>();
    var calls = 0;
    final completer = Completer<int>();

    Future<int> action() {
      calls++;
      return completer.future;
    }

    final f1 = flight.run(action);
    final f2 = flight.run(action);
    completer.complete(42);

    expect(await f1, 42);
    expect(await f2, 42);
    expect(calls, 1);
  });

  test('após conclusão, nova chamada executa de novo', () async {
    final flight = SingleFlight<int>();
    var calls = 0;
    Future<int> action() async => ++calls;

    await flight.run(action);
    await flight.run(action);

    expect(calls, 2);
  });

  test('falha não trava execuções futuras', () async {
    final flight = SingleFlight<int>();
    var calls = 0;
    Future<int> failing() async {
      calls++;
      throw StateError('boom');
    }

    await expectLater(flight.run(failing), throwsStateError);
    await expectLater(flight.run(failing), throwsStateError);
    expect(calls, 2);
  });
}
