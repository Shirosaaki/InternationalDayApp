import 'package:flutter/material.dart';
import '../controllers/settings_controller.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

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
        title: const Text('⚙️ Paramètres'),
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: widget.settingsController,
        builder: (context, _) {
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Apparence',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SwitchListTile(
                  title: const Text('Mode Sombre'),
                  subtitle: const Text('Activer le thème sombre'),
                  secondary: Icon(
                    widget.settingsController.themeMode == ThemeMode.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    color: AppTheme.primaryColor,
                  ),
                  value: widget.settingsController.themeMode == ThemeMode.dark,
                  onChanged: (bool value) {
                    widget.settingsController.updateThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SwitchListTile(
                  title: const Text('Notifications quotidiennes'),
                  subtitle: const Text('Recevez un rappel chaque jour'),
                  secondary: Icon(
                    Icons.notifications,
                    color: AppTheme.accentColor,
                  ),
                  value: widget.settingsController.notificationsEnabled,
                  onChanged: (bool value) async {
                    await widget.settingsController.updateNotificationsEnabled(value);
                    if (value) {
                      await NotificationService().scheduleDailyNotification(_notificationTime);
                    } else {
                      await NotificationService().cancelNotifications();
                    }
                  },
                ),
              ),
              if (widget.settingsController.notificationsEnabled)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: InkWell(
                    onTap: () => _selectTime(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Heure de notification',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _notificationTime.format(context),
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.edit,
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (widget.settingsController.notificationsEnabled)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              NotificationService().testNotification();
                            },
                            child: const Text('📬 Test immédiat'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              NotificationService().testScheduledNotification();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notification programmée dans 30 secondes...'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              // Check pending notifications
                              await Future.delayed(const Duration(milliseconds: 500));
                              final pending = await NotificationService().getPendingNotifications();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${pending.length} notification(s) en attente'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: const Text('⏰ Test dans 30 sec'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final canSchedule = await NotificationService().canScheduleExactAlarms();
                              if (context.mounted) {
                                if (canSchedule) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Permission alarmes exactes: ACCORDÉE'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('❌ Permission alarmes exactes: REFUSÉE - Ouverture des paramètres...'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  await Future.delayed(const Duration(seconds: 1));
                                  await NotificationService().openAlarmSettings();
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                            ),
                            child: const Text('🔐 Vérifier permission alarmes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'À propos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Application des Journées Internationales',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Découvrez les journées internationales du monde entier et testez vos connaissances avec nos quiz amusants.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Version 1.0.0',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}
