import 'package:flutter/material.dart';
import '../controllers/age_range_controller.dart';
import 'history_page.dart';
import 'death_page.dart';
import 'statistics_page.dart';
import 'dashboard_page.dart';

class AgeRangePage extends StatefulWidget {
  const AgeRangePage({super.key});

  @override
  State<AgeRangePage> createState() => _AgeRangePageState();
}

class _AgeRangePageState extends State<AgeRangePage> {
  final AgeRangeController _controller = AgeRangeController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DashboardPage()),
              (route) => false,
            );
          },
        ),
        title: const Text(
          'Kontrol Umur & Rentang',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_downward,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kontrol Umur & Pengaturan Rentang',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pengelolaan Umur Ayam dan Rentang Sensor',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Content Section
            Container(
              width: double.infinity,
              color: Colors.orange,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Umur Ayam Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Umur Ayam',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Age Selector Circles
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(4, (index) {
                              final age = index + 1;
                              return _buildAgeButton(age);
                            }),
                          ),

                          const SizedBox(height: 24),

                          // Progress Bar
                          Stack(
                            children: [
                              Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: _controller.getProgress(),
                                child: Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Progress Label
                          Center(
                            child: Text(
                              'Umur ${_controller.currentAge} Minggu',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Pengaturan Rentang Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Icon
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.tune,
                                  size: 28,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pengaturan Rentang',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Atur rentang suhu dan kelembapan yang optimal berdasarkan umur ayam',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Toggle Switch
                              Switch(
                                value: _controller.autoRangeEnabled,
                                onChanged: (value) {
                                  _controller.toggleAutoRange(value);
                                },
                                activeColor: Colors.white,
                                activeTrackColor: Colors.orange,
                                inactiveThumbColor: Colors.grey.shade400,
                                inactiveTrackColor: Colors.grey.shade300,
                              ),
                            ],
                          ),

                          // Range Settings (shown when enabled)
                          if (_controller.autoRangeEnabled) ...[
                            const SizedBox(height: 24),

                            // Rentang Suhu Section
                            _buildRangeSection(
                              icon: Icons.thermostat,
                              iconColor: Colors.red,
                              title: 'Rentang Suhu',
                              minValue: _controller.minTemperature,
                              targetValue: _controller.targetTemperature,
                              maxValue: _controller.maxTemperature,
                              unit: '°C',
                              minRange: 0.0,
                              maxRange: 100.0,
                              onMinChanged: (value) {
                                _controller.setMinTemperature(value);
                              },
                              onTargetChanged: (value) {
                                _controller.setTargetTemperature(value);
                              },
                              onMaxChanged: (value) {
                                _controller.setMaxTemperature(value);
                              },
                            ),

                            const SizedBox(height: 16),

                            // Rentang Kelembapan Section
                            _buildRangeSection(
                              icon: Icons.water_drop,
                              iconColor: Colors.blue,
                              title: 'Rentang Kelembapan',
                              minValue: _controller.minHumidity,
                              targetValue: _controller.targetHumidity,
                              maxValue: _controller.maxHumidity,
                              unit: '%',
                              minRange: 0.0,
                              maxRange: 100.0,
                              onMinChanged: (value) {
                                _controller.setMinHumidity(value);
                              },
                              onTargetChanged: (value) {
                                _controller.setTargetHumidity(value);
                              },
                              onMaxChanged: (value) {
                                _controller.setMaxHumidity(value);
                              },
                            ),

                            const SizedBox(height: 16),

                            // Information Box
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Informasi Rentang\n\nRentang suhu dan kelembapan ini akan digunakan secara otomatis dalam pengelolaan suhu dan kelembapan kandang ayam. Sistem akan menyesuaikan nilainya sesuai dengan kondisi optimal untuk setiap umur.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
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
            _buildBottomNavItem(Icons.bar_chart, 'Grafik', false),
            _buildBottomNavItem(Icons.history, 'Riwayat', false),
            _buildBottomNavItem(Icons.dangerous, 'Kematian', false),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeButton(int age) {
    final isSelected = age == _controller.currentAge;
    final color = _controller.getAgeColor(age);

    return GestureDetector(
      onTap: () {
        _controller.setCurrentAge(age);
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                age.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.orange.shade900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Minggu',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (label == 'Grafik') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StatisticsPage()),
          );
        } else if (label == 'Riwayat') {
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

  Widget _buildRangeSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required double minValue,
    required double targetValue,
    required double maxValue,
    required String unit,
    required double minRange,
    required double maxRange,
    required Function(double) onMinChanged,
    required Function(double) onTargetChanged,
    required Function(double) onMaxChanged,
  }) {
    final TextEditingController minController = TextEditingController(
      text: minValue.toStringAsFixed(1),
    );
    final TextEditingController targetController = TextEditingController(
      text: targetValue.toStringAsFixed(1),
    );
    final TextEditingController maxController = TextEditingController(
      text: maxValue.toStringAsFixed(1),
    );

    // Determine label prefix based on title
    String labelPrefix = title.contains('Suhu') ? 'Suhu' : 'Kelembapan';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Minimum Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$labelPrefix Minimum',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Minus button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.remove, size: 20),
                      color: Colors.grey.shade700,
                      onPressed: () {
                        if (minValue > minRange) {
                          onMinChanged(minValue - 1);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Value input field
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: TextField(
                          controller: minController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            suffixText: unit,
                            suffixStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          onSubmitted: (value) {
                            final newValue = double.tryParse(value);
                            if (newValue != null &&
                                newValue >= minRange &&
                                newValue <= maxRange) {
                              onMinChanged(newValue);
                            } else {
                              minController.text = minValue.toStringAsFixed(1);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Plus button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add, size: 20),
                      color: Colors.grey.shade700,
                      onPressed: () {
                        if (minValue < maxRange) {
                          onMinChanged(minValue + 1);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Slider
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: iconColor,
                  inactiveTrackColor: iconColor.withOpacity(0.2),
                  thumbColor: iconColor,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayColor: iconColor.withOpacity(0.2),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                ),
                child: Slider(
                  value: minValue,
                  min: minRange,
                  max: maxRange,
                  onChanged: onMinChanged,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Target Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$labelPrefix Target',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Minus button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.remove, size: 20),
                      color: Colors.grey.shade700,
                      onPressed: () {
                        if (targetValue > minRange) {
                          onTargetChanged(targetValue - 1);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Value input field
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: TextField(
                          controller: targetController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            suffixText: unit,
                            suffixStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          onSubmitted: (value) {
                            final newValue = double.tryParse(value);
                            if (newValue != null &&
                                newValue >= minRange &&
                                newValue <= maxRange) {
                              onTargetChanged(newValue);
                            } else {
                              targetController.text = targetValue
                                  .toStringAsFixed(1);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Plus button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add, size: 20),
                      color: Colors.grey.shade700,
                      onPressed: () {
                        if (targetValue < maxRange) {
                          onTargetChanged(targetValue + 1);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Slider
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: iconColor,
                  inactiveTrackColor: iconColor.withOpacity(0.2),
                  thumbColor: iconColor,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayColor: iconColor.withOpacity(0.2),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                ),
                child: Slider(
                  value: targetValue,
                  min: minRange,
                  max: maxRange,
                  onChanged: onTargetChanged,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Maximum Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$labelPrefix Maksimum',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Minus button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.remove, size: 20),
                      color: Colors.grey.shade700,
                      onPressed: () {
                        if (maxValue > minRange) {
                          onMaxChanged(maxValue - 1);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Value input field
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: TextField(
                          controller: maxController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            suffixText: unit,
                            suffixStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          onSubmitted: (value) {
                            final newValue = double.tryParse(value);
                            if (newValue != null &&
                                newValue >= minRange &&
                                newValue <= maxRange) {
                              onMaxChanged(newValue);
                            } else {
                              maxController.text = maxValue.toStringAsFixed(1);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Plus button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add, size: 20),
                      color: Colors.grey.shade700,
                      onPressed: () {
                        if (maxValue < maxRange) {
                          onMaxChanged(maxValue + 1);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Slider
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: iconColor,
                  inactiveTrackColor: iconColor.withOpacity(0.2),
                  thumbColor: iconColor,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayColor: iconColor.withOpacity(0.2),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                ),
                child: Slider(
                  value: maxValue,
                  min: minRange,
                  max: maxRange,
                  onChanged: onMaxChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
