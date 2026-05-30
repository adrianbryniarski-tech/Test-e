import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/features/budgets/application/budget_providers.dart';
import 'package:nasz_budzet_domowy/features/budgets/data/budget.dart';
import 'package:nasz_budzet_domowy/features/dashboard/application/date_range_filter.dart';
import 'package:nasz_budzet_domowy/features/dashboard/data/dashboard_summary.dart';
import 'package:nasz_budzet_domowy/features/transactions/application/transaction_providers.dart';
import 'package:nasz_budzet_domowy/features/transactions/data/transaction.dart';

/// Transakcje odfiltrowane do aktywnego zakresu dat.
final filteredTransactionsProvider =
    Provider<AsyncValue<List<Transaction>>>((ref) {
  final all = ref.watch(transactionsProvider);
  final range = ref.watch(dateRangeFilterProvider);
  return all.whenData(
    (txs) => txs
        .where(
          (t) =>
              !t.occurredAt.isBefore(range.start) &&
              !t.occurredAt.isAfter(range.end),
        )
        .toList(),
  );
});

/// Podsumowanie dashboardu — obliczone z przefiltrowanych transakcji.
/// Poprzedni okres pobierany z tego samego strumienia (client-side filter).
final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  final allAsync = ref.watch(transactionsProvider);
  final filteredAsync = ref.watch(filteredTransactionsProvider);
  final range = ref.watch(dateRangeFilterProvider);

  return filteredAsync.whenData((current) {
    final prevRange = range.previousPeriod;
    final previous = allAsync.value
            ?.where(
              (t) =>
                  !t.occurredAt.isBefore(prevRange.start) &&
                  !t.occurredAt.isAfter(prevRange.end),
            )
            .toList() ??
        const [];
    return DashboardSummary.compute(current, previous, range);
  });
});

/// Postęp budżetów liczony dla AKTYWNEGO zakresu dat dashboardu.
///
/// Limit pozostaje z definicji budżetu (miesięczny), ale wydatki sumujemy
/// z wybranego okresu (`dashboardSummaryProvider.expenseByCategoryId`) —
/// dzięki temu panel „Wydatki wg kategorii" na pulpicie reaguje na zmianę
/// zakresu, tak jak reszta KPI. To odróżnia go od
/// [monthlyBudgetProgressProvider], który zawsze liczy bieżący miesiąc
/// (używany na ekranie Budżetów).
final periodBudgetProgressProvider = Provider<List<BudgetProgress>>((ref) {
  final allBudgets = ref.watch(budgetsProvider).value ?? const [];
  final spend =
      ref.watch(dashboardSummaryProvider).value?.expenseByCategoryId ??
          const <String, int>{};
  final today = DateTime.now();

  // Najnowszy budżet per kategoria z `starts_on <= dziś` (jak w wersji
  // miesięcznej — obsługuje kwoty ustawiane z wyprzedzeniem).
  final byCategory = <String, Budget>{};
  for (final b in allBudgets) {
    if (b.startsOn.isAfter(today)) continue;
    final existing = byCategory[b.categoryId];
    if (existing == null || b.startsOn.isAfter(existing.startsOn)) {
      byCategory[b.categoryId] = b;
    }
  }

  return byCategory.values
      .map(
        (b) => BudgetProgress(
          budget: b,
          spentCents: spend[b.categoryId] ?? 0,
        ),
      )
      .toList()
    ..sort((a, b) => b.fraction.compareTo(a.fraction));
});
