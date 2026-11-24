import 'package:flutter/foundation.dart';

@immutable
class Reminder {
  const Reminder({
    required this.hour,
    required this.minute,
    required this.weekdays,
    this.id,
    this.dhikrId,
    this.enabled = true,
  });

  static const everyDay = {1, 2, 3, 4, 5, 6, 7};

  final int? id;
  final int hour;
  final int minute;

  /// [DateTime.monday] (1) .. [DateTime.sunday] (7).
  final Set<int> weekdays;

  /// Optional dhikr to open when the reminder is tapped.
  final String? dhikrId;
  final bool enabled;

  int get weekdayMask => weekdays.fold(0, (mask, d) => mask | (1 << (d - 1)));

  static Set<int> weekdaysFromMask(int mask) => {
    for (var d = 1; d <= 7; d++)
      if (mask & (1 << (d - 1)) != 0) d,
  };

  /// Notification ids are derived from the reminder id and weekday so each
  /// weekday slot can be scheduled and cancelled independently.
  int notificationId(int weekday) => (id ?? 0) * 10 + weekday;

  Iterable<int> get allNotificationIds => [for (var d = 1; d <= 7; d++) notificationId(d)];

  Reminder copyWith({
    int? id,
    int? hour,
    int? minute,
    Set<int>? weekdays,
    String? dhikrId,
    bool clearDhikr = false,
    bool? enabled,
  }) => Reminder(
    id: id ?? this.id,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    weekdays: weekdays ?? this.weekdays,
    dhikrId: clearDhikr ? null : (dhikrId ?? this.dhikrId),
    enabled: enabled ?? this.enabled,
  );

  @override
  bool operator ==(Object other) =>
      other is Reminder &&
      other.id == id &&
      other.hour == hour &&
      other.minute == minute &&
      setEquals(other.weekdays, weekdays) &&
      other.dhikrId == dhikrId &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(id, hour, minute, weekdayMask, dhikrId, enabled);
}

abstract interface class ReminderRepository {
  Future<List<Reminder>> all();

  Future<Reminder> insert(Reminder reminder);

  Future<void> update(Reminder reminder);

  Future<void> delete(int id);
}
