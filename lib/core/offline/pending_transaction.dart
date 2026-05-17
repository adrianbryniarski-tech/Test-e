import 'package:nasz_budzet_domowy/features/transactions/data/transaction.dart';

/// Transakcja zakolejkowana do wysyłki — fizycznie w lokalnym SQLite.
///
/// Mapowanie 1:1 na kolumny tabeli `pending_transactions` (patrz `LocalDb`).
/// Po udanym sync rekord jest usuwany; jeśli sync padł (sieć / RLS),
/// `lastError` + `retryCount` rosną i czekają na kolejny retry.
class PendingTransaction {
  const PendingTransaction({
    required this.clientOpId,
    required this.householdId,
    required this.occurredAt,
    required this.amountCents,
    required this.type,
    required this.categoryId,
    required this.source,
    required this.dedupHash,
    required this.enqueuedAt,
    required this.retryCount,
    this.createdBy,
    this.description,
    this.note,
    this.lastError,
  });

  factory PendingTransaction.fromMap(Map<String, Object?> row) {
    return PendingTransaction(
      clientOpId: row['client_op_id']! as String,
      householdId: row['household_id']! as String,
      createdBy: row['created_by'] as String?,
      occurredAt: DateTime.parse(row['occurred_at']! as String),
      amountCents: (row['amount_cents']! as num).toInt(),
      type: TransactionType.fromDbValue(row['type']! as String),
      categoryId: row['category_id']! as String,
      description: row['description'] as String?,
      note: row['note'] as String?,
      source: TransactionSource.fromDbValue(row['source']! as String),
      dedupHash: row['dedup_hash']! as String,
      enqueuedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['enqueued_at']! as num).toInt(),
      ),
      lastError: row['last_error'] as String?,
      retryCount: (row['retry_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String clientOpId;
  final String householdId;
  final String? createdBy;
  final DateTime occurredAt;
  final int amountCents;
  final TransactionType type;
  final String categoryId;
  final String? description;
  final String? note;
  final TransactionSource source;
  final String dedupHash;
  final DateTime enqueuedAt;
  final String? lastError;
  final int retryCount;

  Map<String, Object?> toMap() => {
        'client_op_id': clientOpId,
        'household_id': householdId,
        'created_by': createdBy,
        'occurred_at': _dateOnly(occurredAt),
        'amount_cents': amountCents,
        'type': type.toDbValue(),
        'category_id': categoryId,
        'description': description,
        'note': note,
        'source': source.toDbValue(),
        'dedup_hash': dedupHash,
        'enqueued_at': enqueuedAt.millisecondsSinceEpoch,
        'last_error': lastError,
        'retry_count': retryCount,
      };

  /// Payload do `supabase.from('transactions').insert(...)`.
  Map<String, Object?> toSupabaseInsert() => {
        'household_id': householdId,
        'created_by': createdBy,
        'occurred_at': _dateOnly(occurredAt),
        'amount_cents': amountCents,
        'type': type.toDbValue(),
        'category_id': categoryId,
        'description': description,
        'note': note,
        'source': source.toDbValue(),
        'dedup_hash': dedupHash,
        'client_op_id': clientOpId,
      };

  /// Konwersja na [Transaction] dla widoku listy. `id = clientOpId` jest
  /// tymczasowy do czasu synchronizacji — UI traktuje to jako stabilny
  /// klucz w `ListView`.
  Transaction toDisplayTransaction() => Transaction(
        id: clientOpId,
        householdId: householdId,
        createdBy: createdBy,
        occurredAt: occurredAt,
        amountCents: amountCents,
        type: type,
        categoryId: categoryId,
        description: description,
        note: note,
        source: source,
        dedupHash: dedupHash,
        clientOpId: clientOpId,
        createdAt: enqueuedAt,
        isPending: true,
      );

  static String _dateOnly(DateTime dt) {
    final iso = DateTime.utc(dt.year, dt.month, dt.day).toIso8601String();
    return iso.substring(0, 10);
  }
}
