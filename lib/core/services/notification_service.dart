import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A single weekly notification slot.
@immutable
class WeeklyNotice {
  const WeeklyNotice({
    required this.id,
    required this.weekday,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
    this.payload,
  });

  final int id;

  /// [DateTime.monday] .. [DateTime.sunday]
  final int weekday;
  final int hour;
  final int minute;
  final String title;
  final String body;
  final String? payload;
}

abstract interface class NotificationService {
  Future<void> init();

  /// Asks the OS for permission. Returns whether notifications may be shown.
  Future<bool> requestPermission();

  Future<void> scheduleWeekly(WeeklyNotice notice);

  Future<void> cancel(int id);

  /// Emits the payload of notifications the user tapped.
  Stream<String> get taps;

  /// Payload of the notification that launched the app, if any.
  Future<String?> launchPayload();
}

/// Gentle, local-only reminders. Uses inexact scheduling (no exact-alarm
/// permission) and default importance, so reminders never feel intrusive.
class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<String>.broadcast();
  bool _ready = false;

  static const _channelId = 'dhikr_reminders';
  static const _channelName = 'Dhikr reminders';

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('Falling back to UTC for reminders: $e');
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher_foreground'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _taps.add(payload);
      },
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  @override
  Future<void> scheduleWeekly(WeeklyNotice notice) async {
    await init();
    await _plugin.zonedSchedule(
      id: notice.id,
      title: notice.title,
      body: notice.body,
      payload: notice.payload,
      scheduledDate: _nextInstance(notice.weekday, notice.hour, notice.minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Optional reminders you set for your daily dhikr.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextInstance(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (at.weekday != weekday || !at.isAfter(now)) {
      at = tz.TZDateTime(tz.local, at.year, at.month, at.day + 1, hour, minute);
    }
    return at;
  }

  @override
  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }

  @override
  Future<String?> launchPayload() async {
    await init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details!.notificationResponse?.payload;
    }
    return null;
  }
}

/// No-op implementation for tests.
class DisabledNotificationService implements NotificationService {
  DisabledNotificationService({this.permissionGranted = true});

  final bool permissionGranted;
  final scheduled = <int, WeeklyNotice>{};

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> scheduleWeekly(WeeklyNotice notice) async => scheduled[notice.id] = notice;

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);

  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Future<String?> launchPayload() async => null;
}
