class ReminderModel {
  final String title;
  final DateTime scheduledTime;
  final bool isActive;

  ReminderModel({
    required this.title,
    required this.scheduledTime,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'scheduledTime': scheduledTime.toIso8601String(),
        'isActive': isActive,
      };

  factory ReminderModel.fromJson(Map<String, dynamic> json) => ReminderModel(
        title: json['title'],
        scheduledTime: DateTime.parse(json['scheduledTime']),
        isActive: json['isActive'],
      );
}
