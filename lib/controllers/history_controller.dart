import 'package:flutter/material.dart';
import '../models/activity_model.dart';

class HistoryController extends ChangeNotifier {
  List<ActivityModel> _activities = [];
  int _itemsPerPage = 10;
  String _filterDate = 'all';
  String _filterAge = 'all';
  String _filterType =
      'all'; // 'all', 'normal', 'warning', 'emergency', 'error'

  List<ActivityModel> get activities => _activities;
  int get itemsPerPage => _itemsPerPage;
  String get filterDate => _filterDate;
  String get filterAge => _filterAge;
  String get filterType => _filterType;
  int get totalPages => (_activities.length / _itemsPerPage).ceil();

  HistoryController() {
    _initializeActivities();
  }

  void _initializeActivities() {
    _activities = [
      ActivityModel(
        id: '1',
        type: 'normal',
        title: 'Normal Operation',
        description: '',
        dateTime: DateTime(2025, 6, 27, 1, 21),
        chickenAge: 1,
        lampActive: true,
        fanActive: false,
        iconType: 'settings',
      ),
      ActivityModel(
        id: '2',
        type: 'warning',
        title: 'Suhu: Optimal - Kipas OFF',
        description: 'Suhu: Optimal - Kipas OFF',
        dateTime: DateTime(2025, 6, 27, 1, 21),
        chickenAge: 1,
        lampActive: true,
        fanActive: false,
        iconType: 'settings',
      ),
      ActivityModel(
        id: '3',
        type: 'emergency',
        title: 'Kelembapan: Suhu Darurat - Lampu ON untuk Pemanasan',
        description: 'Kelembapan: Suhu Darurat - Lampu ON untuk Pemanasan',
        dateTime: DateTime(2025, 6, 27, 1, 21),
        chickenAge: 1,
        lampActive: true,
        fanActive: false,
        iconType: 'settings',
      ),
      ActivityModel(
        id: '4',
        type: 'error',
        title: 'WiFi: 174816335! : WiFi Disconnected. Attempting to Reconnect',
        description:
            'WiFi: 174816335! : WiFi Disconnected. Attempting to Reconnect',
        dateTime: DateTime(2025, 6, 27, 1, 21),
        chickenAge: 1,
        lampActive: false,
        fanActive: false,
        iconType: 'monitor',
      ),
      ActivityModel(
        id: '5',
        type: 'error',
        title: 'Kelembapan: Suhu Darurat - Lampu ON untuk',
        description: 'Kelembapan: Suhu Darurat - Lampu ON untuk',
        dateTime: DateTime(2025, 6, 27, 1, 21),
        chickenAge: 1,
        lampActive: false,
        fanActive: false,
        iconType: 'monitor',
      ),
    ];
    notifyListeners();
  }

  // Get activities for specific page
  List<ActivityModel> getActivitiesForPage(int page) {
    final startIndex = (page - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _activities.length) {
      return [];
    }

    return _activities.sublist(
      startIndex,
      endIndex > _activities.length ? _activities.length : endIndex,
    );
  }

  // Set items per page
  void setItemsPerPage(int count) {
    _itemsPerPage = count;
    notifyListeners();
  }

  // Filter by date
  void setDateFilter(String filter) {
    _filterDate = filter;
    notifyListeners();
  }

  // Filter by age
  void setAgeFilter(String age) {
    _filterAge = age;
    notifyListeners();
  }

  // Filter by type
  void setTypeFilter(String type) {
    _filterType = type;
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
    notifyListeners();
  }

  // Delete specific activity
  void deleteActivity(String id) {
    _activities.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  // Export activities (placeholder)
  void exportActivities() {
    // Implement export logic here
    notifyListeners();
  }

  // Refresh data
  void refreshData() {
    _initializeActivities();
    notifyListeners();
  }
}
