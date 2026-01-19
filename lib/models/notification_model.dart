class NotificationModel {
  final String id;
  final String type; // 'humidity', 'temperature', 'fuzzy', 'alert'
  final String title;
  final String description;
  final DateTime dateTime;
  final int chickenAge;
  final bool isRead;
  final String severity; // 'low', 'medium', 'high'

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.chickenAge,
    this.isRead = false,
    this.severity = 'medium',
  });

  NotificationModel copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    DateTime? dateTime,
    int? chickenAge,
    bool? isRead,
    String? severity,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      chickenAge: chickenAge ?? this.chickenAge,
      isRead: isRead ?? this.isRead,
      severity: severity ?? this.severity,
    );
  }
}
