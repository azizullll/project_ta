import 'package:flutter/material.dart';
import 'dart:async';
import '../models/activity_model.dart';
import '../services/firebase_service.dart';
import '../services/history_db_helper.dart';

class HistoryController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final HistoryDatabaseHelper _historyDatabaseHelper = HistoryDatabaseHelper();

  List<ActivityModel> _activities = [];
  int _itemsPerPage = 10;
  bool _isInitialized = false;

  StreamSubscription? _logsSubscription;
  StreamSubscription? _sensorSubscription;
  StreamSubscription? _relaySubscription;
  StreamSubscription? _controlSubscription;
  StreamSubscription? _ageSubscription;
  StreamSubscription? _emergencySubscription;

  int _currentChickenAge = 1;
  bool _currentLampActive = false;
  bool _currentFanActive = false;
  final Map<String, String> _lastMessageBySource = {};

  List<ActivityModel> get activities => _activities;
  int get itemsPerPage => _itemsPerPage;
  int get currentChickenAge => _currentChickenAge;

  HistoryController() {
    _initializeController();
  }

  Future<void> _initializeController() async {
    if (_isInitialized) return;

    _firebaseService.initialize();
    await _syncInitialRelayState();
    await _loadLocalActivities();
    _startListening();
    _isInitialized = true;
  }

  Future<void> _syncInitialRelayState() async {
    try {
      final relayData = await _firebaseService.getCurrentRelayStatus();
      _currentFanActive = relayData['Kipas'] as bool? ?? false;
      _currentLampActive = relayData['Lampu'] as bool? ?? false;
    } catch (e) {
      debugPrint('Error loading initial relay status: $e');
    }
  }

  Future<void> _loadLocalActivities() async {
    try {
      _activities = await _historyDatabaseHelper.getActivities(limit: 500);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local history data: $e');
    }
  }

  void _startListening() {
    _ageSubscription = _firebaseService.getChickenAgeStream().listen((age) {
      _currentChickenAge = age;
      notifyListeners();
    });

    _logsSubscription = _firebaseService.getLogsStream().listen((logsData) {
      for (final entry in logsData.entries) {
        final source = entry.key;
        final rawValue = entry.value;
        if (rawValue == null) continue;

        final logText = rawValue.toString().trim();
        if (logText.isEmpty) continue;
        if (_lastMessageBySource[source] == logText) continue;
        _lastMessageBySource[source] = logText;

        final parsed = _parseTimestampedMessage(logText);
        _insertActivity(
          ActivityModel(
            id: '${source}_${DateTime.now().microsecondsSinceEpoch}',
            type: _getSeverityType(parsed.message),
            source: source,
            title: source.toUpperCase(),
            description: parsed.message,
            dateTime: parsed.dateTime,
            chickenAge: _currentChickenAge,
            lampActive: _currentLampActive,
            fanActive: _currentFanActive,
            iconType: source == 'wifi' || source == 'system' ? 'monitor' : 'settings',
          ),
        );
      }
    });

    _sensorSubscription = _firebaseService.getSensorDataStream().listen((sensorData) {
      if (sensorData.isEmpty) return;

      final temperature = (sensorData['temperature'] as num?)?.toDouble();
      final humidity = (sensorData['Humidity'] as num?)?.toDouble();
      final timestamp = sensorData['timestamp'] as String?;

      if (temperature == null && humidity == null) return;

      final sensorMessage =
          'Suhu: ${(temperature ?? 0).toStringAsFixed(1)}°C, Kelembapan: ${(humidity ?? 0).toStringAsFixed(1)}%';

      if (_lastMessageBySource['sensor_live'] == sensorMessage) return;
      _lastMessageBySource['sensor_live'] = sensorMessage;

      _insertActivity(
        ActivityModel(
          id: 'sensor_${DateTime.now().microsecondsSinceEpoch}',
          type: _getSeverityType(sensorMessage),
          source: 'sensor',
          title: 'SENSOR',
          description: sensorMessage,
          dateTime: _parseDateTimeFromString(timestamp) ?? DateTime.now(),
          chickenAge: _currentChickenAge,
          lampActive: _currentLampActive,
          fanActive: _currentFanActive,
          iconType: 'monitor',
        ),
      );
    });

    _relaySubscription = _firebaseService.getRelayStatusStream().listen((relayData) {
      if (relayData.isEmpty) return;

      final fanActive = relayData['Kipas'] as bool? ?? false;
      final lampActive = relayData['Lampu'] as bool? ?? false;
        _currentFanActive = fanActive;
        _currentLampActive = lampActive;
      final relayMessage =
          'Status Relay - Lampu: ${lampActive ? 'Aktif' : 'Nonaktif'}, Kipas: ${fanActive ? 'Aktif' : 'Nonaktif'}';

      if (_lastMessageBySource['relay'] == relayMessage) return;
      _lastMessageBySource['relay'] = relayMessage;

      _insertActivity(
        ActivityModel(
          id: 'relay_${DateTime.now().microsecondsSinceEpoch}',
          type: 'normal',
          source: 'relay',
          title: 'RELAY',
          description: relayMessage,
          dateTime: DateTime.now(),
          chickenAge: _currentChickenAge,
          lampActive: lampActive,
          fanActive: fanActive,
          iconType: 'settings',
        ),
      );
    });

    _controlSubscription = _firebaseService.getControlStatusStream().listen((controlData) {
      if (controlData.isEmpty) return;

      final fanAuto = controlData['fan']?['auto'] as bool? ?? true;
      final lightAuto = controlData['light']?['auto'] as bool? ?? true;
      final fanStatus = controlData['fan']?['status'] as bool? ?? false;
      final lightStatus = controlData['light']?['status'] as bool? ?? false;

      final modeMessage =
          'Mode Kontrol - Fan: ${fanAuto ? 'Auto' : 'Manual'} (${fanStatus ? 'Aktif' : 'Nonaktif'}), '
          'Lampu: ${lightAuto ? 'Auto' : 'Manual'} (${lightStatus ? 'Aktif' : 'Nonaktif'})';

      if (_lastMessageBySource['control'] == modeMessage) return;
      _lastMessageBySource['control'] = modeMessage;

      _insertActivity(
        ActivityModel(
          id: 'control_${DateTime.now().microsecondsSinceEpoch}',
          type: 'normal',
          source: 'control',
          title: 'CONTROL',
          description: modeMessage,
          dateTime: DateTime.now(),
          chickenAge: _currentChickenAge,
          lampActive: _currentLampActive,
          fanActive: _currentFanActive,
          iconType: 'settings',
        ),
      );
    });

    _emergencySubscription =
        _firebaseService.getEmergencyStatusStream().listen((emergencyData) {
      if (emergencyData.isEmpty) return;

      final highTemp = emergencyData['high_temperature'] as bool? ?? false;
      final lowTemp = emergencyData['low_temperature'] as bool? ?? false;
      final highHumidity = emergencyData['high_humidity'] as bool? ?? false;
      final lowHumidity = emergencyData['low_humidity'] as bool? ?? false;

      final message =
          'Status Darurat - Suhu Tinggi: ${highTemp ? 'Ya' : 'Tidak'}, '
          'Suhu Rendah: ${lowTemp ? 'Ya' : 'Tidak'}, '
          'Kelembapan Tinggi: ${highHumidity ? 'Ya' : 'Tidak'}, '
          'Kelembapan Rendah: ${lowHumidity ? 'Ya' : 'Tidak'}';

      if (_lastMessageBySource['status'] == message) return;
      _lastMessageBySource['status'] = message;

      _insertActivity(
        ActivityModel(
          id: 'status_${DateTime.now().microsecondsSinceEpoch}',
          type: (highTemp || lowTemp || highHumidity || lowHumidity)
              ? 'emergency'
              : 'normal',
          source: 'status',
          title: 'STATUS',
          description: message,
          dateTime: DateTime.now(),
          chickenAge: _currentChickenAge,
          lampActive: _currentLampActive,
          fanActive: _currentFanActive,
          iconType: 'monitor',
        ),
      );
    });
  }

  void _insertActivity(ActivityModel activity) {
    if (_activities.isNotEmpty) {
      final latest = _activities.first;
      if (latest.source == activity.source &&
          latest.description == activity.description &&
          latest.chickenAge == activity.chickenAge) {
        return;
      }
    }

    _activities.insert(0, activity);
    if (_activities.length > 500) {
      _activities = _activities.sublist(0, 500);
    }

    _persistActivity(activity);
    notifyListeners();
  }

  Future<void> _persistActivity(ActivityModel activity) async {
    try {
      await _historyDatabaseHelper.insertActivity(activity);
      await _historyDatabaseHelper.trimToLimit(500);
    } catch (e) {
      debugPrint('Error saving local history data: $e');
    }
  }

  _ParsedLogMessage _parseTimestampedMessage(String rawText) {
    final separatorIndex = rawText.indexOf(': ');
    if (separatorIndex <= 0) {
      return _ParsedLogMessage(dateTime: DateTime.now(), message: rawText);
    }

    final timestampText = rawText.substring(0, separatorIndex).trim();
    final message = rawText.substring(separatorIndex + 2).trim();
    final dateTime = _parseDateTimeFromString(timestampText) ?? DateTime.now();

    return _ParsedLogMessage(dateTime: dateTime, message: message);
  }

  DateTime? _parseDateTimeFromString(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _getSeverityType(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('darurat') || lower.contains('emergency')) {
      return 'emergency';
    }
    if (lower.contains('fail') ||
        lower.contains('error') ||
        lower.contains('lost') ||
        lower.contains('disconnected')) {
      return 'error';
    }
    if (lower.contains('peringatan') || lower.contains('warning')) {
      return 'warning';
    }
    return 'normal';
  }

  List<ActivityModel> _getFilteredActivities({
    DateTime? selectedDate,
    int? selectedAge,
    String? selectedType,
  }) {
    return _activities.where((activity) {
      final matchesDate = selectedDate == null
          ? true
          : activity.dateTime.year == selectedDate.year &&
                activity.dateTime.month == selectedDate.month &&
                activity.dateTime.day == selectedDate.day;

      final matchesAge = selectedAge == null ? true : activity.chickenAge == selectedAge;
      final matchesType = selectedType == null ? true : activity.source == selectedType;

      return matchesDate && matchesAge && matchesType;
    }).toList();
  }

  int totalPagesForFilters({
    DateTime? selectedDate,
    int? selectedAge,
    String? selectedType,
  }) {
    final filteredCount = _getFilteredActivities(
      selectedDate: selectedDate,
      selectedAge: selectedAge,
      selectedType: selectedType,
    ).length;

    if (filteredCount == 0) return 1;
    return (filteredCount / _itemsPerPage).ceil();
  }

  List<ActivityModel> getFilteredActivities({
    DateTime? selectedDate,
    int? selectedAge,
    String? selectedType,
  }) {
    return _getFilteredActivities(
      selectedDate: selectedDate,
      selectedAge: selectedAge,
      selectedType: selectedType,
    );
  }

  // Get activities for specific page with active filters
  List<ActivityModel> getActivitiesForPage({
    required int page,
    DateTime? selectedDate,
    int? selectedAge,
    String? selectedType,
  }) {
    final filteredActivities = _getFilteredActivities(
      selectedDate: selectedDate,
      selectedAge: selectedAge,
      selectedType: selectedType,
    );

    final startIndex = (page - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= filteredActivities.length) {
      return [];
    }

    return filteredActivities.sublist(
      startIndex,
      endIndex > filteredActivities.length ? filteredActivities.length : endIndex,
    );
  }

  // Set items per page
  void setItemsPerPage(int count) {
    _itemsPerPage = count;
    notifyListeners();
  }

  // Add new activity
  void addActivity(ActivityModel activity) {
    _activities.insert(0, activity);
    notifyListeners();
  }

  // Clear all activities
  void clearAllActivities() {
    _activities.clear();
    _historyDatabaseHelper.clearAllActivities();
    notifyListeners();
  }

  // Delete specific activity
  void deleteActivity(String id) {
    _activities.removeWhere((a) => a.id == id);
    _historyDatabaseHelper.deleteActivity(id);
    notifyListeners();
  }

  // Export activities (placeholder)
  void exportActivities() {
    // Implement export logic here
  }

  // Refresh data
  Future<void> refreshData() async {
    _lastMessageBySource.clear();
    await _loadLocalActivities();
  }

  @override
  void dispose() {
    _logsSubscription?.cancel();
    _sensorSubscription?.cancel();
    _relaySubscription?.cancel();
    _controlSubscription?.cancel();
    _ageSubscription?.cancel();
    _emergencySubscription?.cancel();
    super.dispose();
  }
}

class _ParsedLogMessage {
  final DateTime dateTime;
  final String message;

  _ParsedLogMessage({required this.dateTime, required this.message});
}
