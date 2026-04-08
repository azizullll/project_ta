import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/dashboard_controller.dart';
import '../models/death_model.dart';
import '../services/death_db_helper.dart';
import 'dashboard_page.dart';
import 'control_page.dart';
import 'settings_page.dart';
import 'notification_page.dart';
import 'age_range_page.dart';
import 'history_page.dart';
import 'death_page.dart';
import 'statistics_page.dart';
import 'real_time_monitor_page.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  final DashboardController _dashboardController = DashboardController();
  final DeathDatabaseHelper _deathDbHelper = DeathDatabaseHelper();

  List<DeathModel> _deathPreviewRecords = [];
  int _totalDeathCount = 0;
  int _selectedIndex = 2; // Data tab selected

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _dashboardController.addListener(_onControllerChanged);
    _loadDeathPreview();
  }

  @override
  void dispose() {
    _dashboardController.removeListener(_onControllerChanged);
    super.dispose();
  }

  Future<void> _loadDeathPreview() async {
    final allRecords = await _deathDbHelper.getRecords();
    if (!mounted) {
      return;
    }

    setState(() {
      _totalDeathCount = allRecords.fold(0, (sum, item) => sum + item.count);
      _deathPreviewRecords = allRecords.take(5).toList();
    });
  }

  String _statusFromValue(String sensor, double value) {
    if (sensor == 'Suhu') {
      if (value > 30 || value < 20) {
        return 'Perhatian';
      }
      return 'Normal';
    }

    if (value > 60 || value < 40) {
      return 'Perhatian';
    }
    return 'Normal';
  }

  String _sensorStatus({
    required String sensor,
    required double value,
    required String dashboardStatus,
  }) {
    if (dashboardStatus.trim().isNotEmpty) {
      return dashboardStatus;
    }
    return _statusFromValue(sensor, value);
  }

  String _formattedLastUpdate() {
    final raw = _dashboardController.lastUpdateTime.trim();
    if (raw.isEmpty) {
      return '-';
    }

    try {
      final parsed = DateTime.parse(raw);
      return DateFormat('HH:mm:ss').format(parsed);
    } catch (_) {
      return raw;
    }
  }

  Future<void> _handleRefresh() async {
    // Simulate refresh delay
    await Future.delayed(const Duration(seconds: 1));
    // Refresh page data sources
    await _dashboardController.refreshData();
    await _loadDeathPreview();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data berhasil diperbarui'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleSwipe(DragEndDetails details) {
    if (details.primaryVelocity! > 0) {
      // Swipe right -> go back to Kontrol (previous page)
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ControlPage(),
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: _handleSwipe,
      child: Scaffold(
        backgroundColor: Colors.orange,
        appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/logo.png',
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.egg, color: Colors.orange);
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.monitor, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RealTimeMonitorPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.access_time, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AgeRangePage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar with white background and rounded bottom
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTab('Dashboard', 0),
                    _buildTab('Kontrol', 1),
                    _buildTab('Data', 2),
                  ],
                ),
              ],
            ),
          ),

          // Content with orange background
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: Colors.orange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Last Updated Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Terakhir diperbarui: ${_formattedLastUpdate()}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Grafik Sensor Title
                    const Text(
                      'Grafik Sensor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Tarik ke bawah untuk menyegarkan data',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),

                    const SizedBox(height: 16),

                    // Temperature and Humidity Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Suhu',
                            '${_dashboardController.data.temperature.toStringAsFixed(0)}°C',
                            Icons.thermostat_outlined,
                            Colors.red,
                            (_dashboardController.data.temperature / 50).clamp(0.0, 1.0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            'Kelembapan',
                            '${_dashboardController.data.humidity.toStringAsFixed(0)}%',
                            Icons.water_drop_outlined,
                            Colors.blue,
                            (_dashboardController.data.humidity / 100).clamp(0.0, 1.0),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Data Sensor Table
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data Sensor',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDataTable(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Angka Kematian Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Angka Kematian',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const DeathPage(),
                                    ),
                                  );
                                  await _loadDeathPreview();
                                },
                                child: const Text(
                                  'Lihat Semua',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _deathPreviewRecords.isNotEmpty
                                ? 'Total kematian: $_totalDeathCount'
                                : 'Tidak ada data angka kematian',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_deathPreviewRecords.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ..._deathPreviewRecords.map((record) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Jumlah: ${record.count}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${record.chickenAge} mg',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat(
                                        'dd/MM HH:mm',
                                      ).format(record.dateTime),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItemWithNav(Icons.bar_chart, 'Grafik', false, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatisticsPage()),
              );
            }),
            _buildBottomNavItem(Icons.history, 'Riwayat', false),
            _buildBottomNavItem(Icons.dangerous, 'Kematian', false),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const DashboardPage(),
              transitionDuration: Duration.zero,
            ),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const ControlPage(),
              transitionDuration: Duration.zero,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.orange : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.orange : Colors.grey,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, size: 20, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(2),
        },
        children: [
          // Header
          TableRow(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            children: [
              _buildTableHeader('Sensor'),
              _buildTableHeader('Nilai'),
              _buildTableHeader('Status'),
              _buildTableHeader('Waktu'),
            ],
          ),
          // Data rows
          TableRow(
            children: [
              _buildTableCell('Suhu'),
              _buildTableCell(
                '${_dashboardController.data.temperature.toStringAsFixed(1)}°C',
              ),
              _buildTableCell(
                _sensorStatus(
                  sensor: 'Suhu',
                  value: _dashboardController.data.temperature,
                  dashboardStatus: _dashboardController.temperatureStatus,
                ),
              ),
              _buildTableCell(_formattedLastUpdate()),
            ],
          ),
          TableRow(
            children: [
              _buildTableCell('Kelembapan'),
              _buildTableCell(
                '${_dashboardController.data.humidity.toStringAsFixed(1)}%',
              ),
              _buildTableCell(
                _sensorStatus(
                  sensor: 'Kelembapan',
                  value: _dashboardController.data.humidity,
                  dashboardStatus: _dashboardController.humidityStatus,
                ),
              ),
              _buildTableCell(_formattedLastUpdate()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (label == 'Riwayat') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HistoryPage()),
          );
        } else if (label == 'Kematian') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DeathPage()),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: isActive ? Colors.orange : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? Colors.orange : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItemWithNav(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: isActive ? Colors.orange : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? Colors.orange : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
