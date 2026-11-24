import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/services/notification_service.dart';
import '../../dhikr/domain/dhikr.dart';
import '../../dhikr/presentation/dhikr_providers.dart';
import '../data/sqlite_reminder_repository.dart';
import '../domain/reminder.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => SqliteReminderRepository(ref.watch(appDatabaseProvider)),
);

/// Result of trying to enable a reminder.
enum ReminderSaveResult { scheduled, saved, permissionDenied }

/// Keeps the reminder table and the OS notification schedule in sync.
class RemindersController extends AsyncNotifier<List<Reminder>> {
  ReminderRepository get _repo => ref.read(reminderRepositoryProvider);
  NotificationService get _notifications => ref.read(notificationServiceProvider);

  @override
  Future<List<Reminder>> build() => ref.watch(reminderRepositoryProvider).all();

  Future<ReminderSaveResult> save(Reminder reminder) async {
    var r = reminder;
    var granted = true;
    if (r.enabled) granted = await _notifications.requestPermission();
    if (r.id == null) {
      r = await _repo.insert(r.copyWith(enabled: r.enabled && granted));
    } else {
      r = r.copyWith(enabled: r.enabled && granted);
      await _repo.update(r);
    }
    await _sync(r);
    await _refresh();
    if (!granted) return ReminderSaveResult.permissionDenied;
    return r.enabled ? ReminderSaveResult.scheduled : ReminderSaveResult.saved;
  }

  Future<ReminderSaveResult> setEnabled(Reminder reminder, bool enabled) => save(reminder.copyWith(enabled: enabled));

  Future<void> remove(Reminder reminder) async {
    final id = reminder.id;
    if (id == null) return;
    state = AsyncData([...?state.value?.where((r) => r.id != id)]);
    for (final nid in reminder.allNotificationIds) {
      await _notifications.cancel(nid);
    }
    await _repo.delete(id);
    await _refresh();
  }

  /// Re-applies every schedule (used at startup, e.g. after a time zone change).
  Future<void> rescheduleAll() async {
    final items = await _repo.all();
    for (final r in items) {
      await _sync(r);
    }
  }

  Future<void> _sync(Reminder r) async {
    for (final nid in r.allNotificationIds) {
      await _notifications.cancel(nid);
    }
    if (!r.enabled) return;
    final dhikr = r.dhikrId == null ? null : await ref.read(dhikrRepositoryProvider).byId(r.dhikrId!);
    final (title, body) = reminderCopy(dhikr);
    for (final day in r.weekdays) {
      await _notifications.scheduleWeekly(
        WeeklyNotice(
          id: r.notificationId(day),
          weekday: day,
          hour: r.hour,
          minute: r.minute,
          title: title,
          body: body,
          payload: dhikr == null ? 'tasbih' : 'dhikr:${dhikr.id}',
        ),
      );
    }
  }

  Future<void> _refresh() async {
    final items = await _repo.all();
    if (ref.mounted) state = AsyncData(items);
  }
}

/// Calm, short notification copy.
(String, String) reminderCopy(Dhikr? dhikr) {
  if (dhikr == null) return ('A moment of remembrance', 'Your tasbih is ready whenever you are.');
  return (dhikr.transliteration, dhikr.translation);
}

final remindersProvider = AsyncNotifierProvider<RemindersController, List<Reminder>>(RemindersController.new);
