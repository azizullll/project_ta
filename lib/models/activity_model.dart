class ActivityModel {
  final String id;
  final String type; // 'normal', 'warning', 'emergency', 'error'
  final String title;
  final String description;
  final String source; // 'relay', 'control', 'status', 'sensor', 'system', dll
  final DateTime dateTime;
  final int chickenAge;
  final bool lampActive;
  final bool fanActive;
  final String iconType; // 'settings', 'monitor'

  ActivityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.source = 'system',
    required this.dateTime,
    required this.chickenAge,
    required this.lampActive,
    required this.fanActive,
    this.iconType = 'settings',
  });

  ActivityModel copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    String? source,
    DateTime? dateTime,
    int? chickenAge,
    bool? lampActive,
    bool? fanActive,
    String? iconType,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      source: source ?? this.source,
      dateTime: dateTime ?? this.dateTime,
      chickenAge: chickenAge ?? this.chickenAge,
      lampActive: lampActive ?? this.lampActive,
      fanActive: fanActive ?? this.fanActive,
      iconType: iconType ?? this.iconType,
    );
  }
}
