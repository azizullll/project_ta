import 'package:flutter/material.dart';
import '../models/death_model.dart';

class DeathController extends ChangeNotifier {
  List<DeathModel> _deathRecords = [];
  int _itemsPerPage = 10;
  String _filterDate = 'all';

  List<DeathModel> get deathRecords => _deathRecords;
  int get itemsPerPage => _itemsPerPage;
  String get filterDate => _filterDate;
  int get totalPages =>
      _deathRecords.isEmpty ? 0 : (_deathRecords.length / _itemsPerPage).ceil();
  int get totalDeaths =>
      _deathRecords.fold(0, (sum, record) => sum + record.count);
  int get totalRecords => _deathRecords.length;
  bool get hasData => _deathRecords.isNotEmpty;

  DeathController() {
    _initializeData();
  }

  void _initializeData() {
    // Initialize with empty data by default
    _deathRecords = [];
    notifyListeners();
  }

  // Get death records for specific page
  List<DeathModel> getRecordsForPage(int page) {
    if (_deathRecords.isEmpty) {
      return [];
    }

    final startIndex = (page - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _deathRecords.length) {
      return [];
    }

    return _deathRecords.sublist(
      startIndex,
      endIndex > _deathRecords.length ? _deathRecords.length : endIndex,
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

  // Add new death record
  void addDeathRecord(DeathModel record) {
    _deathRecords.insert(0, record);
    notifyListeners();
  }

  // Delete specific death record
  void deleteDeathRecord(String id) {
    _deathRecords.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // Clear all death records
  void clearAllRecords() {
    _deathRecords.clear();
    notifyListeners();
  }

  // Export death records (placeholder)
  void exportRecords() {
    // Implement export logic here
    notifyListeners();
  }

  // Refresh data
  void refreshData() {
    _initializeData();
    notifyListeners();
  }

  // Add sample data for testing
  void addSampleData() {
    _deathRecords = [
      DeathModel(
        id: '1',
        dateTime: DateTime(2025, 6, 27, 10, 30),
        count: 2,
        cause: 'Suhu terlalu rendah',
        chickenAge: 1,
        notes: 'Kondisi darurat terdeteksi',
      ),
      DeathModel(
        id: '2',
        dateTime: DateTime(2025, 6, 26, 15, 20),
        count: 1,
        cause: 'Kelembapan tidak stabil',
        chickenAge: 1,
        notes: '',
      ),
    ];
    notifyListeners();
  }
}
