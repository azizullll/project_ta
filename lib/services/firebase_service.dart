import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late DatabaseReference _database;
  
  void initialize() {
    _database = FirebaseDatabase.instance.ref();
  }

  // Listen to sensor data changes
  Stream<Map<String, dynamic>> getSensorDataStream() {
    return _database.child('sensor').onValue.map((event) {
      if (event.snapshot.exists) {
        final rawData = event.snapshot.value as Map<Object?, Object?>?;
        if (rawData != null) {
          return Map<String, dynamic>.from(rawData);
        }
      }
      return <String, dynamic>{};
    });
  }

  // Listen to relay status changes
  Stream<Map<String, dynamic>> getRelayStatusStream() {
    return _database.child('relay').onValue.map((event) {
      if (event.snapshot.exists) {
        final rawData = event.snapshot.value as Map<Object?, Object?>?;
        if (rawData != null) {
          return Map<String, dynamic>.from(rawData);
        }
      }
      return <String, dynamic>{};
    });
  }

  // Listen to control mode changes
  Stream<Map<String, dynamic>> getControlStatusStream() {
    return _database.child('control').onValue.map((event) {
      if (event.snapshot.exists) {
        final rawData = event.snapshot.value as Map<Object?, Object?>?;
        if (rawData != null) {
          return Map<String, dynamic>.from(rawData);
        }
      }
      return <String, dynamic>{};
    });
  }

  // Listen to chicken age changes
  Stream<int> getChickenAgeStream() {
    return _database.child('chicken_age').onValue.map((event) {
      if (event.snapshot.exists) {
        return event.snapshot.value as int? ?? 1;
      }
      return 1;
    });
  }

  // Listen to emergency status
  Stream<Map<String, dynamic>> getEmergencyStatusStream() {
    return _database.child('emergency').onValue.map((event) {
      if (event.snapshot.exists) {
        final rawData = event.snapshot.value as Map<Object?, Object?>?;
        if (rawData != null) {
          return Map<String, dynamic>.from(rawData);
        }
      }
      return <String, dynamic>{};
    });
  }

  // Listen to device status
  Stream<Map<String, dynamic>> getDeviceStatusStream() {
    return _database.child('status').onValue.map((event) {
      if (event.snapshot.exists) {
        final rawData = event.snapshot.value as Map<Object?, Object?>?;
        if (rawData != null) {
          return Map<String, dynamic>.from(rawData);
        }
      }
      return <String, dynamic>{};
    });
  }

  // Control Methods - Send commands to ESP32
  
  // Set fan control mode (auto/manual)
  Future<void> setFanAutoMode(bool isAuto) async {
    try {
      await _database.child('control/fan/auto').set(isAuto);
    } catch (e) {
      print('Error setting fan auto mode: $e');
    }
  }

  // Set fan manual status
  Future<void> setFanStatus(bool status) async {
    try {
      await _database.child('control/fan/status').set(status);
    } catch (e) {
      print('Error setting fan status: $e');
    }
  }

  // Set light control mode (auto/manual)
  Future<void> setLightAutoMode(bool isAuto) async {
    try {
      await _database.child('control/light/auto').set(isAuto);
    } catch (e) {
      print('Error setting light auto mode: $e');
    }
  }

  // Set light manual status
  Future<void> setLightStatus(bool status) async {
    try {
      await _database.child('control/light/status').set(status);
    } catch (e) {
      print('Error setting light status: $e');
    }
  }

  // Set chicken age
  Future<void> setChickenAge(int age) async {
    try {
      await _database.child('chicken_age').set(age);
    } catch (e) {
      print('Error setting chicken age: $e');
    }
  }

  // Update temperature and humidity ranges
  Future<void> updateRanges(int week, Map<String, dynamic> ranges) async {
    try {
      await _database.child('ranges/week$week').set(ranges);
    } catch (e) {
      print('Error updating ranges: $e');
    }
  }

  // Persist whether dynamic range mode is enabled.
  Future<void> setDynamicRangeEnabled(bool enabled) async {
    try {
      await _database.child('settings/dynamic_range_enabled').set(enabled);
    } catch (e) {
      print('Error setting dynamic range mode: $e');
    }
  }

  // Read dynamic range mode preference.
  Future<bool?> getDynamicRangeEnabled() async {
    try {
      final snapshot = await _database.child('settings/dynamic_range_enabled').get();
      if (snapshot.exists) {
        return snapshot.value as bool?;
      }
    } catch (e) {
      print('Error getting dynamic range mode: $e');
    }
    return null;
  }

  // Get ranges for a specific week (one-time read).
  Future<Map<String, dynamic>?> getRangesForWeek(int week) async {
    try {
      final snapshot = await _database.child('ranges/week$week').get();
      if (snapshot.exists) {
        final rawData = snapshot.value as Map<Object?, Object?>?;
        if (rawData != null) {
          return rawData.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
      }
    } catch (e) {
      print('Error getting ranges for week $week: $e');
    }
    return null;
  }

  // Get current sensor data (one-time read)
  Future<Map<String, dynamic>> getCurrentSensorData() async {
    try {
      final snapshot = await _database.child('sensor').get();
      if (snapshot.exists) {
        final rawData = snapshot.value as Map<Object?, Object?>?;
        if (rawData != null) {
          return Map<String, dynamic>.from(rawData);
        }
      }
    } catch (e) {
      print('Error getting sensor data: $e');
    }
    return <String, dynamic>{};
  }

  // Get current relay status (one-time read)
  Future<Map<String, dynamic>> getCurrentRelayStatus() async {
    try {
      final snapshot = await _database.child('relay').get();
      if (snapshot.exists) {
        final rawData = snapshot.value as Map<Object?, Object?>?;
        if (rawData != null) {
          return Map<String, dynamic>.from(rawData);
        }
      }
    } catch (e) {
      print('Error getting relay status: $e');
    }
    return <String, dynamic>{};
  }

  // Get logs
  Stream<Map<String, dynamic>> getLogsStream() {
    return _database.child('logs').onValue.map((event) {
      if (event.snapshot.exists) {
        final rawData = event.snapshot.value as Map<Object?, Object?>?;
        if (rawData != null) {
          return Map<String, dynamic>.from(rawData);
        }
      }
      return <String, dynamic>{};
    });
  }

  // Get fuzzy logic data
  Stream<Map<String, dynamic>> getFuzzyDataStream() {
    return _database.child('fuzzy').onValue.map((event) {
      if (event.snapshot.exists) {
        final rawData = event.snapshot.value as Map<Object?, Object?>?;
        if (rawData != null) {
          return Map<String, dynamic>.from(rawData);
        }
      }
      return <String, dynamic>{};
    });
  }

  // Combined stream for all data
  Stream<Map<String, dynamic>> getAllDataStream() {
    return _database.onValue.map((event) {
      if (event.snapshot.exists) {
        final rawData = event.snapshot.value as Map<Object?, Object?>?;
        if (rawData != null) {
          return Map<String, dynamic>.from(rawData);
        }
      }
      return <String, dynamic>{};
    });
  }
}