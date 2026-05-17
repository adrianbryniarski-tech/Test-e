import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/features/household/application/household_providers.dart';
import 'package:nasz_budzet_domowy/features/transactions/data/transaction.dart';
import 'package:nasz_budzet_domowy/features/transactions/data/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

/// Realtime lista transakcji bieżącego gospodarstwa. Refresh przy
/// zmianie `currentHouseholdIdProvider`.
final transactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final householdId = ref.watch(currentHouseholdIdProvider).value;
  if (householdId == null) {
    return Stream.value(const <Transaction>[]);
  }
  return ref.watch(transactionRepositoryProvider).watchAll(householdId);
});
