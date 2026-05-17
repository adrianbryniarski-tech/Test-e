import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wybrany wariant motywu. Persistowany w `shared_preferences` per
/// urządzenie (motyw to lokalna preferencja UX, nie ma sensu sync z DB).
final themeVariantProvider =
    NotifierProvider<ThemeVariantNotifier, AppThemeVariant>(
  ThemeVariantNotifier.new,
);

class ThemeVariantNotifier extends Notifier<AppThemeVariant> {
  static const _key = 'theme_variant';

  @override
  AppThemeVariant build() {
    // Synchronous build — async load happens after first frame, state
    // jest aktualizowany gdy preferencje się ściągną.
    _load();
    return AppThemeVariant.spokojny;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    if (name == null) return;
    final loaded = AppThemeVariant.values.firstWhere(
      (v) => v.name == name,
      orElse: () => AppThemeVariant.spokojny,
    );
    if (loaded != state) state = loaded;
  }

  Future<void> set(AppThemeVariant variant) async {
    state = variant;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, variant.name);
  }
}

/// Tryb jasny/ciemny/auto. Domyślnie `system` — Android decyduje.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    if (name == null) return;
    final loaded = ThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ThemeMode.system,
    );
    if (loaded != state) state = loaded;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}
