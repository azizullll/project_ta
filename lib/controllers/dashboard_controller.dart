import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../services/firebase_service.dart';
import 'dart:async';

class DashboardController extends ChangeNotifier {
  // Singleton pattern
  static final DashboardController _instance = DashboardController._internal();
  factory DashboardController() => _instance;
  DashboardController._internal() {
    _initializeFirebase();
  }

  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription? _sensorSubscription;
  StreamSubscription? _relaySubscription;
  StreamSubscription? _controlSubscription;
  StreamSubscription? _ageSubscription;
  StreamSubscription? _emergencySubscription;

  DashboardModel _data = DashboardModel(
    temperature: 0.0,
    humidity: 0.0,
    chickenAge: 1,
    isAutoMode: true,
    lampStatus: false,
    fanStatus: false,
    currentMode: 'Otomatis',
  );

  // Emergency status
  bool _highTemperatureAlert = false;
  bool _lowTemperatureAlert = false;
  bool _highHumidityAlert = false;
  bool _lowHumidityAlert = false;

  // Device status messages
  String _temperatureStatus = '';
  String _humidityStatus = '';

  // Connection status
  bool _isConnected = false;
  String _lastUpdateTime = '';

  DashboardModel get data => _data;
  bool get isConnected => _isConnected;
  String get lastUpdateTime => _lastUpdateTime;
  bool get highTemperatureAlert => _highTemperatureAlert;
  bool get lowTemperatureAlert => _lowTemperatureAlert;
  bool get highHumidityAlert => _highHumidityAlert;
  bool get lowHumidityAlert => _lowHumidityAlert;
  String get temperatureStatus => _temperatureStatus;
  String get humidityStatus => _humidityStatus;

  void _initializeFirebase() {
    _firebaseService.initialize();
    _startListening();
  }

  void _startListening() {
    // Listen to sensor data (temperature, humidity)
    _sensorSubscription = _firebaseService.getSensorDataStream().listen((sensorData) {
      if (sensorData.isNotEmpty) {
        _isConnected = true;
        final temperature = (sensorData['temperature'] as num?)?.toDouble() ?? _data.temperature;
        final humidity = (sensorData['Humidity'] as num?)?.toDouble() ?? _data.humidity;
        final timestamp = sensorData['timestamp'] as String? ?? '';
        
        _data = _data.copyWith(
          temperature: temperature,
          humidity: humidity,
        );
        _lastUpdateTime = timestamp;
        notifyListeners();
      }
    }, onError: (error) {
      print('Error listening to sensor data: $error');
      _isConnected = false;
      notifyListeners();
    });

    // Listen to relay status (actual device status from ESP32)
    _relaySubscription = _firebaseService.getRelayStatusStream().listen((relayData) {
      if (relayData.isNotEmpty) {
        final fanStatus = relayData['Kipas'] as bool? ?? _data.fanStatus;
        final lampStatus = relayData['Lampu'] as bool? ?? _data.lampStatus;
        
        _data = _data.copyWith(
          fanStatus: fanStatus,
          lampStatus: lampStatus,
        );
        notifyListeners();
      }
    }, onError: (error) {
      print('Error listening to relay data: $error');
    });

    // Listen to control mode
    _controlSubscription = _firebaseService.getControlStatusStream().listen((controlData) {
      if (controlData.isNotEmpty) {
        // Check if both fan and light are in auto mode
        final fanAuto = controlData['fan']?['auto'] as bool? ?? true;
        final lightAuto = controlData['light']?['auto'] as bool? ?? true;
        final isAutoMode = fanAuto && lightAuto;
        
        _data = _data.copyWith(
          isAutoMode: isAutoMode,
          currentMode: isAutoMode ? 'Otomatis' : 'Manual',
        );
        notifyListeners();
      }
    }, onError: (error) {
      print('Error listening to control data: $error');
    });

    // Listen to chicken age
    _ageSubscription = _firebaseService.getChickenAgeStream().listen((age) {
      _data = _data.copyWith(chickenAge: age);
      notifyListeners();
    }, onError: (error) {
      print('Error listening to chicken age: $error');
    });

    // Listen to emergency alerts
    _emergencySubscription = _firebaseService.getEmergencyStatusStream().listen((emergencyData) {
      if (emergencyData.isNotEmpty) {
        _highTemperatureAlert = emergencyData['high_temperature'] as bool? ?? false;
        _lowTemperatureAlert = emergencyData['low_temperature'] as bool? ?? false;
        _highHumidityAlert = emergencyData['high_humidity'] as bool? ?? false;
        _lowHumidityAlert = emergencyData['low_humidity'] as bool? ?? false;
        notifyListeners();
      }
    }, onError: (error) {
      print('Error listening to emergency data: $error');
    });

    // Listen to device status messages
    _firebaseService.getDeviceStatusStream().listen((statusData) {
      if (statusData.isNotEmpty) {
        _temperatureStatus = statusData['temperature'] as String? ?? '';
        _humidityStatus = statusData['humidity'] as String? ?? '';
        notifyListeners();
      }
    }, onError: (error) {
      print('Error listening to device status: $error');
    });
  }

