import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../household/application/household_providers.dart';
import '../data/transaction.dart';
import '../data/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

/// Realtime lista transakcji bieżącego gospodarstwa. Refresh przy
/// zmianie `currentHouseholdIdProvider`.
final transactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final householdId = ref.watch(currentHouseholdIdProvider).valueOrNull;
  if (householdId == null) {
    return Stream.value(const <Transaction>[]);
  }
  return ref.watch(transactionRepositoryProvider).watchAll(householdId);
});
