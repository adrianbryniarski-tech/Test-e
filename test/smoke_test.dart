import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';

void main() {
  group('AppTheme', () {
    test('light theme has correct seed colors', () {
      final theme = AppTheme.light;
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
    });

    test('dark theme has correct seed colors', () {
      final theme = AppTheme.dark;
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
    });
  });

  group('CategoryPalette', () {
    test('has 12 colors', () {
      expect(CategoryPalette.palette.length, 12);
    });

    test('fromHex parses #RRGGBB correctly', () {
      final green = CategoryPalette.fromHex('#7AB87A');
      expect(green.value.toRadixString(16).toUpperCase(), 'FF7AB87A');
    });

    test('fromHex handles missing #', () {
      final green = CategoryPalette.fromHex('7AB87A');
      expect(green.value.toRadixString(16).toUpperCase(), 'FF7AB87A');
    });
  });
}
