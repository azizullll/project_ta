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
}
