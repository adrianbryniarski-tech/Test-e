/// Konfiguracja przekazywana przez `--dart-define` przy buildzie.
///
/// Przykład:
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ...
/// ```
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String appVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: 'dev');
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  static bool get isSentryEnabled => sentryDsn.isNotEmpty;

  /// Wywołać w `main()` przed bootstrapem.
  ///
  /// Wyrzuca `StateError` z czytelnym komunikatem gdy brakuje krytycznych
  /// zmiennych — łatwiej diagnozować niż null pointer głębiej w stack.
  static void assertConfigured() {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');
    if (missing.isNotEmpty) {
      throw StateError(
        'Brakuje wymaganych zmiennych --dart-define: ${missing.join(', ')}. '
        'Patrz README.md sekcja "Zmienne środowiskowe".',
      );
    }
  }
}
