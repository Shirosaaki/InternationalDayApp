import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class SettingsController with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  TimeOfDay get notificationTime => _notificationTime;
  bool get isInitialized => _isInitialized;

  final NotificationService _notificationService = NotificationService();

  SettingsController() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Initialize notifications first
      await _notificationService.init();
      
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

      print('Settings loaded - isDark: ${_themeMode == ThemeMode.dark}, notificationsEnabled: $_notificationsEnabled, time: ${_notificationTime.hour}:${_notificationTime.minute}');
      
      // Reschedule notifications if they were enabled before
      if (_notificationsEnabled) {
        print('Rescheduling notifications on app startup...');
        await Future.delayed(const Duration(milliseconds: 500));
        await _notificationService.scheduleDailyNotification(_notificationTime);
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading settings: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDark', mode == ThemeMode.dark);
      await prefs.commit();
      print('Theme saved: ${mode == ThemeMode.dark ? "dark" : "light"}');
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  Future<void> updateNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificationsEnabled', value);
      await prefs.commit();
      print('Notifications setting saved: $value');

      if (value) {
        await _notificationService.requestPermissions();
        await Future.delayed(const Duration(milliseconds: 300));
        await _notificationService.scheduleDailyNotification(_notificationTime);
        print('Notifications enabled and scheduled');
      } else {
        await _notificationService.cancelNotifications();
        print('Notifications disabled and cancelled');
      }
    } catch (e) {
      print('Error updating notifications: $e');
    }
  }

  Future<void> updateNotificationTime(TimeOfDay newTime) async {
    _notificationTime = newTime;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notificationHour', newTime.hour);
      await prefs.setInt('notificationMinute', newTime.minute);
      await prefs.commit();
      print('Notification time saved: ${newTime.hour}:${newTime.minute}');

      if (_notificationsEnabled) {
        await Future.delayed(const Duration(milliseconds: 300));
        await _notificationService.scheduleDailyNotification(newTime);
        print('Notifications rescheduled for ${newTime.hour}:${newTime.minute}');
      }
    } catch (e) {
      print('Error updating notification time: $e');
    }
  }
}
