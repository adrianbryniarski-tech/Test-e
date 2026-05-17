import 'package:flutter/material.dart';

/// Material 3 + paleta low-stimulus dla fintech 2026.
///
/// Zasady:
/// - Tło off-white / very-dark-grey (nie czyste białe/czarne — mniej
///   zmęczenia oczu).
/// - Akcent zielony (income, success) i czerwony stonowany (expense,
///   danger) z palety kategorii — spójne z [CategoryPalette] (12 odcieni).
/// - Big typography (Display L dla salda, Headline M dla nagłówków kart).
/// - Font Inter (system) — czytelny, neutralny.
class AppTheme {
  const AppTheme._();

  static const Color _seedLight = Color(0xFF5B7AB9);
  static const Color _seedDark = Color(0xFF8FA8E0);

  // Paleta kategorii (12 niskobodźcowych odcieni) — używana spójnie w UI
  // (lista, pie, chipy, badge). Te same wartości w `category_palette.dart`.
  static const Color incomeAccent = Color(0xFF4AE89E);
  static const Color expenseAccent = Color(0xFFE07A7A);

  // Off-white / very-dark-grey, świadomie nie #FFFFFF / #000000.
  static const Color _lightBg = Color(0xFFF7F6F2);
  static const Color _darkBg = Color(0xFF121317);
  static const Color _lightSurface = Color(0xFFFCFBF8);
  static const Color _darkSurface = Color(0xFF1A1C22);

  static ThemeData get light => _build(
        brightness: Brightness.light,
        seed: _seedLight,
        bg: _lightBg,
        surface: _lightSurface,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        seed: _seedDark,
        bg: _darkBg,
        surface: _darkSurface,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color seed,
    required Color bg,
    required Color surface,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    ).copyWith(surface: surface);

    final base = brightness == Brightness.light
        ? ThemeData.light(useMaterial3: true)
        : ThemeData.dark(useMaterial3: true);

    final textTheme = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
      ),
      displayMedium: base.textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    // useMaterial3 jest defaultem w ThemeData.light()/.dark() od 3.16 —
    // explicit set już deprecated, więc tylko copyWith bez tej flagi.
    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
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
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
    );
  }
}

/// Paleta 12 odcieni dla kategorii (spójna z seedem migracji SQL).
class CategoryPalette {
  const CategoryPalette._();

  static const List<Color> palette = [
    Color(0xFF7AB87A), // zielony — Spożywcze
    Color(0xFF5B8FB9), // niebieski — Rachunki
    Color(0xFFE8A24A), // pomarańczowy — Transport
    Color(0xFFB97AB8), // fiołkowy — Rozrywka
    Color(0xFFE07A7A), // czerwony — Zdrowie
    Color(0xFFE8C24A), // żółty — Dzieci
    Color(0xFF8B7355), // brązowy — Mieszkanie
    Color(0xFFB95B8F), // różowy — Ubrania
    Color(0xFF4AE89E), // jasnozielony — Pensja (income)
    Color(0xFF7AE0D5), // turkus — Inne dochody (income)
    Color(0xFF5B7AB9), // granatowy — Oszczędności
    Color(0xFF94A3B8), // slate — Inne
  ];

  /// Kolor zastępczy gdy kategoria nie ma przypisanego koloru.
  static const Color fallback = Color(0xFF94A3B8);

  /// Parser hex → Color. Format `#RRGGBB`.
  static Color fromHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}
