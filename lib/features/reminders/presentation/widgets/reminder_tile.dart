import 'package:flutter/material.dart';
import '../../data/reminder_model.dart';

class ReminderTile extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const ReminderTile({
    super.key,
    required this.reminder,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(reminder.title),
      subtitle: Text('⏰ ${reminder.scheduledTime}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: reminder.isActive,
            onChanged: (_) => onToggle?.call(),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
