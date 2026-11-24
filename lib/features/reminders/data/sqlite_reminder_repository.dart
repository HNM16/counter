import '../../../core/database/app_database.dart';
import '../domain/reminder.dart';

class SqliteReminderRepository implements ReminderRepository {
  SqliteReminderRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<Reminder>> all() async {
    final rows = await _database.db.query('reminders', orderBy: 'hour ASC, minute ASC');
    return rows
        .map(
          (r) => Reminder(
            id: r['id']! as int,
            hour: r['hour']! as int,
            minute: r['minute']! as int,
            weekdays: Reminder.weekdaysFromMask(r['weekdays']! as int),
            dhikrId: r['dhikr_id'] as String?,
            enabled: (r['enabled']! as int) == 1,
          ),
        )
        .toList();
  }

  @override
  Future<Reminder> insert(Reminder reminder) async {
    final id = await _database.db.insert('reminders', _row(reminder));
    return reminder.copyWith(id: id);
  }

  @override
  Future<void> update(Reminder reminder) async {
    await _database.db.update('reminders', _row(reminder), where: 'id = ?', whereArgs: [reminder.id]);
  }

  @override
  Future<void> delete(int id) async {
    await _database.db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  static Map<String, Object?> _row(Reminder r) => {
    'hour': r.hour,
    'minute': r.minute,
    'weekdays': r.weekdayMask,
    'dhikr_id': r.dhikrId,
    'enabled': r.enabled ? 1 : 0,
  };
}
