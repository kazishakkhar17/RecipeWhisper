import 'package:bli_flutter_recipewhisper/main.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../data/reminder_model.dart';

// Import Awesome Notifications at the top level
import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationHelper {
  
  /// Schedule a notification for a given reminder (mobile & web)
  static Future<void> scheduleReminderNotification(ReminderModel reminder, int id) async {
    if (kIsWeb) {
      await _scheduleWebNotification(reminder, id);
    } else {
      await _scheduleMobileNotification(reminder, id);
    }
  }

  /// Mobile implementation
  static Future<void> _scheduleMobileNotification(ReminderModel reminder, int id) async {
    if (kIsWeb) return;
    
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'reminder_channel',
          title: 'Reminder: ${reminder.title}',
          body: "It's time for your reminder",
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar(
          year: reminder.scheduledTime.year,
          month: reminder.scheduledTime.month,
          day: reminder.scheduledTime.day,
          hour: reminder.scheduledTime.hour,
          minute: reminder.scheduledTime.minute,
          second: 0,
          preciseAlarm: true,
          repeats: false,
        ),
      );
      print('Mobile notification scheduled for ${reminder.scheduledTime}');
    } catch (e) {
      print('Error scheduling mobile notification: $e');
    }
  }

  /// Web implementation
  static Future<void> _scheduleWebNotification(ReminderModel reminder, int id) async {
    try {
      final now = DateTime.now();
      final delay = reminder.scheduledTime.difference(now);

      if (delay.isNegative) return;

      Future.delayed(delay, () {
        _showInAppNotification(
          'Reminder: ${reminder.title}',
          "It's time for your reminder",
        );
      });
      
      print('Web notification scheduled for ${reminder.scheduledTime}');
    } catch (e) {
      print('Error scheduling web notification: $e');
    }
  }

  /// Show immediate notification (both platforms)
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      _showInAppNotification(title, body);
    } else {
      await _showMobileNotification(title: title, body: body);
    }
  }

  /// Mobile: Show immediate notification
  static Future<void> _showMobileNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'reminder_channel',
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
        ),
      );
    } catch (e) {
      print('Error showing mobile notification: $e');
    }
  }

  /// Show in-app notification (works on both web and mobile)
  static void _showInAppNotification(String title, String body) {
    if (kIsWeb) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('$title - $body'),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      print('Notification: $title - $body');
    }
  }

  /// Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    if (!kIsWeb) {
      await AwesomeNotifications().cancel(id);
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    if (!kIsWeb) {
      await AwesomeNotifications().cancelAll();
    }
  }

  /// Check if notifications are allowed
  static Future<bool> isNotificationAllowed() async {
    if (kIsWeb) {
      return true;
    } else {
      return await AwesomeNotifications().isNotificationAllowed();
    }
  }

  /// Request notification permission
  static Future<void> requestPermission() async {
    if (kIsWeb) {
      print('Web notification permission requested (in-app notifications)');
    } else {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }
}
