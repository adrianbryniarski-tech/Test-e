import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/features/transactions/data/transaction.dart';

void main() {
  group('TransactionHasher.normalize', () {
    test('lower-case + strip diacritics', () {
      expect(
        TransactionHasher.normalize('Żabka KAWA łyk'),
        'zabka kawa lyk',
      );
    });

    test('zamienia interpunkcję na spacje i collapse', () {
      expect(
        TransactionHasher.normalize('Biedronka,  ul.Piękna'),
        'biedronka ul piekna',
      );
    });

    test('pusty string → pusty', () {
      expect(TransactionHasher.normalize(''), '');
    });

    test('tylko interpunkcja → pusty', () {
      expect(TransactionHasher.normalize(',,,...'), '');
    });
  });

  group('TransactionHasher.compute', () {
    test('determinizm: te same wejścia → ten sam hash', () {
      final date = DateTime(2026, 5, 17);
      final h1 = TransactionHasher.compute(
        occurredAt: date,
        amountCents: 1500,
        description: 'Biedronka',
      );
      final h2 = TransactionHasher.compute(
        occurredAt: date,
        amountCents: 1500,
        description: 'Biedronka',
      );
      expect(h1, h2);
      expect(h1.length, 64);
    });

    test('różne opisy ale po normalize ten sam → ten sam hash', () {
      final date = DateTime(2026, 5, 17);
      final h1 = TransactionHasher.compute(
        occurredAt: date,
        amountCents: 1500,
        description: 'Biedronka',
      );
      final h2 = TransactionHasher.compute(
        occurredAt: date,
        amountCents: 1500,
        description: 'BIEDRONKA  ',
      );
      expect(h1, h2);
    });

    test('różna kwota → różny hash', () {
      final date = DateTime(2026, 5, 17);
      final h1 = TransactionHasher.compute(
        occurredAt: date,
        amountCents: 1500,
        description: 'Biedronka',
      );
      final h2 = TransactionHasher.compute(
        occurredAt: date,
        amountCents: 1501,
        description: 'Biedronka',
      );
      expect(h1, isNot(h2));
    });

    test('różna data → różny hash', () {
      final h1 = TransactionHasher.compute(
        occurredAt: DateTime(2026, 5, 17),
        amountCents: 1500,
        description: 'Biedronka',
      );
      final h2 = TransactionHasher.compute(
        occurredAt: DateTime(2026, 5, 18),
        amountCents: 1500,
        description: 'Biedronka',
      );
      expect(h1, isNot(h2));
    });

    test('opis null vs pusty string → ten sam hash', () {
      final date = DateTime(2026, 5, 17);
      final h1 = TransactionHasher.compute(
        occurredAt: date,
        amountCents: 1500,
        description: null,
      );
      final h2 = TransactionHasher.compute(
        occurredAt: date,
        amountCents: 1500,
        description: '',
      );
      expect(h1, h2);
    });

    test('time-of-day NIE wpływa na hash (date only)', () {
      final h1 = TransactionHasher.compute(
        occurredAt: DateTime(2026, 5, 17, 8),
        amountCents: 1500,
        description: 'Biedronka',
      );
      final h2 = TransactionHasher.compute(
        occurredAt: DateTime(2026, 5, 17, 23, 59),
        amountCents: 1500,
        description: 'Biedronka',
      );
      expect(h1, h2);
    });
  });
}
