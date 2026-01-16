import 'package:flutter/material.dart';
import '../controllers/settings_controller.dart';
import '../services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  final SettingsController settingsController;

  const SettingsPage({super.key, required this.settingsController});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TimeOfDay _notificationTime;

  @override
  void initState() {
    super.initState();
    _notificationTime = widget.settingsController.notificationTime;
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (picked != null && picked != _notificationTime) {
      setState(() {
        _notificationTime = picked;
      });
      await widget.settingsController.updateNotificationTime(picked);
      if (widget.settingsController.notificationsEnabled) {
        await NotificationService().scheduleDailyNotification(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Mode Sombre'),
            value: widget.settingsController.themeMode == ThemeMode.dark,
            onChanged: (bool value) {
              widget.settingsController.updateThemeMode(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Notifications quotidiennes'),
            value: widget.settingsController.notificationsEnabled,
            onChanged: (bool value) async {
              await widget.settingsController.updateNotificationsEnabled(value);
              if (value) {
                await NotificationService().scheduleDailyNotification(_notificationTime);
              } else {
                await NotificationService().cancelNotifications();
              }
              setState(() {});
            },
          ),
          ListTile(
            title: const Text('Heure de notification'),
            subtitle: Text(_notificationTime.format(context)),
            enabled: widget.settingsController.notificationsEnabled,
            onTap: () => _selectTime(context),
          ),
        ],
      ),
    );
  }
}
