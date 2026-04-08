import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../controllers/dashboard_controller.dart';
import 'dart:async';

class DataLogPage extends StatefulWidget {
  const DataLogPage({super.key});

  @override
  State<DataLogPage> createState() => _DataLogPageState();
}

class _DataLogPageState extends State<DataLogPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final DashboardController _controller = DashboardController();
  StreamSubscription? _logsSubscription;
  Map<String, dynamic> _systemLogs = {};
  List<Map<String, dynamic>> _sensorHistory = [];
  
  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    // Listen to system logs
    _logsSubscription = _firebaseService.getLogsStream().listen((logs) {
      if (mounted) {
        setState(() {
          _systemLogs = logs;
        });
      }
    });

    // Listen to sensor data for history
    _firebaseService.getSensorDataStream().listen((sensorData) {
      if (mounted && sensorData.isNotEmpty) {
        setState(() {
          _sensorHistory.insert(0, {
            'timestamp': sensorData['timestamp'] ?? DateTime.now().toString(),
            'temperature': sensorData['temperature'] ?? 0.0,
            'humidity': sensorData['Humidity'] ?? 0.0,
          });
          // Keep only last 50 records
          if (_sensorHistory.length > 50) {
            _sensorHistory = _sensorHistory.sublist(0, 50);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _logsSubscription?.cancel();
    super.dispose();
  }

  Widget _buildLogCard(String title, String? log, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            width: double.infinity,
            child: Text(
              log ?? 'Belum ada log tersedia',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorHistoryCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              const Icon(Icons.history, color: Colors.purple, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Riwayat Sensor (50 Data Terakhir)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_sensorHistory.isNotEmpty)
            Container(
              height: 300,
              child: ListView.builder(
                itemCount: _sensorHistory.length,
                itemBuilder: (context, index) {
                  final record = _sensorHistory[index];
                  final timestamp = record['timestamp'] as String? ?? '';
                  final temp = record['temperature'] as num? ?? 0.0;
                  final humidity = record['humidity'] as num? ?? 0.0;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            timestamp.isNotEmpty 
                                ? timestamp.split(' ').last.substring(0, 8)
                                : 'N/A',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${temp.toStringAsFixed(1)}°C',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${humidity.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              child: const Center(
                child: Text(
                  'Belum ada data sensor tersedia',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
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
          'Data & Log System',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
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
              // System Logs
              _buildLogCard(
                'System Log',
                _systemLogs['system'] as String?,
                Icons.memory,
                Colors.blue,
              ),
              
              // WiFi Logs
              _buildLogCard(
                'WiFi Connection Log',
                _systemLogs['wifi'] as String?,
                Icons.wifi,
                Colors.green,
              ),
              
              // Sensor Logs
              _buildLogCard(
                'Sensor Log',
                _systemLogs['sensor'] as String?,
                Icons.sensors,
                Colors.orange,
              ),
              
              // LCD Logs
              _buildLogCard(
                'LCD Display Log',
                _systemLogs['lcd'] as String?,
                Icons.monitor,
                Colors.purple,
              ),

              // Sensor History
              _buildSensorHistoryCard(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}