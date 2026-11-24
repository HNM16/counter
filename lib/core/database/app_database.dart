import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite connection and schema.
///
/// Tables:
/// * `dhikr`         - library entries (built-in and user-created)
/// * `sessions`      - one row per counting session (active row has `ended_at IS NULL`)
/// * `session_days`  - per-day repetition counts for each session, so statistics
///                     stay correct when a session spans midnight
/// * `goals`         - daily repetition goals
/// * `reminders`     - local reminder schedules
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const fileName = 'sakina.db';
  static const schemaVersion = 1;

  /// Opens (and creates/migrates) the database.
  ///
  /// [factory] and [path] are injectable so tests can use an in-memory FFI
  /// database with the exact production schema.
  static Future<AppDatabase> open({DatabaseFactory? factory, String? path}) async {
    final f = factory ?? databaseFactory;
    final resolvedPath = path ?? p.join(await f.getDatabasesPath(), fileName);
    final db = await f.openDatabase(
      resolvedPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) => _migrate(db, 0, version),
        onUpgrade: _migrate,
      ),
    );
    return AppDatabase._(db);
  }

  static Future<void> _migrate(Database db, int from, int to) async {
    final batch = db.batch();
    if (from < 1) {
      batch.execute('''
        CREATE TABLE dhikr (
          id TEXT PRIMARY KEY,
          arabic TEXT NOT NULL,
          transliteration TEXT NOT NULL,
          translation TEXT NOT NULL,
          suggested_count INTEGER,
          reference TEXT,
          is_custom INTEGER NOT NULL DEFAULT 0,
          is_favorite INTEGER NOT NULL DEFAULT 0,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        )
      ''');
      batch.execute('''
        CREATE TABLE sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          dhikr_id TEXT NOT NULL,
          dhikr_label TEXT NOT NULL,
          dhikr_arabic TEXT NOT NULL,
          target INTEGER NOT NULL,
          total_count INTEGER NOT NULL DEFAULT 0,
          active_ms INTEGER NOT NULL DEFAULT 0,
          is_paused INTEGER NOT NULL DEFAULT 0,
          started_at INTEGER NOT NULL,
          last_activity_at INTEGER NOT NULL,
          ended_at INTEGER
        )
      ''');
      batch.execute('CREATE INDEX idx_sessions_started ON sessions(started_at DESC)');
      batch.execute('CREATE INDEX idx_sessions_dhikr ON sessions(dhikr_id)');
      batch.execute('''
        CREATE TABLE session_days (
          session_id INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
          day TEXT NOT NULL,
          count INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (session_id, day)
        )
      ''');
      batch.execute('CREATE INDEX idx_session_days_day ON session_days(day)');
      batch.execute('''
        CREATE TABLE goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          dhikr_id TEXT,
          target INTEGER NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
      batch.execute('''
        CREATE TABLE reminders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          hour INTEGER NOT NULL,
          minute INTEGER NOT NULL,
          weekdays INTEGER NOT NULL,
          dhikr_id TEXT,
          enabled INTEGER NOT NULL DEFAULT 1
        )
      ''');
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() => db.close();
}
