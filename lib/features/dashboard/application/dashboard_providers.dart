import 'package:flutter_riverpod/flutter_riverpod.dart';
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
final dashboardSummaryProvider =
    Provider<AsyncValue<DashboardSummary>>((ref) {
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
