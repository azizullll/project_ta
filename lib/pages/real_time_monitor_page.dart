import 'package:flutter/material.dart';
import '../controllers/dashboard_controller.dart';
import '../services/firebase_service.dart';
import 'dart:async';

class RealTimeMonitorPage extends StatefulWidget {
  const RealTimeMonitorPage({super.key});

  @override
  State<RealTimeMonitorPage> createState() => _RealTimeMonitorPageState();
}

class _RealTimeMonitorPageState extends State<RealTimeMonitorPage> {
  final DashboardController _controller = DashboardController();
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription? _allDataSubscription;
  Map<String, dynamic> _allData = {};
  Map<String, dynamic> _fuzzyData = {};
  Map<String, dynamic> _logsData = {};

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
    _startListening();
  }

  void _startListening() {
    // Listen to all Firebase data
    _allDataSubscription = _firebaseService.getAllDataStream().listen((data) {
      if (mounted) {
        setState(() {
          _allData = data;
        });
      }
    });

    // Listen to fuzzy logic data
    _firebaseService.getFuzzyDataStream().listen((data) {
      if (mounted) {
        setState(() {
          _fuzzyData = data;
        });
      }
    });

    // Listen to logs
    _firebaseService.getLogsStream().listen((data) {
      if (mounted) {
        setState(() {
          _logsData = data;
        });
      }
    });
  }

  @override
  void dispose() {
    _allDataSubscription?.cancel();
    super.dispose();
  }

  Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  Widget _buildDataCard(
    String title,
    Map<String, dynamic>? data,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (data != null && data.isNotEmpty)
            ...data.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const Text(': '),
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.value.toString(),
                        style: const TextStyle(color: Colors.black54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Text(
              'Tidak ada data',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertCard() {
    bool hasEmergency =
        _controller.highTemperatureAlert ||
        _controller.lowTemperatureAlert ||
        _controller.highHumidityAlert ||
        _controller.lowHumidityAlert;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasEmergency ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasEmergency ? Colors.red : Colors.green,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasEmergency ? Icons.warning : Icons.check_circle,
                color: hasEmergency ? Colors.red : Colors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Status Darurat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: hasEmergency ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasEmergency) ...[
            if (_controller.highTemperatureAlert)
              _buildAlertRow('Suhu Tinggi', Colors.red),
            if (_controller.lowTemperatureAlert)
              _buildAlertRow('Suhu Rendah', Colors.orange),
            if (_controller.highHumidityAlert)
              _buildAlertRow('Kelembapan Tinggi', Colors.red),
            if (_controller.lowHumidityAlert)
              _buildAlertRow('Kelembapan Rendah', Colors.orange),
          ] else
            const Text(
              'Semua kondisi normal',
              style: TextStyle(color: Colors.green, fontSize: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertRow(String alert, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 12),
          const SizedBox(width: 8),
          Text(
            alert,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Real-Time Monitor',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _controller.isConnected ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _controller.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _controller.isConnected ? 'Online' : 'Offline',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        margin: const EdgeInsets.only(top: 8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _controller.isConnected
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _controller.isConnected ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _controller.isConnected
                          ? Icons.cloud_done
                          : Icons.cloud_off,
                      color: _controller.isConnected
                          ? Colors.green
                          : Colors.red,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _controller.isConnected
                                ? 'Terhubung ke ESP32'
                                : 'Tidak Terhubung',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _controller.isConnected
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          if (_controller.lastUpdateTime.isNotEmpty)
                            Text(
                              'Update terakhir: ${_controller.lastUpdateTime}',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Emergency Alerts
              _buildAlertCard(),

              // Sensor Data
              _buildDataCard(
                'Data Sensor',
                _asStringMap(_allData['sensor']),
                Icons.sensors,
              ),

              // Relay Status
              _buildDataCard(
                'Status Relay',
                _asStringMap(_allData['relay']),
                Icons.electrical_services,
              ),

              // Control Status
              _buildDataCard(
                'Status Kontrol',
                _asStringMap(_allData['control']),
                Icons.settings_remote,
              ),

              // Device Status
              if (_controller.temperatureStatus.isNotEmpty ||
                  _controller.humidityStatus.isNotEmpty)
                _buildDataCard('Status Perangkat', {
                  'Suhu': _controller.temperatureStatus,
                  'Kelembapan': _controller.humidityStatus,
                }, Icons.info),

              // Fuzzy Logic Data (optional, for debugging)
              if (_fuzzyData.isNotEmpty)
                _buildDataCard(
                  'Data Fuzzy Logic',
                  _fuzzyData,
                  Icons.psychology,
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
