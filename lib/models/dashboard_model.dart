class DashboardModel {
  final double temperature;
  final double humidity;
  final int chickenAge;
  final bool isAutoMode;
  final bool lampStatus;
  final bool fanStatus;
  final String currentMode;

  DashboardModel({
    required this.temperature,
    required this.humidity,
    required this.chickenAge,
    required this.isAutoMode,
    required this.lampStatus,
    required this.fanStatus,
    required this.currentMode,
  });

  DashboardModel copyWith({
    double? temperature,
    double? humidity,
    int? chickenAge,
    bool? isAutoMode,
    bool? lampStatus,
    bool? fanStatus,
    String? currentMode,
  }) {
    return DashboardModel(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      chickenAge: chickenAge ?? this.chickenAge,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      lampStatus: lampStatus ?? this.lampStatus,
      fanStatus: fanStatus ?? this.fanStatus,
      currentMode: currentMode ?? this.currentMode,
    );
  }
}
