import 'package:flutter/material.dart';

class ControlController extends ChangeNotifier {
  bool _isAutoMode = true;
  bool _lampStatus = false;
  bool _fanStatus = false;

  bool get isAutoMode => _isAutoMode;
  bool get lampStatus => _lampStatus;
  bool get fanStatus => _fanStatus;
  String get currentMode => _isAutoMode ? 'Otomatis' : 'Manual';

  // Toggle between auto and manual mode
  void toggleMode() {
    _isAutoMode = !_isAutoMode;
    notifyListeners();
  }

  // Set mode explicitly
  void setMode(bool isAuto) {
    _isAutoMode = isAuto;
    notifyListeners();
  }

  // Toggle lamp
  void toggleLamp(bool value) {
    if (!_isAutoMode) {
      _lampStatus = value;
      notifyListeners();
    }
  }

  // Toggle fan
  void toggleFan(bool value) {
    if (!_isAutoMode) {
      _fanStatus = value;
      notifyListeners();
    }
  }

  // Auto control based on sensor data (called from dashboard)
  void autoControlDevices(double temperature, double humidity) {
    if (_isAutoMode) {
      // Lamp: Turn on if humidity is low
      _lampStatus = humidity < 40;

      // Fan: Turn on if temperature is high
      _fanStatus = temperature > 30;

      notifyListeners();
    }
  }

  // Manual control for lamp
  void setLampStatus(bool status) {
    if (!_isAutoMode) {
      _lampStatus = status;
      notifyListeners();
    }
  }

  // Manual control for fan
  void setFanStatus(bool status) {
    if (!_isAutoMode) {
      _fanStatus = status;
      notifyListeners();
    }
  }
}
