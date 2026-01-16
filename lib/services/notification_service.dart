import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../data/days_data.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    // Set local timezone based on device's UTC offset
    final DateTime now = DateTime.now();
    final Duration offset = now.timeZoneOffset;
    
    // Find a timezone that matches the current offset
    // Common timezones by offset
    String timezoneName;
    final int hours = offset.inHours;
    
    if (hours == 1) {
      timezoneName = 'Europe/Paris';
    } else if (hours == 2) {
      timezoneName = 'Europe/Helsinki';
    } else if (hours == 0) {
      timezoneName = 'Europe/London';
    } else if (hours == -5) {
      timezoneName = 'America/New_York';
    } else if (hours == -8) {
      timezoneName = 'America/Los_Angeles';
    } else if (hours == 9) {
      timezoneName = 'Asia/Tokyo';
    } else {
      // Fallback: use UTC with manual offset calculation
      timezoneName = 'UTC';
    }
    
    try {
      tz.setLocalLocation(tz.getLocation(timezoneName));
      print('Timezone set to: $timezoneName (UTC${hours >= 0 ? "+" : ""}$hours)');
    } catch (e) {
      print('Error setting timezone: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    final fln.DarwinInitializationSettings initializationSettingsDarwin =
        fln.DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    final fln.InitializationSettings initializationSettings = fln.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );
    
    // Create Android notification channels
    final fln.AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>();
    
    // Create daily notification channel
    await androidImplementation?.createNotificationChannel(
      fln.AndroidNotificationChannel(
        'daily_notification',
        'Daily Notifications',
        description: 'Daily international day notifications',
        importance: fln.Importance.max,
        enableVibration: true,
        playSound: true,
      ),
    );

    // Create test notification channel
    await androidImplementation?.createNotificationChannel(
      fln.AndroidNotificationChannel(
        'test_channel_id',
        'Test Notifications',
        description: 'Test notification channel',
        importance: fln.Importance.max,
        enableVibration: true,
        playSound: true,
      ),
    );
    
    await androidImplementation?.requestNotificationsPermission();
    
    // Request exact alarm permission (Android 12+)
    final bool? exactAlarmGranted = await androidImplementation?.requestExactAlarmsPermission();
    print('Exact alarm permission granted: $exactAlarmGranted');
    
    print('Notification service initialized');
  }
  
  @pragma('vm:entry-point')
  static void _onSelectNotification(fln.NotificationResponse notificationResponse) {
    print('Notification tapped: ${notificationResponse.payload}');
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            fln.IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
     await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            fln.MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    final fln.AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyNotification(TimeOfDay time) async {
    try {
      // Cancel any existing notification first
      await flutterLocalNotificationsPlugin.cancel(1);
      
      final scheduledTime = _nextInstanceOfTime(time);
      final body = _buildDailyNotificationBody(scheduledTime);
      print('Scheduling daily notification for: $scheduledTime');
      print('Current time: ${tz.TZDateTime.now(tz.local)}');
      
      await flutterLocalNotificationsPlugin.zonedSchedule(
        1, // Use ID 1 for daily notifications
        'Journée Internationale',
        body,
        scheduledTime,
        fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'daily_notification',
            'Daily Notifications',
            channelDescription: 'Daily international day notifications',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: const fln.DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: fln.DateTimeComponents.time,
      );
      
      print('Daily notification scheduled successfully!');
    } catch (e) {
      print('Error scheduling daily notification: $e');
    }
  }

  Future<void> cancelNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> testNotification() async {
    try {
      print('Sending test notification...');
      await flutterLocalNotificationsPlugin.show(
        999,
        '🧪 Notification Test',
        'If you see this, notifications are working!',
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'test_channel_id',
            'Test Notification',
            channelDescription: 'Test notification channel',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
            playSound: true,
          ),
          iOS: fln.DarwinNotificationDetails(),
        ),
      );
      print('Test notification sent successfully!');
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  // Test scheduled notification - fires in 30 seconds
  Future<void> testScheduledNotification() async {
    try {
      print('Scheduling test notification for 30 seconds from now...');
      
      final DateTime now = DateTime.now();
      final DateTime scheduledTime = now.add(const Duration(seconds: 30));
      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
      
      print('Now: $now');
      print('Scheduled for: $scheduledTime');
      print('TZ Scheduled: $tzScheduledTime');
      
      await flutterLocalNotificationsPlugin.zonedSchedule(
        888,
        '⏰ Scheduled Test',
        'This notification was scheduled 30 seconds ago!',
        tzScheduledTime,
        fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'daily_notification',
            'Daily Notifications',
            channelDescription: 'Daily international day notifications',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: const fln.DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.inexactAllowWhileIdle,
      );
      
      print('Test scheduled notification set!');
    } catch (e) {
      print('Error scheduling test notification: $e');
    }
  }

  // Check pending notifications
  Future<List<fln.PendingNotificationRequest>> getPendingNotifications() async {
    final List<fln.PendingNotificationRequest> pending = 
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    print('Pending notifications: ${pending.length}');
    for (var p in pending) {
      print('  ID: ${p.id}, Title: ${p.title}');
    }
    return pending;
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    // Use device's local DateTime to avoid timezone issues
    final DateTime now = DateTime.now();
    DateTime scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    // Convert to TZDateTime using the local timezone offset
    final tz.TZDateTime result = tz.TZDateTime.from(scheduledDate, tz.local);
    
    print('_nextInstanceOfTime: Device now=$now, Scheduled=$scheduledDate, TZResult=$result');
    return result;
  }

  String _buildDailyNotificationBody(DateTime date) {
    final todaysDays = internationalDaysData
        .where((day) => day.month == date.month && day.day == date.day)
        .toList();

    if (todaysDays.isEmpty) {
      return "Pas de journée internationale aujourd'hui 😌";
    }

    if (todaysDays.length == 1) {
      return "Aujourd'hui, c'est ${todaysDays.first.title} 🌍";
    }

    final first = todaysDays.first.title;
    final remaining = todaysDays.length - 1;
    final otherLabel = remaining == 1 ? 'autre thème' : 'autres thèmes';
    return "Aujourd'hui, c'est $first et $remaining $otherLabel en plus 🎉";
  }

  // Check if exact alarms are allowed
  Future<bool> canScheduleExactAlarms() async {
    final fln.AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>();
    
    final bool? canSchedule = await androidImplementation?.canScheduleExactNotifications();
    print('Can schedule exact alarms: $canSchedule');
    return canSchedule ?? false;
  }

  // Open alarm settings
  Future<void> openAlarmSettings() async {
    const platform = MethodChannel('alarm_settings');
    try {
      await platform.invokeMethod('openAlarmSettings');
    } catch (e) {
      print('Error opening alarm settings: $e');
      // Fallback: request permission through the plugin
      final fln.AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              fln.AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }
}
