import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/counter_session.dart';

class SqliteSessionRepository implements SessionRepository {
  SqliteSessionRepository(this._database);

  final AppDatabase _database;

  Database get _db => _database.db;

  @override
  Future<CounterSession?> loadActive() async {
    final rows = await _db.query('sessions', where: 'ended_at IS NULL', orderBy: 'id DESC', limit: 1);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<CounterSession> insert(CounterSession session) async {
    final row = _toRow(session)..remove('id');
    final id = await _db.insert('sessions', row);
    return session.copyWith(id: id);
  }

  @override
  Future<void> save(CounterSession session, {int dayDelta = 0, DateTime? at}) async {
    final id = session.id;
    if (id == null) throw StateError('Cannot save a session that was never inserted');
    await _db.transaction((txn) async {
      await txn.update('sessions', _toRow(session), where: 'id = ?', whereArgs: [id]);
      if (dayDelta > 0) {
        final day = DayKey.of(at ?? session.lastActivityAt);
        await txn.rawInsert(
          'INSERT INTO session_days(session_id, day, count) VALUES(?, ?, ?) '
          'ON CONFLICT(session_id, day) DO UPDATE SET count = count + excluded.count',
          [id, day, dayDelta],
        );
      } else if (dayDelta < 0) {
        await _removeFromDays(txn, id, -dayDelta, DayKey.of(at ?? session.lastActivityAt));
      }
    });
  }

  /// Undo removes counts from [preferredDay] first, then from the most recent
  /// days, so per-day totals always add up to the session total.
  Future<void> _removeFromDays(Transaction txn, int sessionId, int amount, String preferredDay) async {
    var remaining = amount;
    final rows = await txn.query('session_days', where: 'session_id = ? AND count > 0', whereArgs: [sessionId]);
    final sorted = [...rows]
      ..sort((a, b) {
        final da = a['day']! as String;
        final db = b['day']! as String;
        if (da == preferredDay) return -1;
        if (db == preferredDay) return 1;
        return db.compareTo(da);
      });
    for (final row in sorted) {
      if (remaining == 0) break;
      final count = row['count']! as int;
      final take = count < remaining ? count : remaining;
      await txn.update(
        'session_days',
        {'count': count - take},
        where: 'session_id = ? AND day = ?',
        whereArgs: [sessionId, row['day']],
      );
      remaining -= take;
    }
    await txn.delete('session_days', where: 'session_id = ? AND count <= 0', whereArgs: [sessionId]);
  }

  @override
  Future<void> delete(int id) async {
    await _db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<CounterSession>> history({int limit = 50, int offset = 0}) async {
    final rows = await _db.query(
      'sessions',
      where: 'total_count > 0',
      orderBy: 'COALESCE(ended_at, last_activity_at) DESC, id DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> clearAll() async {
    await _db.delete('sessions');
  }

  static Map<String, Object?> _toRow(CounterSession s) => {
    'id': s.id,
    'dhikr_id': s.dhikrId,
    'dhikr_label': s.dhikrLabel,
    'dhikr_arabic': s.dhikrArabic,
    'target': s.target,
    'total_count': s.totalCount,
    'active_ms': s.activeDuration.inMilliseconds,
    'is_paused': s.isPaused ? 1 : 0,
    'started_at': s.startedAt.millisecondsSinceEpoch,
    'last_activity_at': s.lastActivityAt.millisecondsSinceEpoch,
    'ended_at': s.endedAt?.millisecondsSinceEpoch,
  };

  static CounterSession _fromRow(Map<String, Object?> r) {
    DateTime ts(String k) => DateTime.fromMillisecondsSinceEpoch(r[k]! as int);
    final ended = r['ended_at'] as int?;
    return CounterSession(
      id: r['id']! as int,
      dhikrId: r['dhikr_id']! as String,
      dhikrLabel: r['dhikr_label']! as String,
      dhikrArabic: r['dhikr_arabic']! as String,
      target: r['target']! as int,
      totalCount: r['total_count']! as int,
      activeDuration: Duration(milliseconds: r['active_ms']! as int),
      isPaused: (r['is_paused']! as int) == 1,
      startedAt: ts('started_at'),
      lastActivityAt: ts('last_activity_at'),
      endedAt: ended == null ? null : DateTime.fromMillisecondsSinceEpoch(ended),
    );
  }
}
