import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_storage.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final ThemeStorage storage;

  ThemeCubit({required this.storage}) : super(ThemeMode.dark) {
    _restore();
  }

  Future<void> _restore() async {
    final saved = await storage.readMode();
    if (saved == 'light') emit(ThemeMode.light);
    if (saved == 'dark') emit(ThemeMode.dark);
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    emit(next);
    await storage.saveMode(next == ThemeMode.light ? 'light' : 'dark');
  }
}
