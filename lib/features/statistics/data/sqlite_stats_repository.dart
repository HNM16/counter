import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/stats_models.dart';

class SqliteStatsRepository implements StatsRepository {
  SqliteStatsRepository(this._database);

  final AppDatabase _database;

  Database get _db => _database.db;

  @override
  Future<Map<DateTime, int>> dailyTotals(DateTime from, DateTime to) async {
    final rows = await _db.rawQuery(
      'SELECT day, SUM(count) AS total FROM session_days '
      'WHERE day BETWEEN ? AND ? GROUP BY day HAVING total > 0',
      [DayKey.of(from), DayKey.of(to)],
    );
    return {for (final r in rows) DayKey.parse(r['day']! as String): (r['total']! as num).toInt()};
  }

  @override
  Future<StatsSummary> summary() async {
    final totals = (await _db.rawQuery('''
      SELECT
        COALESCE(SUM(total_count), 0) AS total,
        COALESCE(SUM(CASE WHEN ended_at IS NOT NULL THEN 1 ELSE 0 END), 0) AS completed,
        COALESCE(SUM(total_count / target), 0) AS rounds,
        COALESCE(SUM(active_ms), 0) AS active,
        COALESCE(MAX(total_count), 0) AS longest_count,
        COALESCE(MAX(active_ms), 0) AS longest_ms
      FROM sessions WHERE total_count > 0
    ''')).first;

    final best = await _db.rawQuery(
      'SELECT day, SUM(count) AS total FROM session_days GROUP BY day '
      'HAVING total > 0 ORDER BY total DESC, day DESC LIMIT 1',
    );
    final activeDays =
        Sqflite.firstIntValue(
          await _db.rawQuery(
            'SELECT COUNT(*) FROM (SELECT day FROM session_days GROUP BY day HAVING SUM(count) > 0)',
          ),
        ) ??
        0;

    int n(String k) => (totals[k]! as num).toInt();
    return StatsSummary(
      totalCount: n('total'),
      completedSessions: n('completed'),
      totalRounds: n('rounds'),
      totalActive: Duration(milliseconds: n('active')),
      bestDay: best.isEmpty
          ? null
          : DayRecord(DayKey.parse(best.first['day']! as String), (best.first['total']! as num).toInt()),
      longestSessionCount: n('longest_count'),
      longestSessionDuration: Duration(milliseconds: n('longest_ms')),
      activeDays: activeDays,
    );
  }

  @override
  Future<List<DhikrUsage>> topDhikr({int limit = 5}) async {
    // The label of the most recent session is used, so renamed custom dhikr
    // show their current name.
    final rows = await _db.rawQuery(
      '''
      SELECT s.dhikr_id AS id,
             SUM(s.total_count) AS total,
             COUNT(*) AS sessions,
             (SELECT dhikr_label FROM sessions x WHERE x.dhikr_id = s.dhikr_id ORDER BY x.id DESC LIMIT 1) AS label,
             (SELECT dhikr_arabic FROM sessions x WHERE x.dhikr_id = s.dhikr_id ORDER BY x.id DESC LIMIT 1) AS arabic
      FROM sessions s
      WHERE s.total_count > 0
      GROUP BY s.dhikr_id
      ORDER BY total DESC
      LIMIT ?
      ''',
      [limit],
    );
    return rows
        .map(
          (r) => DhikrUsage(
            dhikrId: r['id']! as String,
            label: r['label']! as String,
            arabic: r['arabic']! as String,
            count: (r['total']! as num).toInt(),
            sessions: (r['sessions']! as num).toInt(),
          ),
        )
        .toList();
  }

  @override
  Future<List<DateTime>> activeDays() async {
    final rows = await _db.rawQuery(
      'SELECT day FROM session_days GROUP BY day HAVING SUM(count) > 0 ORDER BY day ASC',
    );
    return rows.map((r) => DayKey.parse(r['day']! as String)).toList();
  }

  @override
  Future<Map<String, int>> countsByDhikrOn(DateTime day) async {
    final rows = await _db.rawQuery(
      'SELECT s.dhikr_id AS id, SUM(d.count) AS total FROM session_days d '
      'JOIN sessions s ON s.id = d.session_id WHERE d.day = ? GROUP BY s.dhikr_id',
      [DayKey.of(day)],
    );
    return {for (final r in rows) r['id']! as String: (r['total']! as num).toInt()};
  }
}
