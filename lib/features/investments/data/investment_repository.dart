import 'package:nasz_budzet_domowy/core/supabase/supabase_client.dart';
import 'package:nasz_budzet_domowy/features/investments/data/investment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

sealed class InvestmentWriteResult {
  const InvestmentWriteResult();
}

class InvestmentWriteSuccess extends InvestmentWriteResult {
  const InvestmentWriteSuccess();
}

class InvestmentWriteFailure extends InvestmentWriteResult {
  const InvestmentWriteFailure(this.message);
  final String message;
}

class InvestmentRepository {
  const InvestmentRepository();

  Stream<List<Investment>> watchAll(String householdId) {
    return supabase
        .from('investments')
        .stream(primaryKey: ['id'])
        .eq('household_id', householdId)
        .order('created_at')
        .map((rows) => rows.map(Investment.fromJson).toList());
  }

  Future<InvestmentWriteResult> insert(Investment inv) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return const InvestmentWriteFailure('Brak sesji — zaloguj się.');
    }
    try {
      await supabase.from('investments').insert(inv.toInsert(user.id));
      return const InvestmentWriteSuccess();
    } on PostgrestException catch (e) {
      return InvestmentWriteFailure('${e.code ?? "?"} ${e.message}');
    }
  }

  Future<InvestmentWriteResult> delete(String id) async {
    try {
      await supabase.from('investments').delete().eq('id', id);
      return const InvestmentWriteSuccess();
    } on PostgrestException catch (e) {
      return InvestmentWriteFailure(e.message);
    }
  }

  /// Strumień dziennych snapshotów wartości portfela (do wykresu).
  Stream<List<PortfolioSnapshot>> watchSnapshots(String householdId) {
    return supabase
        .from('portfolio_snapshots')
        .stream(primaryKey: ['id'])
        .eq('household_id', householdId)
        .order('captured_at')
        .map((rows) => rows.map(PortfolioSnapshot.fromJson).toList());
  }

  /// Upsert dziennego snapshotu (jeden na (gospodarstwo, dzień)).
  /// Wywoływane po przeliczeniu wartości portfela.
  Future<void> upsertSnapshot({
    required String householdId,
    required int totalValueCents,
  }) async {
    final today = DateTime.now();
    final date = '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    try {
      await supabase.from('portfolio_snapshots').upsert(
        {
          'household_id': householdId,
          'total_value_cents': totalValueCents,
          'captured_at': date,
        },
        onConflict: 'household_id,captured_at',
      );
    } on Object {
      // snapshot to bonus — błąd nie blokuje wyświetlania portfela
    }
  }
}
