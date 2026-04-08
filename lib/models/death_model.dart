class DeathModel {
  final String id;
  final DateTime dateTime;
  final int count;
  final String cause;
  final int chickenAge;
  final String notes;

  DeathModel({
    required this.id,
    required this.dateTime,
    required this.count,
    required this.cause,
    required this.chickenAge,
    this.notes = '',
  });

  DeathModel copyWith({
    String? id,
    DateTime? dateTime,
    int? count,
    String? cause,
    int? chickenAge,
    String? notes,
  }) {
    return DeathModel(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      count: count ?? this.count,
      cause: cause ?? this.cause,
      chickenAge: chickenAge ?? this.chickenAge,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'count': count,
      'cause': cause,
      'chickenAge': chickenAge,
      'notes': notes,
    };
  }

  factory DeathModel.fromMap(Map<String, Object?> map) {
    return DeathModel(
      id: map['id'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      count: map['count'] as int,
      cause: map['cause'] as String,
      chickenAge: map['chickenAge'] as int,
      notes: (map['notes'] as String?) ?? '',
    );
  }
}
