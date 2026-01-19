class SensorDataModel {
  final String sensor;
  final double value;
  final String status;
  final String time;

  SensorDataModel({
    required this.sensor,
    required this.value,
    required this.status,
    required this.time,
  });

  SensorDataModel copyWith({
    String? sensor,
    double? value,
    String? status,
    String? time,
  }) {
    return SensorDataModel(
      sensor: sensor ?? this.sensor,
      value: value ?? this.value,
      status: status ?? this.status,
      time: time ?? this.time,
    );
  }
}
