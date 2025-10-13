import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bli_flutter_recipewhisper/core/localization/app_localizations.dart';
import '../providers/reminder_provider.dart';
import '../widgets/reminder_tile.dart';
import '../../data/reminder_model.dart';

class ReminderScreen extends ConsumerWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(reminderProvider);
    final notifier = ref.read(reminderProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('reminders')), // ✅ localized
      ),
      body: reminders.isEmpty
          ? Center(
              child: Text(
                context.tr('no_recipes'), // You can also add a key like 'no_reminders'
                style: const TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                return ReminderTile(
                  reminder: reminder,
                  onToggle: () => notifier.toggleReminder(reminder, index),
                  onDelete: () => notifier.deleteReminder(index),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final titleController = TextEditingController();
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (pickedTime == null) return;

          final now = DateTime.now();
          final scheduled = DateTime(
            now.year,
            now.month,
            now.day,
            pickedTime.hour,
            pickedTime.minute,
          );

          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(context.tr('set_reminder')), // ✅ localized
              content: TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: context.tr('reminders'),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    final newReminder = ReminderModel(
                      title: titleController.text,
                      scheduledTime: scheduled,
                    );
                    notifier.addReminder(newReminder);
                    Navigator.pop(context);
                  },
                  child: Text(context.tr('save')), // ✅ localized
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
