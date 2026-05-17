import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category.dart';
import 'package:nasz_budzet_domowy/features/transactions/application/voice_parser.dart';
import 'package:nasz_budzet_domowy/features/transactions/data/transaction.dart';

void main() {
  // Minimalny zestaw kategorii do testów parsera.
  final cats = [
    const Category(
      id: 'cat-spozy',
      householdId: 'hh-1',
      name: 'Spożywcze',
      icon: 'shopping_cart',
      colorHex: '#7AB87A',
      type: TransactionType.expense,
      isSystem: true,
    ),
    const Category(
      id: 'cat-trans',
      householdId: 'hh-1',
      name: 'Transport',
      icon: 'directions_car',
      colorHex: '#E8A24A',
      type: TransactionType.expense,
      isSystem: true,
    ),
    const Category(
      id: 'cat-zdrowie',
      householdId: 'hh-1',
      name: 'Zdrowie',
      icon: 'local_pharmacy',
      colorHex: '#E07A7A',
      type: TransactionType.expense,
      isSystem: true,
    ),
    const Category(
      id: 'cat-pensja',
      householdId: 'hh-1',
      name: 'Pensja',
      icon: 'payments',
      colorHex: '#4AE89E',
      type: TransactionType.income,
      isSystem: true,
    ),
  ];

  late VoiceParser parser;

  setUp(() {
    parser = VoiceParser(cats);
  });

  group('VoiceParser kwota', () {
    test('150 złotych → 15000 centów', () {
      final r = parser.parse('150 złotych Biedronka');
      expect(r.amountCents, 15000);
    });

    test('29,99 zł → 2999 centów', () {
      final r = parser.parse('29,99 zł zakupy');
      expect(r.amountCents, 2999);
    });

    test('brak kwoty → null', () {
      final r = parser.parse('byłem w sklepie');
      expect(r.amountCents, isNull);
    });

    test('100.50 zł → 10050', () {
      final r = parser.parse('100.50 zł paliwo');
      expect(r.amountCents, 10050);
    });
  });

  group('VoiceParser data', () {
    test('wczoraj → data wczorajsza', () {
      final r = parser.parse('50 zł wczoraj Biedronka');
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(r.occurredAt?.day, yesterday.day);
      expect(r.occurredAt?.month, yesterday.month);
    });

    test('dziś → data dzisiejsza', () {
      final r = parser.parse('20 zł dziś zakupy');
      final today = DateTime.now();
      expect(r.occurredAt?.day, today.day);
    });

    test('brak daty → dzisiaj (default)', () {
      final r = parser.parse('200 zł zakupy');
      final today = DateTime.now();
      expect(r.occurredAt?.day, today.day);
    });
  });

  group('VoiceParser kategoria', () {
    test('Biedronka → Spożywcze', () {
      final r = parser.parse('150 złotych Biedronka wczoraj');
      expect(r.categoryId, 'cat-spozy');
      expect(r.categoryName, 'Spożywcze');
    });

    test('paliwo → Transport', () {
      final r = parser.parse('100 zł paliwo na Orlenie');
      expect(r.categoryId, 'cat-trans');
    });

    test('apteka → Zdrowie', () {
      final r = parser.parse('35 zł apteka leki');
      expect(r.categoryId, 'cat-zdrowie');
    });

    test('brak aliasu → null', () {
      final r = parser.parse('500 zł bardzo dziwna rzecz');
      expect(r.categoryId, isNull);
    });
  });

  group('VoiceParser typ', () {
    test('pensja → income', () {
      final r = parser.parse('5000 zł pensja');
      expect(r.type, TransactionType.income);
    });

    test('zakupy → expense', () {
      final r = parser.parse('150 zł zakupy Biedronka');
      expect(r.type, TransactionType.expense);
    });

    test('zarobiłem → income', () {
      final r = parser.parse('zarobiłem 200 zł premia');
      expect(r.type, TransactionType.income);
    });
  });

  group('VoiceParser pełny przykład', () {
    test('"150 złotych Biedronka wczoraj"', () {
      final r = parser.parse('150 złotych Biedronka wczoraj');
      expect(r.amountCents, 15000);
      expect(r.categoryId, 'cat-spozy');
      expect(r.type, TransactionType.expense);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(r.occurredAt?.day, yesterday.day);
    });
  });
}
