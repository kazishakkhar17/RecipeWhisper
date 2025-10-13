import 'package:bli_flutter_recipewhisper/features/reminders/data/datasources/shared_pref_reminder_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/reminder_model.dart';
import '../../domain/usecases/set_reminder.dart';

final reminderProvider =
    StateNotifierProvider<ReminderNotifier, List<ReminderModel>>((ref) {
  return ReminderNotifier(SetReminderUseCase(SharedPrefReminderDatasource()));
});

class ReminderNotifier extends StateNotifier<List<ReminderModel>> {
  final SetReminderUseCase usecase;

  ReminderNotifier(this.usecase) : super([]) {
    loadReminders();
  }

  Future<void> loadReminders() async {
    state = await usecase.getAllReminders();
  }

  Future<void> addReminder(ReminderModel reminder) async {
    await usecase.addReminder(reminder);
    await loadReminders();
  }

  Future<void> toggleReminder(ReminderModel reminder, int index) async {
    await usecase.toggleReminder(reminder, index);
    await loadReminders();
  }

  Future<void> deleteReminder(int index) async {
    await usecase.deleteReminder(index);
    await loadReminders();
  }
}
