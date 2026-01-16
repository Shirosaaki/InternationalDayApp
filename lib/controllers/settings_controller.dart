import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class SettingsController with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  TimeOfDay get notificationTime => _notificationTime;

  final NotificationService _notificationService = NotificationService();

  SettingsController() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Theme
    final isDark = prefs.getBool('isDark');
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }

    // Notifications
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
    
    // Time
    final hour = prefs.getInt('notificationHour') ?? 9;
    final minute = prefs.getInt('notificationMinute') ?? 0;
    _notificationTime = TimeOfDay(hour: hour, minute: minute);

    notifyListeners();
    
    // Initialize notifications
    await _notificationService.init();
    if (_notificationsEnabled) {
      // Ensure permissions are requested if enabled
      await _notificationService.requestPermissions();
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', mode == ThemeMode.dark);
  }

  Future<void> updateNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);

    if (value) {
      await _notificationService.requestPermissions();
      await _notificationService.scheduleDailyNotification(_notificationTime);
    } else {
      await _notificationService.cancelNotifications();
    }
  }

  Future<void> updateNotificationTime(TimeOfDay newTime) async {
    _notificationTime = newTime;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notificationHour', newTime.hour);
    await prefs.setInt('notificationMinute', newTime.minute);

    if (_notificationsEnabled) {
      await _notificationService.scheduleDailyNotification(newTime);
    }
  }
}
