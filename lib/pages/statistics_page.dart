import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/rendering.dart';
import '../controllers/statistics_controller.dart';
import 'history_page.dart';
import 'death_page.dart';
import 'dashboard_page.dart';
import 'dart:ui' as ui;

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final StatisticsController _controller = StatisticsController();
  DateTimeRange? _selectedDateRange;
  String _periodText = 'Periode: 21 - 27 Mei 2024';

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

  List<String> _getDateLabels() {
    if (_selectedDateRange == null) {
      // Default: tanggal hari ini mundur 6 hari
      final now = DateTime.now();
      return List.generate(7, (index) {
        final date = now.subtract(Duration(days: 6 - index));
        return DateFormat('dd/MM').format(date);
      });
    }

    return List.generate(7, (index) {
      final date = _selectedDateRange!.start.add(Duration(days: index));
      return DateFormat('dd/MM').format(date);
    });
  }

  Future<void> _showDateRangePicker() async {
    DateTime? startDate = _selectedDateRange?.start;
    DateTime? endDate = _selectedDateRange?.end;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select range',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Date Range',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.calendar_today, color: Colors.grey[700]),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Colors.orange,
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  startDate = picked;
                                  // Otomatis set end date 6 hari setelah start date (total 7 hari)
                                  endDate = picked.add(const Duration(days: 6));
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.orange,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                startDate != null
                                    ? DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(startDate!)
                                    : 'dd/mm/yyyy',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: startDate != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 1),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade100,
                            ),
                            child: Text(
                              endDate != null
                                  ? DateFormat('dd/MM/yyyy').format(endDate!)
                                  : 'dd/mm/yyyy',
                              style: TextStyle(
                                fontSize: 16,
                                color: endDate != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Start Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'End Date (Otomatis +7 hari)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: startDate != null && endDate != null
                              ? () {
                                  this.setState(() {
                                    _selectedDateRange = DateTimeRange(
                                      start: startDate!,
                                      end: endDate!,
                                    );
                                    _periodText =
                                        'Periode: ${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}';
                                  });
                                  Navigator.of(context).pop();
                                }
                              : null,
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Statistik Penggunaan Perangkat',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Summary Cards and Period Filter - White Section with rounded bottom
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Operasi\nPerangkat',
                        '168 Jam',
                        Icons.access_time,
                        Colors.blue.shade400,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Penggunaan\nListrik',
                        '112 Jam',
                        Icons.flash_on,
                        Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Penggunaan\nAki',
                        '56 Jam',
                        Icons.battery_charging_full,
                        Colors.green.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Period info
                GestureDetector(
                  onTap: _showDateRangePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _periodText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Charts Container - Orange background section
          Expanded(
            child: Container(
              color: Colors.orange,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChartCard(
                        'Grafik Operasi Lampu dan Kipas',
                        'Durasi operasi harian (jam)',
                        _controller.lampAndFanData,
                        ['Lampu', 'Kipas'],
                        [Colors.orange.shade300, Colors.blue.shade400],
                        Icons.lightbulb_outline,
                      ),

                      const SizedBox(height: 24),

                      // Chart 2: Durasi Penggunaan Listrik dan Aki
                      _buildChartCard(
                        'Durasi Penggunaan Listrik dan Aki',
                        'Sumber daya harian (jam)',
                        _controller.powerAndBatteryData,
                        ['Listrik', 'Aki'],
                        [Colors.orange.shade300, Colors.green.shade400],
                        Icons.power,
                      ),

                      const SizedBox(height: 100),
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
            _buildBottomNavItem(Icons.bar_chart, 'Grafik', true, null),
            _buildBottomNavItem(Icons.history, 'Riwayat', false, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            }),
            _buildBottomNavItem(Icons.dangerous, 'Kematian', false, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DeathPage()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(
    String title,
    String subtitle,
    Map<String, List<double>> data,
    List<String> labels,
    List<Color> colors,
    IconData icon,
  ) {
    final dateLabels = _getDateLabels();
    final maxValue = 24.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: Colors.orange.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                height: 220,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Y-axis labels
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '24',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '18',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '12',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '6',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '0',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Chart scatter plot
                    Expanded(
                      child: CustomPaint(
                        painter: ScatterPlotPainter(
                          dateLabels: dateLabels,
                          data1: data[labels[0]]!,
                          data2: data[labels[1]]!,
                          color1: colors[0],
                          color2: colors[1],
                          maxValue: maxValue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Legend with better design
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(labels[0], colors[0]),
                  const SizedBox(width: 32),
                  _buildLegendItem(labels[1], colors[1]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback? onTap,
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

class ScatterPlotPainter extends CustomPainter {
  final List<String> dateLabels;
  final List<double> data1;
  final List<double> data2;
  final Color color1;
  final Color color2;
  final double maxValue;

  ScatterPlotPainter({
    required this.dateLabels,
    required this.data1,
    required this.data2,
    required this.color1,
    required this.color2,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 40; // Reserve space for labels
    final pointRadius = 6.0;
    final spacing = size.width / (dateLabels.length - 1);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = (chartHeight / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw connecting lines for data1
    final linePaint1 = Paint()
      ..color = color1.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path1 = Path();
    for (int i = 0; i < data1.length; i++) {
      final x = i * spacing;
      final y = chartHeight - (data1[i] / maxValue * chartHeight);
      if (i == 0) {
        path1.moveTo(x, y);
      } else {
        path1.lineTo(x, y);
      }
    }
    canvas.drawPath(path1, linePaint1);

    // Draw connecting lines for data2
    final linePaint2 = Paint()
      ..color = color2.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path2 = Path();
    for (int i = 0; i < data2.length; i++) {
      final x = i * spacing;
      final y = chartHeight - (data2[i] / maxValue * chartHeight);
      if (i == 0) {
        path2.moveTo(x, y);
      } else {
        path2.lineTo(x, y);
      }
    }
    canvas.drawPath(path2, linePaint2);

    // Draw points for data1
    for (int i = 0; i < data1.length; i++) {
      final x = i * spacing;
      final y = chartHeight - (data1[i] / maxValue * chartHeight);

      // Shadow
      canvas.drawCircle(
        Offset(x, y),
        pointRadius + 2,
        Paint()..color = color1.withOpacity(0.2),
      );

      // Point
      canvas.drawCircle(Offset(x, y), pointRadius, Paint()..color = color1);

      // White center
      canvas.drawCircle(
        Offset(x, y),
        pointRadius - 2,
        Paint()..color = Colors.white,
      );
    }

    // Draw points for data2
    for (int i = 0; i < data2.length; i++) {
      final x = i * spacing;
      final y = chartHeight - (data2[i] / maxValue * chartHeight);

      // Shadow
      canvas.drawCircle(
        Offset(x, y),
        pointRadius + 2,
        Paint()..color = color2.withOpacity(0.2),
      );

      // Point
      canvas.drawCircle(Offset(x, y), pointRadius, Paint()..color = color2);

      // White center
      canvas.drawCircle(
        Offset(x, y),
        pointRadius - 2,
        Paint()..color = Colors.white,
      );
    }

    // Draw date labels
    final textStyle = TextStyle(
      color: Colors.grey.shade700,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    for (int i = 0; i < dateLabels.length; i++) {
      final x = i * spacing;
      final textSpan = TextSpan(text: dateLabels[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartHeight + 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
