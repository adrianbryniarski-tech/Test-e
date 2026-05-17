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
/// Postgres error codes po których nie ma sensu retry'ować — zmiana danych
/// w DB nie naprawi błędu deterministycznego (np. FK violation = kategoria
/// nie istnieje, RLS = brak uprawnień). Po takim błędzie inkrementujemy
/// retry_count + idziemy do następnej op. Po `maxRetries` op trafia do
/// dead-letter w DAO i jest pomijana.
const _permanentPgErrorCodes = <String>{
  '23502', // not_null_violation
  '23503', // foreign_key_violation (np. category_id usunięty)
  '23514', // check_violation
  '42501', // insufficient_privilege (RLS odrzuciło)
  '22P02', // invalid_text_representation
};

class SyncWorker extends ChangeNotifier {
  SyncWorker(this._dao);

  final PendingOpsDao _dao;

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  StreamSubscription<AuthState>? _authSub;
  bool _started = false;

  bool _running = false;
  bool _pendingRun = false;

  SyncWorkerState _state = SyncWorkerState.idle;
  SyncWorkerState get state => _state;

  DateTime? _lastSyncAt;
  DateTime? get lastSyncAt => _lastSyncAt;

  String? _lastError;
  String? get lastError => _lastError;

  /// Startuje listenery i robi pierwszy drain (jeśli mamy pendingi).
  ///
  /// Dwa trigery:
  /// 1. `Connectivity.onConnectivityChanged` — gdy wraca sieć po offline.
  /// 2. `Supabase.auth.onAuthStateChange` — `signedIn` triggeruje drain,
  ///    bo `_drain` wymaga `auth.uid()` i bez tej subskrypcji op-y
  ///    wpisane przed loginem nie poszłyby do bazy aż do kolejnej zmiany
  ///    connectivity.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) _scheduleDrain();
    });

    _authSub = supabase.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedIn) _scheduleDrain();
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
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Filtruje po `created_by = currentUser.id` (nie spamuje cudzymi op-ami,
    // które i tak by padły na RLS) i pomija dead-lettery (retry_count ≥ max).
    final pendings = await _dao.listForUser(user.id);
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
        await _dao.markFailure(op.clientOpId, '${e.code ?? "?"} ${e.message}');
        if (_permanentPgErrorCodes.contains(e.code)) {
          // Deterministyczny błąd (FK / RLS / NOT NULL itp.) — retry da
          // ten sam wynik. Idziemy do NASTĘPNEJ op, nie blokujemy
          // kolejki. Po `PendingOpsDao.maxRetries` ta op wpadnie w
          // dead-letter i przestanie się pojawiać w listForUser.
          continue;
        }
        // Inny błąd (np. 5xx, network reject) — przerywamy żeby nie
        // spamować Supabase. Kolejny drain spróbuje od początku.
        break;
      } on Object catch (e) {
        hadError = true;
        await _dao.markFailure(op.clientOpId, e.toString());
        // Sieciowy / timeout — przerywamy. Następny event connectivity
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
    _authSub?.cancel();
    super.dispose();
  }
}
