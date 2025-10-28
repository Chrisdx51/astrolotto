// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart'; // for flutterLocalNotificationsPlugin

// ✅ UK Lottery Notification — Monday 10 AM
Future<void> scheduleWeeklyLotteryUK() async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
    1001,
    "UK Lottery Reminder",
    "✨ Don’t forget! UK Lotto draw is tonight! Check your cosmic numbers!",
    _nextInstanceOfWeekday(1, 10), // Monday 10:00 AM
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'astro_lotto_channel',
        'Astro Lotto Alerts',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
    UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
  );
}

// ✅ Weekly Astro Forecast — Wednesday 9 AM
Future<void> scheduleWeeklyForecast() async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
    1002,
    "🔮 Weekly Cosmic Forecast",
    "Your lucky cosmic forecast is ready — align with the stars ✨",
    _nextInstanceOfWeekday(3, 9), // Wednesday 9:00 AM
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'astro_lotto_channel',
        'Astro Lotto Alerts',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
    UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
  );
}

// ✅ Helper: Pick next weekday + time
tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour) {
  final now = tz.TZDateTime.now(tz.local);
  var scheduled =
  tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
  while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

// ✅ Called from main.dart after token setup
Future<void> scheduleWeeklyReminder() async {
  await scheduleWeeklyLotteryUK();
  await scheduleWeeklyForecast();
}
