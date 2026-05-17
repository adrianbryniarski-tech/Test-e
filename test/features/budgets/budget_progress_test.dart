import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/features/budgets/data/budget.dart';

void main() {
  Budget budget(int amountCents) => Budget(
        id: 'b-1',
        householdId: 'h-1',
        categoryId: 'cat-1',
        amountCents: amountCents,
        startsOn: DateTime(2026, 5),
      );

  group('BudgetProgress', () {
    test('fraction = wydatki / limit', () {
      final p = BudgetProgress(budget: budget(10000), spentCents: 3500);
      expect(p.fraction, closeTo(0.35, 1e-9));
    });

    test('isExceeded gdy wydatki > limit', () {
      final p = BudgetProgress(budget: budget(10000), spentCents: 10001);
      expect(p.isExceeded, isTrue);
      expect(p.isNearLimit, isFalse);
    });

    test('isNearLimit gdy 80%-100% (granice włącznie / wyłącznie)', () {
      expect(
        BudgetProgress(budget: budget(10000), spentCents: 7999).isNearLimit,
        isFalse,
        reason: '79.99% — jeszcze nie w "near"',
      );
      expect(
        BudgetProgress(budget: budget(10000), spentCents: 8000).isNearLimit,
        isTrue,
        reason: '80% — granica włączona',
      );
      expect(
        BudgetProgress(budget: budget(10000), spentCents: 10000).isNearLimit,
        isTrue,
        reason: '100% — równo limit, nie przekroczone',
      );
      expect(
        BudgetProgress(budget: budget(10000), spentCents: 10001).isNearLimit,
        isFalse,
        reason: 'powyżej 100% to już isExceeded, nie isNearLimit',
      );
    });

    test('fraction = 0 dla zerowego budżetu (brak dzielenia przez 0)', () {
      final p = BudgetProgress(budget: budget(0), spentCents: 500);
      expect(p.fraction, 0);
      // Schema constraint amount_cents > 0 nie pozwala stworzyć takiego
      // budżetu w bazie, ale defensywnie nie crashujemy w modelu.
    });
  });
}
