import 'package:bli_flutter_recipewhisper/features/reminders/data/reminder_model.dart';
import 'package:bli_flutter_recipewhisper/features/reminders/data/datasources/shared_pref_reminder_datasource.dart';

import '../../presentation/utils/notification_helper.dart';
// import '../../presentation/utils/notification_helper.dart'; // <-- add this import

class SetReminderUseCase {
  final SharedPrefReminderDatasource datasource;

  SetReminderUseCase(this.datasource);

  Future<List<ReminderModel>> getAllReminders() async {
    return await datasource.getReminders();
  }

  Future<void> addReminder(ReminderModel reminder) async {
    await datasource.addReminder(reminder);

    // Schedule notification after saving the reminder
    final allReminders = await getAllReminders();
    final index = allReminders.indexOf(reminder); // use index as unique ID
    await NotificationHelper.scheduleReminderNotification(reminder, index); // <-- added
  }

  Future<void> toggleReminder(ReminderModel reminder, int index) async {
    final updated = ReminderModel(
      title: reminder.title,
      scheduledTime: reminder.scheduledTime,
      isActive: !reminder.isActive,
    );
    await datasource.updateReminder(updated, index);
  }

  Future<void> deleteReminder(int index) async {
    await datasource.deleteReminder(index);
  }
}