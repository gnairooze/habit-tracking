import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/habit.dart';
import '../models/alert.dart';
import 'database_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Request permissions for notifications
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>();

      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      // Handle notification tap - could navigate to alert screen
      debugPrint('Notification payload: $payload');
    }
  }

  Future<void> scheduleHabitNotifications(Habit habit) async {
    // Cancel existing notifications for this habit
    await cancelHabitNotifications(habit.id!);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Generate alerts for the next 30 days
    for (int dayOffset = 0; dayOffset < 30; dayOffset++) {
      final targetDate = today.add(Duration(days: dayOffset));
      final scheduledTimes =
          _getScheduledTimesForDate(habit.schedule, targetDate);

      for (final timeString in scheduledTimes) {
        final timeParts = timeString.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        final scheduledDateTime = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          hour,
          minute,
        );

        // Only schedule future notifications
        if (scheduledDateTime.isAfter(now)) {
          // Create alert in database
          final alert = Alert(
            habitId: habit.id!,
            habitName: habit.name,
            habitDescription: habit.description,
            scheduledDateTime: scheduledDateTime,
            createdAt: now,
          );

          final alertId = await DatabaseService.instance.insertAlert(alert);

          // Schedule notification
          await _scheduleNotification(
            alertId,
            habit.name,
            habit.description,
            scheduledDateTime,
          );
        }
      }
    }
  }

  List<String> _getScheduledTimesForDate(
      HabitSchedule schedule, DateTime date) {
    switch (schedule.type) {
      case ScheduleType.daily:
        return schedule.times;

      case ScheduleType.weekly:
        final dayName = _getDayName(date.weekday);
        if (schedule.days?.contains(dayName) == true) {
          return schedule.times;
        }
        return [];

      case ScheduleType.monthly:
        final dayNumber = date.day.toString();
        if (schedule.days?.contains(dayNumber) == true) {
          return schedule.times;
        }
        return [];
    }
  }

  String _getDayName(int weekday) {
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return dayNames[weekday - 1];
  }

  Future<void> _scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDateTime,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'habit_reminders',
      'Habit Reminders',
      channelDescription: 'Notifications for habit reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
      macOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDateTime, tz.local),
      platformChannelSpecifics,
      payload: id.toString(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelHabitNotifications(int habitId) async {
    // Get all alerts for this habit
    final alerts = await DatabaseService.instance.getAlerts();
    final habitAlerts = alerts.where((alert) => alert.habitId == habitId);

    // Cancel notifications and delete alerts
    for (final alert in habitAlerts) {
      if (alert.id != null) {
        await _flutterLocalNotificationsPlugin.cancel(alert.id!);
        await DatabaseService.instance.deleteAlert(alert.id!);
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
