import '../../../core/database/app_database.dart';
import '../domain/goal.dart';

class SqliteGoalRepository implements GoalRepository {
  SqliteGoalRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<Goal>> all() async {
    final rows = await _database.db.query('goals', orderBy: 'dhikr_id IS NOT NULL, created_at ASC');
    return rows
        .map(
          (r) => Goal(
            id: r['id']! as int,
            dhikrId: r['dhikr_id'] as String?,
            target: r['target']! as int,
            createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at']! as int),
          ),
        )
        .toList();
  }

  @override
  Future<Goal> insert(Goal goal) async {
    final id = await _database.db.insert('goals', {
      'dhikr_id': goal.dhikrId,
      'target': goal.target,
      'created_at': goal.createdAt.millisecondsSinceEpoch,
    });
    return goal.copyWith(id: id);
  }

  @override
  Future<void> update(Goal goal) async {
    await _database.db.update(
      'goals',
      {'dhikr_id': goal.dhikrId, 'target': goal.target},
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  @override
  Future<void> delete(int id) async {
    await _database.db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }
}
