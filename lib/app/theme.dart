import 'package:flutter/material.dart';

/// Warianty motywu graficznego. Każdy zachowuje Material 3 jako fundament,
/// ale różni się paletą, tłem, kształtami i typografią. User wybiera w
/// Ustawieniach; wybór persistowany w `shared_preferences`.
///
/// Trendy 2026 (zgodnie z research'em):
/// - Material 3 Expressive — żywe kolory, customizable themes
/// - Glassmorphism refined — szkło używane "chirurgicznie" na cards
/// - Minimalism with functionality — biel/przestrzeń, big typography
/// - Bold typography — duże nagłówki, czytelne cyfry
/// - Dark mode native — first class citizen
enum AppThemeVariant {
  spokojny(
    label: 'Spokojny',
    description: 'Niskobodźcowe pastele, kremowe tło. Dla skupionej pracy.',
  ),
  expressive(
    label: 'Material You',
    description: 'Żywe kolory Material 3 Expressive. Domyślny Android 2026.',
  ),
  szklo(
    label: 'Szkło',
    description: 'Pastele i półprzezroczystości w stylu glassmorphism.',
  ),
  zachod(
    label: 'Zachód',
    description: 'Ciepłe gradienty koralu i bursztynu. Domowa atmosfera.',
  ),
  mono(
    label: 'Mono',
    description: 'Czarno-białe minimum z jednym akcentem. Brutalist 2026.',
  ),
  cyber(
    label: 'Cyber',
    description:
        'Neonowy zielony + czarne OLED. Cyberpunk 2026 — najlepszy w '
        'trybie ciemnym.',
  ),
  synthwave(
    label: 'Synthwave',
    description:
        'Magenta + cyan retro 80s. Mocny vibe, świetlist w ciemnym.',
  ),
  galaktyka(
    label: 'Galaktyka',
    description:
        'Deep space purple/indigo + neonowe gwiazdy. Głęboka czerń OLED '
        'z fioletowymi akcentami.',
  );

  const AppThemeVariant({required this.label, required this.description});

  final String label;
  final String description;

  /// Czy motyw używa "premium" efektów neon: gradient tła, glow buttons,
  /// animated borders. Tylko dla 3 neon-tematów.
  bool get hasNeonEffects =>
      this == AppThemeVariant.cyber ||
      this == AppThemeVariant.synthwave ||
      this == AppThemeVariant.galaktyka;

  /// Drugi kolor dla gradientu tła (poza primary z ColorScheme).
  /// Używany w `NeonGradientBackground` do subtle gradient'u.
  Color get gradientAccent => switch (this) {
        AppThemeVariant.cyber => const Color(0xFF00D9C0),
        AppThemeVariant.synthwave => const Color(0xFF6CC7FF),
        AppThemeVariant.galaktyka => const Color(0xFFFF6CD9),
        _ => const Color(0xFF000000),
      };
}

/// Builder ThemeData dla wszystkich wariantów. Wybiera między 5 stylami
/// + jasny/ciemny tryb.
class AppTheme {
  const AppTheme._();

  // Akcenty INCOME/EXPENSE są STAŁE między motywami — finanse muszą być
  // czytelne jednakowo wszędzie (zielony = dochód, czerwony = wydatek).
  static const Color incomeAccent = Color(0xFF4AE89E);
  static const Color expenseAccent = Color(0xFFE07A7A);

  static ThemeData light(AppThemeVariant variant) =>
      _build(variant, Brightness.light);
  static ThemeData dark(AppThemeVariant variant) =>
      _build(variant, Brightness.dark);

  static ThemeData _build(AppThemeVariant variant, Brightness brightness) {
    final spec = _specFor(variant, brightness);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: spec.seed,
      brightness: brightness,
    ).copyWith(surface: spec.surface);

    final base = brightness == Brightness.light
        ? ThemeData.light(useMaterial3: true)
        : ThemeData.dark(useMaterial3: true);

