import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';

class DashboardController extends ChangeNotifier {
  // Singleton pattern
  static final DashboardController _instance = DashboardController._internal();
  factory DashboardController() => _instance;
  DashboardController._internal();

  DashboardModel _data = DashboardModel(
    temperature: 28.0,
    humidity: 45.0,
    chickenAge: 1,
    isAutoMode: true,
    lampStatus: true,
    fanStatus: false,
    currentMode: 'Otomatis',
  );

  DashboardModel get data => _data;

  // Toggle auto mode
  void toggleAutoMode(bool value) {
    _data = _data.copyWith(
      isAutoMode: value,
      currentMode: value ? 'Otomatis' : 'Manual',
    );
    notifyListeners();
  }

  // Update temperature
  void updateTemperature(double temperature) {
    _data = _data.copyWith(temperature: temperature);
    _autoControlDevices();
    notifyListeners();
  }

  // Update humidity
  void updateHumidity(double humidity) {
    _data = _data.copyWith(humidity: humidity);
    _autoControlDevices();
    notifyListeners();
  }

  // Update chicken age
  void updateChickenAge(int age) {
    _data = _data.copyWith(chickenAge: age);
    notifyListeners();
  }

  // Manual control lamp
  void toggleLamp(bool status) {
    if (!_data.isAutoMode) {
      _data = _data.copyWith(lampStatus: status);
      notifyListeners();
    }
  }

  // Manual control fan
  void toggleFan(bool status) {
    if (!_data.isAutoMode) {
      _data = _data.copyWith(fanStatus: status);
      notifyListeners();
    }
  }

  // Auto control devices based on temperature and humidity
  void _autoControlDevices() {
    if (_data.isAutoMode) {
      bool shouldTurnOnFan = _data.temperature > 30 || _data.humidity > 60;
      bool shouldTurnOnLamp = _data.temperature < 25;

      _data = _data.copyWith(
        fanStatus: shouldTurnOnFan,
        lampStatus: shouldTurnOnLamp,
      );
    }
  }

  // Simulate real-time data updates
  void simulateDataUpdate() {
    // This method can be called periodically to simulate sensor data
    // In real application, this would be replaced with actual sensor readings
    _data = _data.copyWith(
      temperature:
          25.0 + (DateTime.now().millisecondsSinceEpoch % 10).toDouble(),
      humidity: 40.0 + (DateTime.now().millisecondsSinceEpoch % 20).toDouble(),
    );
    _autoControlDevices();
    notifyListeners();
  }
}
