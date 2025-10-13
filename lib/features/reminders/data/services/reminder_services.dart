import 'package:flutter/foundation.dart' show kIsWeb;
import '../../data/reminder_model.dart';
// import 'notification_service_mobile.dart' if (dart.library.html) 'notification_service_web.dart';

// Abstract interface that both implementations follow
abstract class NotificationService {
  Future<bool> requestPermission();
  Future<void> scheduleReminderNotification(ReminderModel reminder, int id);
  void cancelNotification(int id);
  void cancelAllNotifications();
  Future<void> rescheduleAllReminders(List<ReminderModel> reminders);
}

// This function is implemented in both notification_service_mobile.dart and notification_service_web.dart
// The conditional import above will automatically choose the right one
NotificationService getNotificationService() => throw UnimplementedError();

// Factory to get the right implementation
class NotificationHelper {
  static NotificationService? _instance;
  
  static NotificationService get instance {
    _instance ??= getNotificationService();
    return _instance!;
  }

  static Future<bool> requestPermission() async {
    return await instance.requestPermission();
  }

  static Future<void> scheduleReminderNotification(
      ReminderModel reminder, int id) async {
    await instance.scheduleReminderNotification(reminder, id);
  }

  static void cancelNotification(int id) {
    instance.cancelNotification(id);
  }

  static void cancelAllNotifications() {
    instance.cancelAllNotifications();
  }

  static Future<void> rescheduleAllReminders(
      List<ReminderModel> reminders) async {
    await instance.rescheduleAllReminders(reminders);
  }
}