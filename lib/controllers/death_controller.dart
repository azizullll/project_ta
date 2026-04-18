import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/death_model.dart';
import '../services/death_db_helper.dart';

class DeathController extends ChangeNotifier {
  List<DeathModel> _deathRecords = [];
  int _itemsPerPage = 10;
  String _filterDate = 'all';
  final DeathDatabaseHelper _dbHelper = DeathDatabaseHelper();

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

  Future<void> _initializeData() async {
    await refreshData();
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
  Future<void> addDeathRecord(DeathModel record) async {
    await _dbHelper.insertRecord(record);
    _deathRecords.insert(0, record);
    notifyListeners();
  }

  // Delete specific death record
  Future<void> deleteDeathRecord(String id) async {
    await _dbHelper.deleteRecord(id);
    _deathRecords.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // Clear all death records
  Future<void> clearAllRecords() async {
    await _dbHelper.clearAllRecords();
    _deathRecords.clear();
    notifyListeners();
  }

  Future<Directory> _resolveExportDirectory() async {
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        return downloadDir;
      }

      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        return externalDir;
      }
    }

    return getApplicationDocumentsDirectory();
  }

  Future<String> exportRecordsToPdf(List<DeathModel> records) async {
    final pdf = pw.Document();

    final rows = records
        .map(
          (record) => [
            DateFormat('dd/MM/yyyy').format(record.dateTime),
            DateFormat('HH:mm').format(record.dateTime),
            record.count.toString(),
            record.chickenAge.toString(),
            record.cause,
            record.notes.isEmpty ? '-' : record.notes,
          ],
        )
        .toList();

    final totalDeaths = records.fold<int>(
      0,
      (sum, record) => sum + record.count,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'Laporan Data Kematian Ayam',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Tanggal export: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          ),
          pw.Text('Jumlah record: ${records.length}'),
          pw.Text('Total kematian: $totalDeaths ekor'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Tanggal',
              'Waktu',
              'Jumlah',
              'Umur (Minggu)',
              'Penyebab',
              'Catatan',
            ],
            data: rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    final output = await pdf.save();
    final directory = await _resolveExportDirectory();
    final fileName =
        'data_kematian_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final filePath = p.join(directory.path, fileName);

    final file = File(filePath);
    await file.writeAsBytes(output, flush: true);

    return filePath;
  }

  // Refresh data
  Future<void> refreshData() async {
    _deathRecords = await _dbHelper.getRecords();
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
