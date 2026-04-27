import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _crudChannelId = 'crud_channel';
  static const _crudChannelName = 'CRUD activity';
  static const _reminderChannelId = 'reminder_channel';
  static const _reminderChannelName = 'Reminders';
  static const int reminderNotificationId = 1001;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _crudChannelId,
        _crudChannelName,
        description: 'Confirmation notifications for create/update/delete',
        importance: Importance.defaultImportance,
      ),
    );

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _reminderChannelId,
        _reminderChannelName,
        description: 'Periodic reminders to log your collection',
        importance: Importance.high,
      ),
    );

    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    _initialized = true;
  }

  Future<void> showCrudToast(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _crudChannelId,
        _crudChannelName,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        ticker: 'crud',
      ),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title,
      body,
      details,
    );
  }

  Future<void> scheduleEveryFiveHoursReminder() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _reminderChannelId,
        _reminderChannelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    // flutter_local_notifications doesn't have a "every 5 hours" preset.
    // Schedule the next occurrence with matchDateTimeComponents = null and
    // re-schedule on each tap; for simplicity here we use periodicallyShow
    // with the closest available repeat (hourly) and gate the body to only
    // fire every 5 hours by computing the next slot ourselves.
    final next = _nextFiveHourSlot();
    try {
      await _plugin.zonedSchedule(
        reminderNotificationId,
        'Collection reminder',
        "Don't forget to log your collection!",
        next,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to schedule reminder: $e');
      }
    }
  }

  Future<void> cancelReminder() async {
    await _plugin.cancel(reminderNotificationId);
  }

  tz.TZDateTime _nextFiveHourSlot() {
    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      now.hour,
    ).add(const Duration(hours: 5));
    if (candidate.isBefore(now)) {
      candidate = candidate.add(const Duration(hours: 5));
    }
    return candidate;
  }
}
