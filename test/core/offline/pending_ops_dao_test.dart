import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/core/offline/local_db.dart';
import 'package:nasz_budzet_domowy/core/offline/pending_ops_dao.dart';
import 'package:nasz_budzet_domowy/core/offline/pending_transaction.dart';
import 'package:nasz_budzet_domowy/features/transactions/data/transaction.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late LocalDb db;
  late PendingOpsDao dao;

  setUp(() async {
    db = LocalDb(fixedPath: inMemoryDatabasePath);
    dao = PendingOpsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  PendingTransaction makeOp({
    String clientOpId = 'op-1',
    String householdId = 'h-1',
    int amountCents = 1500,
  }) {
    return PendingTransaction(
      clientOpId: clientOpId,
      householdId: householdId,
      occurredAt: DateTime(2026, 5, 17),
      amountCents: amountCents,
      type: TransactionType.expense,
      categoryId: 'cat-1',
      source: TransactionSource.manual,
      dedupHash: 'hash-$clientOpId-$amountCents',
      enqueuedAt: DateTime(2026, 5, 17, 12),
      retryCount: 0,
    );
  }

  test('enqueue + listAll round-trip', () async {
    await dao.enqueue(makeOp());
    final all = await dao.listAll();
    expect(all, hasLength(1));
    expect(all.first.clientOpId, 'op-1');
    expect(all.first.amountCents, 1500);
  });

  test('enqueue tego samego client_op_id — ignored (idempotency)', () async {
    await dao.enqueue(makeOp());
    await dao.enqueue(makeOp(amountCents: 9999));
    final all = await dao.listAll();
    expect(all, hasLength(1));
    // Zachowany pierwszy zapis — drugi został zignorowany.
    expect(all.first.amountCents, 1500);
  });

  test('listForHousehold filtruje po household_id', () async {
    await dao.enqueue(makeOp(clientOpId: 'a'));
    await dao.enqueue(makeOp(clientOpId: 'b', householdId: 'h-2'));
    final h1 = await dao.listForHousehold('h-1');
    expect(h1, hasLength(1));
    expect(h1.first.clientOpId, 'a');
  });

  test('remove kasuje rekord', () async {
    await dao.enqueue(makeOp());
    await dao.remove('op-1');
    expect(await dao.listAll(), isEmpty);
  });

  test('markFailure ustawia error + zwiększa retry_count', () async {
    await dao.enqueue(makeOp());
    await dao.markFailure('op-1', 'network timeout');
    await dao.markFailure('op-1', 'network timeout');
    final all = await dao.listAll();
    expect(all.first.lastError, 'network timeout');
    expect(all.first.retryCount, 2);
  });

  test('countWithErrors zlicza tylko z lastError', () async {
    await dao.enqueue(makeOp(clientOpId: 'a'));
    await dao.enqueue(makeOp(clientOpId: 'b'));
    await dao.markFailure('a', 'boom');
    expect(await dao.countAll(), 2);
    expect(await dao.countWithErrors(), 1);
  });

  test('watchForHousehold emituje przy każdej zmianie', () async {
    final stream = dao.watchForHousehold('h-1');
    final events = <int>[];
    final sub = stream.listen((list) => events.add(list.length));
    // Pierwsza wartość: pusta lista.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(events.last, 0);

    await dao.enqueue(makeOp(clientOpId: 'a'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(events.last, 1);

    await dao.enqueue(makeOp(clientOpId: 'b'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(events.last, 2);

    await dao.remove('a');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(events.last, 1);

    await sub.cancel();
  });
}
