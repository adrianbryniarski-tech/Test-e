import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase/supabase_client.dart';
import 'transaction.dart';

/// Wynik próby zapisu transakcji.
sealed class TransactionWriteResult {
  const TransactionWriteResult();
}

class TransactionWriteSuccess extends TransactionWriteResult {
  const TransactionWriteSuccess(this.transaction);
  final Transaction transaction;
}

/// Duplikat — `UNIQUE(household_id, dedup_hash)` zwrócił 23505.
class TransactionDuplicate extends TransactionWriteResult {
  const TransactionDuplicate();
}

class TransactionWriteFailure extends TransactionWriteResult {
  const TransactionWriteFailure(this.message);
  final String message;
}

/// CRUD + realtime na `transactions`.
class TransactionRepository {
  TransactionRepository() : _uuid = const Uuid();

  final Uuid _uuid;

  /// Strumień transakcji gospodarstwa, sortowany malejąco po dacie.
  /// `supabase.from(...).stream()` jest auto-subskrybowany do realtime,
  /// czyli emit po każdym INSERT/UPDATE/DELETE z innego klienta.
  Stream<List<Transaction>> watchAll(String householdId) {
    return supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('household_id', householdId)
        .order('occurred_at', ascending: false)
        .map((rows) => rows.map(Transaction.fromJson).toList());
  }

  /// Insert nowej transakcji.
  ///
  /// Klient kalkuluje `dedup_hash` (twarda deduplikacja) oraz
  /// `client_op_id` (idempotency dla offline kolejki — Part B Ticketu 4).
  /// Łapanie kodu Postgres 23505 → typed `TransactionDuplicate`
  /// żeby UI mógł pokazać "to już jest w bazie".
  Future<TransactionWriteResult> insert({
    required String householdId,
    required DateTime occurredAt,
    required int amountCents,
    required TransactionType type,
    required String categoryId,
    required TransactionSource source,
    String? description,
    String? note,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return const TransactionWriteFailure('Brak sesji — zaloguj się.');
    }

    final dedupHash = TransactionHasher.compute(
      occurredAt: occurredAt,
      amountCents: amountCents,
      description: description,
    );
    final clientOpId = _uuid.v4();

    try {
      final row = await supabase
          .from('transactions')
          .insert({
            'household_id': householdId,
            'created_by': user.id,
            'occurred_at': _dateOnly(occurredAt),
            'amount_cents': amountCents,
            'type': type.toDbValue(),
            'category_id': categoryId,
            'description': description,
            'note': note,
            'source': source.toDbValue(),
            'dedup_hash': dedupHash,
            'client_op_id': clientOpId,
          })
          .select()
          .single();
      return TransactionWriteSuccess(Transaction.fromJson(row));
    } on PostgrestException catch (e) {
      // 23505 = unique_violation. Może odpalić zarówno `dedup_hash`
      // jak i `client_op_id` (oba mają UNIQUE). Z punktu widzenia
      // usera oba znaczą "ten zapis już jest" — komunikat ten sam.
      if (e.code == '23505') return const TransactionDuplicate();
      return TransactionWriteFailure(
        'Nie udało się zapisać: ${e.message}',
      );
    } on Object catch (e) {
      return TransactionWriteFailure('Błąd zapisu: $e');
    }
  }

  Future<void> delete(String id) async {
    await supabase.from('transactions').delete().eq('id', id);
  }

  static String _dateOnly(DateTime dt) {
    final iso = DateTime.utc(dt.year, dt.month, dt.day).toIso8601String();
    return iso.substring(0, 10); // YYYY-MM-DD
  }
}
