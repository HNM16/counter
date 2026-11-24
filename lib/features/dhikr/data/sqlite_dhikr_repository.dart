import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/dhikr.dart';
import 'dhikr_seed.dart';

class SqliteDhikrRepository implements DhikrRepository {
  SqliteDhikrRepository(this._database, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _clock;

  Database get _db => _database.db;

  @override
  Future<void> ensureSeeded() async {
    final batch = _db.batch();
    for (final d in DhikrSeed.entries) {
      batch.insert('dhikr', _toRow(d), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<Dhikr>> all() async {
    final rows = await _db.query('dhikr', orderBy: 'is_custom ASC, sort_order ASC, created_at ASC');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Dhikr?> byId(String id) async {
    final rows = await _db.query('dhikr', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<Dhikr> create({
    required String arabic,
    required String transliteration,
    required String translation,
    int? suggestedCount,
  }) async {
    final now = _clock();
    final maxOrder = Sqflite.firstIntValue(await _db.rawQuery('SELECT MAX(sort_order) FROM dhikr')) ?? 0;
    final dhikr = Dhikr(
      id: 'custom_${now.microsecondsSinceEpoch}',
      arabic: arabic.trim(),
      transliteration: transliteration.trim(),
      translation: translation.trim(),
      suggestedCount: suggestedCount,
      isCustom: true,
      sortOrder: maxOrder + 1,
      createdAt: now,
    );
    await _db.insert('dhikr', _toRow(dhikr), conflictAlgorithm: ConflictAlgorithm.abort);
    return dhikr;
  }

  @override
  Future<void> update(Dhikr dhikr) async {
    await _db.update('dhikr', _toRow(dhikr), where: 'id = ?', whereArgs: [dhikr.id]);
  }

  @override
  Future<void> delete(String id) async {
    await _db.transaction((txn) async {
      await txn.delete('dhikr', where: 'id = ? AND is_custom = 1', whereArgs: [id]);
      await txn.delete('goals', where: 'dhikr_id = ?', whereArgs: [id]);
      await txn.update('reminders', {'dhikr_id': null}, where: 'dhikr_id = ?', whereArgs: [id]);
    });
  }

  static Map<String, Object?> _toRow(Dhikr d) => {
    'id': d.id,
    'arabic': d.arabic,
    'transliteration': d.transliteration,
    'translation': d.translation,
    'suggested_count': d.suggestedCount,
    'reference': d.reference,
    'is_custom': d.isCustom ? 1 : 0,
    'is_favorite': d.isFavorite ? 1 : 0,
    'sort_order': d.sortOrder,
    'created_at': d.createdAt.millisecondsSinceEpoch,
  };

  static Dhikr _fromRow(Map<String, Object?> r) => Dhikr(
    id: r['id']! as String,
    arabic: r['arabic']! as String,
    transliteration: r['transliteration']! as String,
    translation: r['translation']! as String,
    suggestedCount: r['suggested_count'] as int?,
    reference: r['reference'] as String?,
    isCustom: (r['is_custom']! as int) == 1,
    isFavorite: (r['is_favorite']! as int) == 1,
    sortOrder: r['sort_order']! as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at']! as int),
  );
}