    final textTheme = _textThemeFor(base.textTheme, variant);
    final borderRadius = _borderRadiusFor(variant);

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: spec.background,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: spec.surface,
        elevation: spec.cardElevation,
        shadowColor:
            spec.cardElevation > 0 ? colorScheme.shadow : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: spec.background,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius * 0.8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: spec.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius * 0.7),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius * 0.7),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius * 0.7),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: spec.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius * 1.2),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
    );
  }

  static _ThemeSpec _specFor(AppThemeVariant variant, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (variant) {
      AppThemeVariant.spokojny => _ThemeSpec(
          seed: isDark ? const Color(0xFF8FA8E0) : const Color(0xFF5B7AB9),
          background:
              isDark ? const Color(0xFF121317) : const Color(0xFFF7F6F2),
          surface: isDark ? const Color(0xFF1A1C22) : const Color(0xFFFCFBF8),
          cardElevation: 0,
        ),
      AppThemeVariant.expressive => _ThemeSpec(
          seed: const Color(0xFF6750A4),
          background:
              isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFEF7FF),
          surface: isDark ? const Color(0xFF2B2930) : const Color(0xFFF7F2FA),
          cardElevation: 1,
        ),
      AppThemeVariant.szklo => _ThemeSpec(
          seed: isDark ? const Color(0xFF8FCFEC) : const Color(0xFF5BA8D9),
          background:
              isDark ? const Color(0xFF0F1620) : const Color(0xFFEEF4FB),
          surface: isDark
              ? const Color(0xFF1A2330).withValues(alpha: 0.85)
              : const Color(0xFFFFFFFF).withValues(alpha: 0.7),
          cardElevation: 2,
        ),
      AppThemeVariant.zachod => _ThemeSpec(
          seed: isDark ? const Color(0xFFFFAB8E) : const Color(0xFFE07A4F),
          background:
              isDark ? const Color(0xFF1E1612) : const Color(0xFFFDF4ED),
          surface: isDark ? const Color(0xFF2A1F18) : const Color(0xFFFFF8F1),
          cardElevation: 0,
        ),
      AppThemeVariant.mono => _ThemeSpec(
          seed: const Color(0xFF65D946),
          background:
              isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
          surface: isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F2),
          cardElevation: 0,
        ),

      // Cyberpunk neon — najjaskrawszy w dark mode, OLED-friendly czerń.
      // Neonowy zielony (jak Matrix) na pure black tle.
      AppThemeVariant.cyber => _ThemeSpec(
          seed: isDark ? const Color(0xFF00FF88) : const Color(0xFF00C46A),
          background:
              isDark ? const Color(0xFF000000) : const Color(0xFFF0FAF5),
          surface: isDark ? const Color(0xFF0A1410) : const Color(0xFFE0F7E8),
          cardElevation: isDark ? 0 : 1,
        ),

      // Synthwave / retro 80s — magenta + cyan, neonowy glow w ciemnym.
      AppThemeVariant.synthwave => _ThemeSpec(
          seed: isDark ? const Color(0xFFFF3EA5) : const Color(0xFFE91E63),
          background:
              isDark ? const Color(0xFF0D0421) : const Color(0xFFFFF0F8),
          surface: isDark ? const Color(0xFF1A0935) : const Color(0xFFFEE0F0),
          cardElevation: isDark ? 0 : 1,
        ),

      // Deep space / galaxy — fioletowo-indigo na pure black, neonowe
      // gwiazdy. Wow factor dla dark, lekkie pastele dla light.
      AppThemeVariant.galaktyka => _ThemeSpec(
          seed: isDark ? const Color(0xFFB36CFF) : const Color(0xFF7C4DFF),
          background:
              isDark ? const Color(0xFF030014) : const Color(0xFFF5F0FF),
          surface: isDark ? const Color(0xFF120829) : const Color(0xFFEAE0FF),
          cardElevation: isDark ? 0 : 1,
        ),
    };
  }

  static double _borderRadiusFor(AppThemeVariant variant) {
    return switch (variant) {
      AppThemeVariant.spokojny => 20,
      AppThemeVariant.expressive => 24,
      AppThemeVariant.szklo => 28,
      AppThemeVariant.zachod => 22,
      AppThemeVariant.mono => 4,
      AppThemeVariant.cyber => 8, // ostry, terminal-like
      AppThemeVariant.synthwave => 16,
      AppThemeVariant.galaktyka => 24,
    };
  }

  static TextTheme _textThemeFor(TextTheme base, AppThemeVariant variant) {
    final common = base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    if (variant == AppThemeVariant.mono) {
      return common.copyWith(
        displayLarge: common.displayLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -2.5,
        ),
        displayMedium: common.displayMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
        ),
        headlineMedium: common.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        titleLarge: common.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      );
    }

    // Cyber — szerokie letter-spacing dla "terminal" feel.
    if (variant == AppThemeVariant.cyber) {
      return common.copyWith(
        displayLarge: common.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        displayMedium: common.displayMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      );
    }

    return common;
  }
}

class _ThemeSpec {
  const _ThemeSpec({
    required this.seed,
    required this.background,
    required this.surface,
    required this.cardElevation,
  });

  final Color seed;
  final Color background;
  final Color surface;
  final double cardElevation;
}

/// Paleta 12 odcieni dla kategorii (spójna z seedem migracji SQL).
class CategoryPalette {
  const CategoryPalette._();

  static const List<Color> palette = [
    Color(0xFF7AB87A),
    Color(0xFF5B8FB9),
    Color(0xFFE8A24A),
    Color(0xFFB97AB8),
    Color(0xFFE07A7A),
    Color(0xFFE8C24A),
    Color(0xFF8B7355),
    Color(0xFFB95B8F),
    Color(0xFF4AE89E),
    Color(0xFF7AE0D5),
    Color(0xFF5B7AB9),
    Color(0xFF94A3B8),
  ];

  static const Color fallback = Color(0xFF94A3B8);

  static Color fromHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}
