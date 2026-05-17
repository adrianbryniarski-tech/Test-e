import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:nasz_budzet_domowy/core/offline/pending_ops_dao.dart';
import 'package:nasz_budzet_domowy/core/offline/pending_transaction.dart';
import 'package:nasz_budzet_domowy/core/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stan działającego workera (dla UI).
enum SyncWorkerState { idle, syncing }

/// Worker który przepycha kolejkę pendingów do Supabase.
///
/// Tryby trigger'a:
/// - `start()` — przy starcie apki (gdy mamy już sesję usera).
/// - `Connectivity.onConnectivityChanged` → online → drain.
/// - `syncNow()` — manualny tap usera w ikonie statusu.
///
/// Reentrancy: drugi `_drain()` w trakcie pierwszego wraca natychmiast
/// (flag `_running`). Po pierwszym drain, jeśli w tym czasie ktoś wołał
/// `syncNow()`, robi się drugi run (flag `_pendingRun`).
class SyncWorker extends ChangeNotifier {
  SyncWorker(this._dao);

  final PendingOpsDao _dao;

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _started = false;

  bool _running = false;
  bool _pendingRun = false;

  SyncWorkerState _state = SyncWorkerState.idle;
  SyncWorkerState get state => _state;

  DateTime? _lastSyncAt;
  DateTime? get lastSyncAt => _lastSyncAt;

  String? _lastError;
  String? get lastError => _lastError;

  /// Startuje listener i robi pierwszy drain (jeśli mamy pendingi).
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      // 6.x emituje List<ConnectivityResult>. "Online" gdy COKOLWIEK
      // innego niż `none` siedzi w liście — wifi+cellular może być jedno
      // lub drugie, oba znaczą "mogę próbować".
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        // unawaited — listener nie czeka.
        _scheduleDrain();
      }
    });

    await _scheduleDrain();
  }

  /// Manualny trigger z UI (np. tap na ⏳).
  Future<void> syncNow() => _scheduleDrain();

  Future<void> _scheduleDrain() async {
    if (_running) {
      _pendingRun = true;
      return;
    }
    _running = true;
    try {
      do {
        _pendingRun = false;
        await _drain();
      } while (_pendingRun);
    } finally {
      _running = false;
    }
  }

  Future<void> _drain() async {
    if (supabase.auth.currentUser == null) return;

    final pendings = await _dao.listAll();
    if (pendings.isEmpty) return;

    _state = SyncWorkerState.syncing;
    notifyListeners();

    var hadError = false;
    for (final op in pendings) {
      try {
        await _pushOne(op);
        await _dao.remove(op.clientOpId);
      } on PostgrestException catch (e) {
        // 23505 = unique_violation. Może odpalić zarówno na `dedup_hash`
        // (ten zapis już jest w bazie — np. od drugiego małżonka),
        // jak i na `client_op_id` (retry tego samego op). W obu
        // przypadkach z punktu widzenia kolejki: "już dostarczony".
        if (e.code == '23505') {
          await _dao.remove(op.clientOpId);
          continue;
        }
        hadError = true;
        await _dao.markFailure(op.clientOpId, e.message);
        // RLS / kategoria nie istnieje / inne błędy "nieuleczalne sieciowo"
        // - przerywamy drain żeby nie spamować Supabase. User zobaczy
        // ⚠️ i może zdecydować co dalej.
        break;
      } on Object catch (e) {
        hadError = true;
        await _dao.markFailure(op.clientOpId, e.toString());
        // Sieciowy błąd — przerywamy. Następny event connectivity
        // odpali kolejny drain.
        break;
      }
    }

    _state = SyncWorkerState.idle;
    _lastSyncAt = DateTime.now();
    _lastError = hadError ? 'Niektóre operacje czekają na ponowną próbę' : null;
    notifyListeners();
  }

  Future<void> _pushOne(PendingTransaction op) async {
    await supabase
        .from('transactions')
        .insert(op.toSupabaseInsert())
        .select()
        .single();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }
}
