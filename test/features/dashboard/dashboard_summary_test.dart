import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/features/dashboard/application/date_range_filter.dart';
import 'package:nasz_budzet_domowy/features/dashboard/data/dashboard_summary.dart';
import 'package:nasz_budzet_domowy/features/transactions/data/transaction.dart';

Transaction _tx(
  int amount,
  TransactionType type,
  String cat,
  DateTime when,
) {
  return Transaction(
    id: 'tx-${when.microsecondsSinceEpoch}-$cat-$amount',
    householdId: 'h1',
    occurredAt: when,
    amountCents: amount,
    type: type,
    categoryId: cat,
    source: TransactionSource.manual,
    dedupHash: 'hash',
    createdAt: when,
  );
}

const _inc = TransactionType.income;
const _exp = TransactionType.expense;

void main() {
  // Zakres 10-dniowy → tryb dzienny w bar bucketach (days <= 14).
  final range = DateRangeFilter.custom(
    DateTime(2026, 5),
    DateTime(2026, 5, 10),
  );

  group('DashboardSummary.compute — sumy', () {
    test('rozdziela dochody i wydatki; saldo = dochód - wydatek', () {
      final current = [
        _tx(20000, _inc, 'wyplata', DateTime(2026, 5, 2)),
        _tx(5000, _exp, 'jedzenie', DateTime(2026, 5, 3)),
      ];

      final s = DashboardSummary.compute(current, const [], range);

      expect(s.totalIncomeCents, 20000);
      expect(s.totalExpenseCents, 5000);
      expect(s.balanceCents, 15000);
    });

    test('expenseByCategoryId sumuje wydatki po kategorii, pomija dochody', () {
      final current = [
        _tx(3000, _exp, 'jedzenie', DateTime(2026, 5, 2)),
        _tx(1500, _exp, 'jedzenie', DateTime(2026, 5, 4)),
        _tx(9000, _exp, 'auto', DateTime(2026, 5, 5)),
        _tx(50000, _inc, 'wyplata', DateTime(2026, 5)),
      ];

      final s = DashboardSummary.compute(current, const [], range);

      expect(s.expenseByCategoryId['jedzenie'], 4500);
      expect(s.expenseByCategoryId['auto'], 9000);
      expect(s.expenseByCategoryId.containsKey('wyplata'), isFalse);
    });

    test('delta liczona względem poprzedniego okresu', () {
      final current = [
        _tx(20000, _inc, 'c', DateTime(2026, 5, 2)),
        _tx(5000, _exp, 'c', DateTime(2026, 5, 3)),
      ];
      final previous = [
        _tx(10000, _inc, 'c', DateTime(2026, 4, 2)),
        _tx(3000, _exp, 'c', DateTime(2026, 4, 3)),
      ];

      final s = DashboardSummary.compute(current, previous, range);

      expect(s.prevBalanceCents, 7000); // 10000 - 3000
      expect(s.balanceCents, 15000); // 20000 - 5000
      expect(s.deltaCents, 8000); // 15000 - 7000
    });

    test('puste listy → zera, brak wyjątku', () {
      final s = DashboardSummary.compute(const [], const [], range);
      expect(s.totalIncomeCents, 0);
      expect(s.totalExpenseCents, 0);
      expect(s.balanceCents, 0);
      expect(s.deltaCents, 0);
      expect(s.expenseByCategoryId, isEmpty);
      expect(s.barBuckets, isEmpty);
      expect(s.runningBalancePoints, isEmpty);
    });
  });

  group('DashboardSummary.compute — wykresy', () {
    test('bar buckets (tryb dzienny) grupują dochód/wydatek per dzień', () {
      final current = [
        _tx(10000, _inc, 'c', DateTime(2026, 5, 2, 9)),
        _tx(4000, _exp, 'c', DateTime(2026, 5, 2, 18)),
        _tx(2000, _exp, 'c', DateTime(2026, 5, 5)),
      ];

      final s = DashboardSummary.compute(current, const [], range);

      expect(s.barBuckets.length, 2);
      final day2 = s.barBuckets.firstWhere(
        (b) => b.date == DateTime(2026, 5, 2),
      );
      expect(day2.incomeCents, 10000);
      expect(day2.expenseCents, 4000);
      final day5 = s.barBuckets.firstWhere(
        (b) => b.date == DateTime(2026, 5, 5),
      );
      expect(day5.expenseCents, 2000);
      expect(day5.incomeCents, 0);
      // Posortowane rosnąco po dacie.
      expect(s.barBuckets.first.date.isBefore(s.barBuckets.last.date), isTrue);
    });

    test('running balance kumuluje saldo dzień po dniu', () {
      final current = [
        _tx(10000, _inc, 'c', DateTime(2026, 5, 2)),
        _tx(4000, _exp, 'c', DateTime(2026, 5, 4)),
      ];

      final s = DashboardSummary.compute(current, const [], range);

      expect(s.runningBalancePoints.length, 2);
      expect(s.runningBalancePoints.first.balanceCents, 10000);
      expect(s.runningBalancePoints.last.balanceCents, 6000); // 10000 - 4000
    });
  });
}
