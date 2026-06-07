import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../features/gamification/domain/user_profile.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification click if needed
      },
    );
  }

  /// Schedules daily reminders based on the user's night shift schedule
  static Future<void> scheduleShiftReminders(UserProfile profile) async {
    // 1. Cancel existing notifications to avoid duplicates
    await _notificationsPlugin.cancelAll();

    // 2. Schedule Meal Reminders
    // Meal 1: 1 hour after shift start (Wakeup)
    _scheduleDaily(1, "Time for Meal 1! 🥗", "High protein fuel to start your shift strong.", profile.startHour + 1, 0);

    // Meal 2: Middle of shift (Dinner)
    _scheduleDaily(2, "Shift Dinner Time! 🍗", "Keep your metabolism active. Don't skip your protein!", profile.startHour + 6, 0);

    // Meal 3: End of shift (Sleep Prep)
    _scheduleDaily(3, "Post-Shift Meal 🍳", "Eat your final meal before heading to sleep.", profile.startHour + 10, 0);

    // Water Reminder: 4 hours into shift
    _scheduleDaily(4, "Stay Hydrated! 💧", "Drink 500ml of water now to stay alert and avoid cravings.", profile.startHour + 4, 0);

    // Sleep Reminder: 30 mins before sleep time
    try {
      final sleepParts = profile.sleepTime.split(':');
      if (sleepParts.length == 2) {
        int hour = int.parse(sleepParts[0]);
        int min = int.parse(sleepParts[1]);
        _scheduleDaily(5, "Prepare for Sleep 💤", "Wear blue-blockers and dim the lights. Recovery is key to fat loss.", hour, min - 30);
      }
    } catch (_) {}
  }

  static Future<void> _scheduleDaily(int id, String title, String body, int hour, int minute) async {
    // Adjust hour if it overflows 24
    int finalHour = hour % 24;
    if (minute < 0) {
      finalHour = (finalHour - 1) % 24;
      minute = 60 + minute;
    } else if (minute >= 60) {
      finalHour = (finalHour + 1) % 24;
      minute = minute % 60;
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(finalHour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'shift_reminders',
          'Shift Reminders',
          channelDescription: 'Daily reminders for meals and hydration during night shifts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
