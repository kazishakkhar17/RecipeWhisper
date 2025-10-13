import 'dart:convert';
import '../reminder_model.dart';
import 'package:shared_preferences/shared_preferences.dart';



class SharedPrefReminderDatasource {
  static const String _reminderKey = 'reminders';

  Future<List<ReminderModel>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_reminderKey);
    if (jsonString == null) return [];
    final List decoded = json.decode(jsonString);
    return decoded.map((e) => ReminderModel.fromJson(e)).toList();
  }

  Future<void> saveReminders(List<ReminderModel> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(reminders.map((e) => e.toJson()).toList());
    await prefs.setString(_reminderKey, jsonString);
  }

  Future<void> addReminder(ReminderModel reminder) async {
    final reminders = await getReminders();
    reminders.add(reminder);
    await saveReminders(reminders);
  }

  Future<void> updateReminder(ReminderModel reminder, int index) async {
    final reminders = await getReminders();
    if (index >= 0 && index < reminders.length) {
      reminders[index] = reminder;
      await saveReminders(reminders);
    }
  }

  Future<void> deleteReminder(int index) async {
    final reminders = await getReminders();
    if (index >= 0 && index < reminders.length) {
      reminders.removeAt(index);
      await saveReminders(reminders);
    }
  }
}
