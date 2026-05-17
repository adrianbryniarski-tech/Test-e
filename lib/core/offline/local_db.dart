import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Lokalna baza SQLite dla offline kolejki.
///
/// Trzymamy minimum tabel — tylko to czego Supabase nie może obsłużyć
/// gdy nie ma sieci. Cache zsynchronizowanych transakcji NIE jest tu,
/// `supabase.stream()` sam buforuje na żywym połączeniu.
class LocalDb {
  LocalDb({this.fixedPath});

  /// Singleton używany w runtime (path = `getApplicationSupportDirectory`).
  static final LocalDb instance = LocalDb();

  /// Override ścieżki na potrzeby testów. Jeśli `null` → szukamy
  /// `getApplicationSupportDirectory()`.
  final String? fixedPath;

  static const _dbName = 'nasz_budzet_offline.db';
  static const _schemaVersion = 1;

  Database? _db;

  Future<Database> get database async {
    final cached = _db;
    if (cached != null) return cached;
    final path = await _resolvePath();
    _db = await openDatabase(
      path,
      version: _schemaVersion,
      onCreate: _onCreate,
    );
    return _db!;
  }

  Future<String> _resolvePath() async {
    final fixed = fixedPath;
    if (fixed != null) return fixed;
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, _dbName);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_transactions (
        client_op_id TEXT PRIMARY KEY,
        household_id TEXT NOT NULL,
        created_by TEXT,
        occurred_at TEXT NOT NULL,
        amount_cents INTEGER NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT NOT NULL,
        description TEXT,
        note TEXT,
        source TEXT NOT NULL,
        dedup_hash TEXT NOT NULL,
        enqueued_at INTEGER NOT NULL,
        last_error TEXT,
        retry_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_pending_by_household '
      'ON pending_transactions(household_id, enqueued_at)',
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
