import 'package:flutter/material.dart';

class AgeRangeController extends ChangeNotifier {
  int _currentAge = 1;
  int _maxAge = 4;
  bool _autoRangeEnabled = false;

  // Temperature settings
  double _minTemperature = 25.0;
  double _targetTemperature = 28.0;
  double _maxTemperature = 32.0;

  // Humidity settings
  double _minHumidity = 55.0;
  double _targetHumidity = 60.0;
  double _maxHumidity = 70.0;

  int get currentAge => _currentAge;
  int get maxAge => _maxAge;
  bool get autoRangeEnabled => _autoRangeEnabled;

  // Temperature getters
  double get minTemperature => _minTemperature;
  double get targetTemperature => _targetTemperature;
  double get maxTemperature => _maxTemperature;

  // Humidity getters
  double get minHumidity => _minHumidity;
  double get targetHumidity => _targetHumidity;
  double get maxHumidity => _maxHumidity;

  // Set current age
  void setCurrentAge(int age) {
    if (age >= 1 && age <= _maxAge) {
      _currentAge = age;
      notifyListeners();
    }
  }

  // Toggle auto range
  void toggleAutoRange(bool value) {
    _autoRangeEnabled = value;
    notifyListeners();
  }

  // Get progress value (0.0 to 1.0)
  double getProgress() {
    return (_currentAge - 1) / (_maxAge - 1);
  }

  // Get color for age button
  Color getAgeColor(int age) {
    if (age == _currentAge) {
      return Colors.orange;
    } else if (age < _currentAge) {
      return Colors.orange.shade200;
    } else {
      return Colors.orange.shade50;
    }
  }

  // Increment age
  void incrementAge() {
    if (_currentAge < _maxAge) {
      _currentAge++;
      notifyListeners();
    }
  }

  // Decrement age
  void decrementAge() {
    if (_currentAge > 1) {
      _currentAge--;
      notifyListeners();
    }
  }

  // Reset to week 1
  void resetAge() {
    _currentAge = 1;
    notifyListeners();
  }

  // Set minimum temperature
  void setMinTemperature(double value) {
    _minTemperature = value;
    notifyListeners();
  }

  // Set target temperature
  void setTargetTemperature(double value) {
    _targetTemperature = value;
    notifyListeners();
  }

  // Set max temperature
  void setMaxTemperature(double value) {
    _maxTemperature = value;
    notifyListeners();
  }

  // Set minimum humidity
  void setMinHumidity(double value) {
    _minHumidity = value;
    notifyListeners();
  }

  // Set target humidity
  void setTargetHumidity(double value) {
    _targetHumidity = value;
    notifyListeners();
  }

  // Set max humidity
  void setMaxHumidity(double value) {
    _maxHumidity = value;
    notifyListeners();
  }
}
