import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category_repository.dart';
import 'package:nasz_budzet_domowy/features/household/application/household_providers.dart';
import 'package:nasz_budzet_domowy/features/transactions/application/transaction_providers.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return const CategoryRepository();
});

/// Lista kategorii gospodarstwa. Auto-reload przy zmianie householdId.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final householdId = ref.watch(currentHouseholdIdProvider).value;
  if (householdId == null) {
    return Stream.value(const <Category>[]);
  }
  return ref.watch(categoryRepositoryProvider).watchAll(householdId);
});

/// Liczba transakcji per kategoria (`categoryId → count`). Liczona z aktualnej
/// listy transakcji w pamięci — bez extra zapytania do bazy. Dla naszej skali
/// (~setki transakcji) to OK.
final transactionCountByCategoryProvider = Provider<Map<String, int>>((ref) {
  final txs = ref.watch(transactionsProvider).value ?? const [];
  final result = <String, int>{};
  for (final t in txs) {
    result.update(t.categoryId, (v) => v + 1, ifAbsent: () => 1);
  }
  return result;
});
