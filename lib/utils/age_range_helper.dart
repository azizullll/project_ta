import '../services/firebase_service.dart';

class AgeRangeHelper {
  static final FirebaseService _firebaseService = FirebaseService();

  // Temperature and humidity ranges for each week
  static const Map<int, Map<String, dynamic>> defaultRanges = {
    1: {
      'temperature': {'min': 33.0, 'max': 35.0, 'target': 34.0},
      'humidity': {'min': 60.0, 'max': 70.0, 'target': 65.0},
    },
    2: {
      'temperature': {'min': 30.0, 'max': 33.0, 'target': 31.5},
      'humidity': {'min': 60.0, 'max': 65.0, 'target': 62.5},
    },
    3: {
      'temperature': {'min': 28.0, 'max': 30.0, 'target': 29.0},
      'humidity': {'min': 60.0, 'max': 65.0, 'target': 62.5},
    },
    4: {
      'temperature': {'min': 25.0, 'max': 28.0, 'target': 26.5},
      'humidity': {'min': 55.0, 'max': 60.0, 'target': 57.5},
    },
  };

  // Get range data for specific week
  static Map<String, dynamic>? getRangeForWeek(int week) {
    if (week < 1 || week > 4) return null;
    return defaultRanges[week];
  }

  // Update ranges in Firebase for a specific week
  static Future<bool> updateRangeForWeek(int week, Map<String, dynamic> ranges) async {
    try {
      await _firebaseService.updateRanges(week, ranges);
      return true;
    } catch (e) {
      print('Error updating ranges for week $week: $e');
      return false;
    }
  }

  // Initialize all default ranges in Firebase
  static Future<bool> initializeDefaultRanges() async {
    try {
      for (int week = 1; week <= 4; week++) {
        final ranges = defaultRanges[week]!;
        await _firebaseService.updateRanges(week, ranges);
      }
      return true;
    } catch (e) {
      print('Error initializing default ranges: $e');
      return false;
    }
  }

  // Get temperature status based on current temperature and week
  static String getTemperatureStatus(double temperature, int week) {
    final range = getRangeForWeek(week);
    if (range == null) return 'Week not valid';

    final tempRange = range['temperature'] as Map<String, dynamic>;
    final min = tempRange['min'] as double;
    final max = tempRange['max'] as double;
    final target = tempRange['target'] as double;

    if (temperature < min - 2) {
      return 'Sangat Rendah - Berbahaya!';
    } else if (temperature < min) {
      return 'Rendah - Perlu Pemanasan';
    } else if (temperature >= min && temperature <= max) {
      final distance = (temperature - target).abs();
      if (distance <= 0.5) {
        return 'Optimal';
      } else {
        return 'Normal';
      }
    } else if (temperature <= max + 2) {
      return 'Tinggi - Perlu Pendinginan';
    } else {
      return 'Sangat Tinggi - Berbahaya!';
    }
  }

  // Get humidity status based on current humidity and week
  static String getHumidityStatus(double humidity, int week) {
    final range = getRangeForWeek(week);
    if (range == null) return 'Week not valid';

    final humidityRange = range['humidity'] as Map<String, dynamic>;
    final min = humidityRange['min'] as double;
    final max = humidityRange['max'] as double;
    final target = humidityRange['target'] as double;

    if (humidity < min - 5) {
      return 'Sangat Rendah - Berbahaya!';
    } else if (humidity < min) {
      return 'Rendah - Perlu Humidifier';
    } else if (humidity >= min && humidity <= max) {
      final distance = (humidity - target).abs();
      if (distance <= 2.5) {
        return 'Optimal';
      } else {
        return 'Normal';
      }
    } else if (humidity <= max + 5) {
      return 'Tinggi - Perlu Dehumidifier';
    } else {
      return 'Sangat Tinggi - Berbahaya!';
    }
  }

  // Get recommended action based on temperature and humidity
  static Map<String, dynamic> getRecommendedActions(double temperature, double humidity, int week) {
    final tempStatus = getTemperatureStatus(temperature, week);
    final humidityStatus = getHumidityStatus(humidity, week);
    
    Map<String, dynamic> actions = {
      'fan': false,
      'light': false,
      'emergency': false,
      'message': '',
    };

    // Temperature actions
    if (tempStatus.contains('Sangat Tinggi') || tempStatus.contains('Tinggi')) {
      actions['fan'] = true;
    }

    // Humidity actions
    if (humidityStatus.contains('Tinggi')) {
      actions['light'] = true; // Light generates heat to reduce humidity
    }

    // Emergency situations
    if (tempStatus.contains('Sangat') || humidityStatus.contains('Sangat')) {
      actions['emergency'] = true;
    }

    // Special case: if temperature is very low, turn on light for heating
    if (tempStatus.contains('Sangat Rendah') || tempStatus.contains('Rendah')) {
      actions['light'] = true;
    }

    // Generate message
    List<String> messages = [];
    if (actions['fan'] as bool) messages.add('Kipas ON (Pendinginan)');
    if (actions['light'] as bool) messages.add('Lampu ON (Pemanasan/Dehumidifier)');
    if (actions['emergency'] as bool) messages.add('⚠️ KONDISI DARURAT!');
    
    actions['message'] = messages.isEmpty ? 'Semua kondisi normal' : messages.join(', ');

    return actions;
  }

  // Validate custom ranges
  static bool validateRanges(Map<String, dynamic> ranges) {
    try {
      final tempRange = ranges['temperature'] as Map<String, dynamic>;
      final humidityRange = ranges['humidity'] as Map<String, dynamic>;

      final tempMin = tempRange['min'] as double;
      final tempMax = tempRange['max'] as double;
      final tempTarget = tempRange['target'] as double;

      final humidityMin = humidityRange['min'] as double;
      final humidityMax = humidityRange['max'] as double;
      final humidityTarget = humidityRange['target'] as double;

      // Temperature validations
      if (tempMin >= tempMax) return false;
      if (tempTarget < tempMin || tempTarget > tempMax) return false;
      if (tempMin < 20 || tempMax > 45) return false; // Reasonable limits for chickens

      // Humidity validations
      if (humidityMin >= humidityMax) return false;
      if (humidityTarget < humidityMin || humidityTarget > humidityMax) return false;
      if (humidityMin < 30 || humidityMax > 90) return false; // Reasonable limits

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get status color for UI
  static String getStatusColor(String status) {
    if (status.contains('Optimal')) {
      return 'green';
    } else if (status.contains('Normal')) {
      return 'blue';
    } else if (status.contains('Rendah') || status.contains('Tinggi')) {
      return 'orange';
    } else if (status.contains('Sangat')) {
      return 'red';
    }
    return 'grey';
  }
}