import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/shared/theme/theme_cubit.dart';
import 'package:baber_mobile/shared/theme/theme_storage.dart';

class MockThemeStorage extends Mock implements ThemeStorage {}

void main() {
  late MockThemeStorage storage;

  setUp(() {
    storage = MockThemeStorage();
    when(() => storage.saveMode(any())).thenAnswer((_) async {});
  });

  test('defaults to dark before storage resolves', () {
    when(() => storage.readMode()).thenAnswer((_) async => null);
    expect(ThemeCubit(storage: storage).state, ThemeMode.dark);
  });

  blocTest<ThemeCubit, ThemeMode>(
    'restores light mode from storage on startup',
    setUp: () => when(() => storage.readMode()).thenAnswer((_) async => 'light'),
    build: () => ThemeCubit(storage: storage),
    expect: () => [ThemeMode.light],
  );

  blocTest<ThemeCubit, ThemeMode>(
    'stays dark when storage has no saved preference',
    setUp: () => when(() => storage.readMode()).thenAnswer((_) async => null),
    build: () => ThemeCubit(storage: storage),
    expect: () => <ThemeMode>[],
  );

  blocTest<ThemeCubit, ThemeMode>(
    'toggle flips dark to light and persists it',
    setUp: () => when(() => storage.readMode()).thenAnswer((_) async => null),
    build: () => ThemeCubit(storage: storage),
    act: (cubit) => cubit.toggle(),
    expect: () => [ThemeMode.light],
    verify: (_) {
      verify(() => storage.saveMode('light')).called(1);
    },
  );

  blocTest<ThemeCubit, ThemeMode>(
    'toggle flips light back to dark and persists it',
    setUp: () => when(() => storage.readMode()).thenAnswer((_) async => 'light'),
    build: () => ThemeCubit(storage: storage),
    act: (cubit) async {
      // Let the constructor's restore-from-storage future settle before
      // toggling, otherwise toggle() races it and reads the stale default.
      await Future<void>.delayed(Duration.zero);
      await cubit.toggle();
    },
    skip: 1,
    expect: () => [ThemeMode.dark],
    verify: (_) {
      verify(() => storage.saveMode('dark')).called(1);
    },
  );
}