  // Toggle auto mode - affects both fan and light
  Future<void> toggleAutoMode(bool value) async {
    try {
      await _firebaseService.setFanAutoMode(value);
      await _firebaseService.setLightAutoMode(value);
      
      _data = _data.copyWith(
        isAutoMode: value,
        currentMode: value ? 'Otomatis' : 'Manual',
      );
      notifyListeners();
    } catch (e) {
      print('Error toggling auto mode: $e');
    }
  }

  // Update temperature - not needed as it comes from Firebase
  void updateTemperature(double temperature) {
    // This method is now handled by Firebase stream
    // Keeping for backward compatibility
  }

  // Update humidity - not needed as it comes from Firebase
  void updateHumidity(double humidity) {
    // This method is now handled by Firebase stream
    // Keeping for backward compatibility
  }

  // Update chicken age
  Future<void> updateChickenAge(int age) async {
    try {
      await _firebaseService.setChickenAge(age);
      _data = _data.copyWith(chickenAge: age);
      notifyListeners();
    } catch (e) {
      print('Error updating chicken age: $e');
    }
  }

  // Manual control lamp
  Future<void> toggleLamp(bool status) async {
    if (!_data.isAutoMode) {
      try {
        // First set to manual mode
        await _firebaseService.setLightAutoMode(false);
        // Then set the status
        await _firebaseService.setLightStatus(status);
        
        _data = _data.copyWith(
          lampStatus: status,
          isAutoMode: false,
          currentMode: 'Manual',
        );
        notifyListeners();
      } catch (e) {
        print('Error toggling lamp: $e');
      }
    }
  }

  // Manual control fan
  Future<void> toggleFan(bool status) async {
    if (!_data.isAutoMode) {
      try {
        // First set to manual mode
        await _firebaseService.setFanAutoMode(false);
        // Then set the status
        await _firebaseService.setFanStatus(status);
        
        _data = _data.copyWith(
          fanStatus: status,
          isAutoMode: false,
          currentMode: 'Manual',
        );
        notifyListeners();
      } catch (e) {
        print('Error toggling fan: $e');
      }
    }
  }

  // Force refresh data from Firebase
  Future<void> refreshData() async {
    try {
      // Force listeners to re-read from Firebase
      notifyListeners();
    } catch (e) {
      print('Error refreshing data: $e');
    }
  }

  // Auto control devices based on temperature and humidity - not needed anymore
  void _autoControlDevices() {
    // This is now handled by ESP32 based on Firebase data
    // Keeping for backward compatibility
  }

  // Simulate real-time data updates - not needed anymore
  void simulateDataUpdate() {
    // This is now handled by Firebase real-time updates
    // Keeping for backward compatibility
  }

  // Cleanup method
  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _relaySubscription?.cancel();
    _controlSubscription?.cancel();
    _ageSubscription?.cancel();
    _emergencySubscription?.cancel();
    super.dispose();
  }
}
