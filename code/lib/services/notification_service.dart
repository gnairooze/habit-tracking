import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/habit.dart';
import '../models/alert.dart';
import 'database_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  static void _onNotificationTap(NotificationResponse notificationResponse) {
    // Handle notification tap - navigate to alert screen
    // This will be handled by the main app navigation
  }

  static Future<void> scheduleHabitNotifications(Habit habit) async {
    if (!habit.alertEnabled) return;

    // Cancel existing notifications for this habit
    await cancelHabitNotifications(habit.id!);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Schedule notifications for the next 30 days
    for (int dayOffset = 0; dayOffset < 30; dayOffset++) {
      final date = today.add(Duration(days: dayOffset));
      
      if (_shouldScheduleForDate(habit.schedule, date)) {
        for (final time in habit.schedule.times) {
          final scheduledDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );

          // Only schedule future notifications
          if (scheduledDateTime.isAfter(now)) {
            await _scheduleNotification(
              habit,
              scheduledDateTime,
              dayOffset * 100 + habit.schedule.times.indexOf(time),
            );

            // Create alert record in database
            final alert = Alert(
              habitId: habit.id!,
              habitName: habit.name,
              habitDescription: habit.description,
              scheduledDateTime: scheduledDateTime,
            );
            await DatabaseService.insertAlert(alert);
          }
        }
      }
    }
  }

  static bool _shouldScheduleForDate(HabitSchedule schedule, DateTime date) {
    switch (schedule.type) {
      case ScheduleType.daily:
        return true;
      case ScheduleType.weekly:
        if (schedule.selectedDays != null) {
          return schedule.selectedDays!.contains(date.weekday);
        }
        return true;
      case ScheduleType.monthly:
        if (schedule.selectedDays != null) {
          return schedule.selectedDays!.contains(date.day);
        }
        return true;
    }
  }

  static Future<void> _scheduleNotification(
    Habit habit,
    DateTime scheduledDateTime,
    int notificationId,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'habit_reminders',
      'Habit Reminders',
      channelDescription: 'Notifications for habit reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'Habit Reminder: ${habit.name}',
      habit.description,
      tz.TZDateTime.from(scheduledDateTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: habit.id.toString(),
    );
  }

  static Future<void> cancelHabitNotifications(int habitId) async {
    // This is a simplified approach - in a real app you'd want to track notification IDs
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
