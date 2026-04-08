import 'package:flutter/foundation.dart';

import '../models/activity_model.dart';
import '../services/history_db_helper.dart';

class StatisticsController extends ChangeNotifier {
  final HistoryDatabaseHelper _historyDbHelper = HistoryDatabaseHelper();

  final Map<String, List<double>> _lampAndFanData = {
    'Lampu': List<double>.filled(7, 0),
    'Kipas': List<double>.filled(7, 0),
  };

  final Map<String, List<double>> _powerAndBatteryData = {
    'Listrik': List<double>.filled(7, 0),
    'Backup Daya': List<double>.filled(7, 24),
  };

  Map<String, List<double>> get lampAndFanData => _lampAndFanData;
  Map<String, List<double>> get powerAndBatteryData => _powerAndBatteryData;

  double get totalOperationHours {
    final lampTotal = _lampAndFanData['Lampu']!.fold<double>(0, (a, b) => a + b);
    final fanTotal = _lampAndFanData['Kipas']!.fold<double>(0, (a, b) => a + b);
    return lampTotal + fanTotal;
  }

  double get listrikHours =>
      _powerAndBatteryData['Listrik']!.fold<double>(0, (a, b) => a + b);

  double get backupDayaHours =>
      _powerAndBatteryData['Backup Daya']!.fold<double>(0, (a, b) => a + b);

  StatisticsController() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(
      const Duration(days: 6),
    );
    updateDataForRange(start);
  }

  Future<void> updateDataForRange(DateTime startDate) async {
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = normalizedStart.add(const Duration(days: 7));

    final activities = await _historyDbHelper.getActivities(limit: 5000);
    final sortedActivities = List<ActivityModel>.from(activities)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final lampData = List<double>.filled(7, 0);
    final fanData = List<double>.filled(7, 0);
    final listrikData = List<double>.filled(7, 0);
    final backupData = List<double>.filled(7, 24);

    for (int index = 0; index < 7; index++) {
      final dayStart = normalizedStart.add(Duration(days: index));
      final dayEnd = dayStart.add(const Duration(days: 1));

      if (dayStart.isAfter(normalizedEnd) || dayStart.isAfter(DateTime.now())) {
        continue;
      }

      final initialStateEvent = _findLastEventBeforeOrAt(sortedActivities, dayStart);
      bool currentLamp = initialStateEvent?.lampActive ?? false;
      bool currentFan = initialStateEvent?.fanActive ?? false;

      DateTime cursor = dayStart;
      double lampSeconds = 0;
      double fanSeconds = 0;
      double listrikSeconds = 0;

      for (final event in sortedActivities) {
        if (!event.dateTime.isAfter(dayStart)) continue;
        if (!event.dateTime.isBefore(dayEnd)) break;

        final segmentEnd = event.dateTime;
        if (segmentEnd.isAfter(cursor)) {
          final seconds = segmentEnd.difference(cursor).inSeconds.toDouble();
          if (currentLamp) lampSeconds += seconds;
          if (currentFan) fanSeconds += seconds;
          if (currentLamp || currentFan) listrikSeconds += seconds;
        }

        currentLamp = event.lampActive;
        currentFan = event.fanActive;
        cursor = segmentEnd;
      }

      final finalSegmentEnd = dayEnd.isAfter(DateTime.now()) ? DateTime.now() : dayEnd;
      if (finalSegmentEnd.isAfter(cursor)) {
        final seconds = finalSegmentEnd.difference(cursor).inSeconds.toDouble();
        if (currentLamp) lampSeconds += seconds;
        if (currentFan) fanSeconds += seconds;
        if (currentLamp || currentFan) listrikSeconds += seconds;
      }

      final lampHours = _roundHour(lampSeconds / 3600);
      final fanHours = _roundHour(fanSeconds / 3600);
      final listrikHours = _roundHour(listrikSeconds / 3600);
      final backupHours = _roundHour((24 - listrikHours).clamp(0, 24).toDouble());

      lampData[index] = lampHours;
      fanData[index] = fanHours;
      listrikData[index] = listrikHours;
      backupData[index] = backupHours;
    }

    _lampAndFanData['Lampu'] = lampData;
    _lampAndFanData['Kipas'] = fanData;
    _powerAndBatteryData['Listrik'] = listrikData;
    _powerAndBatteryData['Backup Daya'] = backupData;

    notifyListeners();
  }

  ActivityModel? _findLastEventBeforeOrAt(
    List<ActivityModel> activities,
    DateTime reference,
  ) {
    ActivityModel? result;
    for (final event in activities) {
      if (event.dateTime.isAfter(reference)) break;
      result = event;
    }
    return result;
  }

  double _roundHour(double value) {
    return double.parse(value.toStringAsFixed(1));
  }
}
