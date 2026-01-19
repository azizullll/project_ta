import 'package:flutter/material.dart';
import '../models/sensor_data_model.dart';

class DataController extends ChangeNotifier {
  double _temperature = 28.0;
  double _humidity = 45.0;
  String _lastUpdated = '23:28:10';

  List<SensorDataModel> _sensorDataList = [];
  int _deathCount = 0;

  double get temperature => _temperature;
  double get humidity => _humidity;
  String get lastUpdated => _lastUpdated;
  List<SensorDataModel> get sensorDataList => _sensorDataList;
  int get deathCount => _deathCount;
  bool get hasDeathData => _deathCount > 0;

  DataController() {
    _initializeSensorData();
  }

  void _initializeSensorData() {
    _sensorDataList = [
      SensorDataModel(
        sensor: 'Suhu',
        value: 32.1,
        status: 'Perhatian',
        time: '23.57.12',
      ),
      SensorDataModel(
        sensor: 'Kelembapan',
        value: 62.3,
        status: 'Perhatian',
        time: '23.57.12',
      ),
    ];
    notifyListeners();
  }

  // Update temperature
  void updateTemperature(double temp) {
    _temperature = temp;
    _updateSensorData('Suhu', temp);
    notifyListeners();
  }

  // Update humidity
  void updateHumidity(double humid) {
    _humidity = humid;
    _updateSensorData('Kelembapan', humid);
    notifyListeners();
  }

  // Update sensor data in the list
  void _updateSensorData(String sensor, double value) {
    final now = DateTime.now();
    final timeString = '${now.hour}.${now.minute}.${now.second}';

    final index = _sensorDataList.indexWhere((data) => data.sensor == sensor);
    if (index != -1) {
      _sensorDataList[index] = SensorDataModel(
        sensor: sensor,
        value: value,
        status: _getStatus(sensor, value),
        time: timeString,
      );
    }

    _updateLastUpdatedTime();
  }

  // Determine status based on sensor value
  String _getStatus(String sensor, double value) {
    if (sensor == 'Suhu') {
      if (value > 30) return 'Perhatian';
      if (value < 20) return 'Perhatian';
      return 'Normal';
    } else if (sensor == 'Kelembapan') {
      if (value > 60) return 'Perhatian';
      if (value < 40) return 'Perhatian';
      return 'Normal';
    }
    return 'Normal';
  }

  // Update last updated time
  void _updateLastUpdatedTime() {
    final now = DateTime.now();
    _lastUpdated =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    notifyListeners();
  }

  // Add death record
  void addDeathRecord(int count) {
    _deathCount += count;
    notifyListeners();
  }

  // Reset death count
  void resetDeathCount() {
    _deathCount = 0;
    notifyListeners();
  }

  // Refresh data (simulate)
  void refreshData() {
    _updateLastUpdatedTime();
    // Simulate data refresh
    _temperature =
        25.0 + (DateTime.now().millisecondsSinceEpoch % 10).toDouble();
    _humidity = 40.0 + (DateTime.now().millisecondsSinceEpoch % 20).toDouble();

    _initializeSensorData();
    notifyListeners();
  }
}
