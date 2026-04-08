import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../controllers/history_controller.dart';
import '../models/activity_model.dart';
import 'death_page.dart';
import 'statistics_page.dart';
import 'dashboard_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryController _controller = HistoryController();
  int _currentPage = 1;
  DateTime? _selectedDate;
  String _dateFilterText = 'Semua Tanggal';
  int? _selectedAge;
  String _ageFilterText = 'Umur Saat Ini';
  String? _selectedType;
  String _typeFilterText = 'Semua';
  bool _isLoading = true;

  void _handleControllerChange() {
    if (!mounted) return;

    final maxPage = _controller.totalPagesForFilters(
      selectedDate: _selectedDate,
      selectedAge: _selectedAge,
      selectedType: _selectedType,
    );

    setState(() {
      if (_isLoading) {
        _isLoading = false;
      }

      if (_currentPage > maxPage) {
        _currentPage = maxPage;
      }

      if (_selectedAge == null) {
        _ageFilterText = 'Umur Saat Ini (${_controller.currentChickenAge} minggu)';
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _ageFilterText = 'Umur Saat Ini (${_controller.currentChickenAge} minggu)';
    _controller.addListener(_handleControllerChange);

    // Fallback to prevent indefinite skeleton when stream callback is delayed.
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || !_isLoading) return;
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
        _selectedDate = picked;
        _dateFilterText = DateFormat('dd/MM/yyyy').format(picked);
        _currentPage = 1;
      });
    }
  }

  void _showAgeFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Umur Ayam'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Semua Umur'),
                onTap: () {
                  setState(() {
                    _selectedAge = null;
                    _ageFilterText =
                        'Umur Saat Ini (${_controller.currentChickenAge} minggu)';
                    _currentPage = 1;
                  });
                  Navigator.pop(context);
                },
              ),
              ...List.generate(4, (index) {
                final age = index + 1;
                return ListTile(
                  title: Text('Minggu $age'),
                  onTap: () {
                    setState(() {
                      _selectedAge = age;
                      _ageFilterText = 'Umur: $age Minggu';
                      _currentPage = 1;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showTypeFilterDialog() {
    final types = [
      {'label': 'Semua', 'value': null, 'icon': Icons.list},
      {'label': 'Relay', 'value': 'relay', 'icon': Icons.flash_on},
      {'label': 'Kontrol', 'value': 'control', 'icon': Icons.settings},
      {'label': 'Status', 'value': 'status', 'icon': Icons.info_outline},
      {'label': 'Sensor', 'value': 'sensor', 'icon': Icons.sensors},
      {'label': 'Sistem', 'value': 'system', 'icon': Icons.computer},
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Tipe Aktivitas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: types.map((type) {
              return ListTile(
                leading: Icon(type['icon'] as IconData, color: Colors.orange),
                title: Text(type['label'] as String),
                onTap: () {
                  setState(() {
                    _selectedType = type['value'] as String?;
                    _typeFilterText = type['label'] as String;
                    _currentPage = 1;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
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

  Future<void> _exportHistoryToPdf() async {
    final dataToExport = _controller.getFilteredActivities(
      selectedDate: _selectedDate,
      selectedAge: _selectedAge,
      selectedType: _selectedType,
    );

    if (dataToExport.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data riwayat untuk diunduh'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final pdf = pw.Document();
      final rows = dataToExport
          .map(
            (activity) => [
              DateFormat('dd/MM/yyyy').format(activity.dateTime),
              DateFormat('HH:mm').format(activity.dateTime),
              activity.type,
              activity.source,
              activity.title,
              activity.description,
              activity.chickenAge.toString(),
              activity.lampActive ? 'Aktif' : 'Nonaktif',
              activity.fanActive ? 'Aktif' : 'Nonaktif',
            ],
          )
          .toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Text(
              'Laporan Riwayat Aktivitas',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Tanggal export: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Tanggal',
                'Waktu',
                'Tipe',
                'Sumber',
                'Judul',
                'Deskripsi',
                'Umur',
                'Lampu',
                'Kipas',
              ],
              data: rows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      );

      final output = await pdf.save();

      final directory = await _resolveExportDirectory();
      final fileName =
          'riwayat_aktivitas_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = p.join(directory.path, fileName);

      final file = File(filePath);
      await file.writeAsBytes(output, flush: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF tersimpan: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export PDF riwayat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _controller.totalPagesForFilters(
      selectedDate: _selectedDate,
      selectedAge: _selectedAge,
      selectedType: _selectedType,
    );
    final activities = _controller.getActivitiesForPage(
      page: _currentPage,
      selectedDate: _selectedDate,
      selectedAge: _selectedAge,
      selectedType: _selectedType,
    );

    final titleAge = _selectedAge ?? _controller.currentChickenAge;

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
        title: Text(
          'Riwayat Aktivitas (Umur: $titleAge Minggu)',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Section
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
                // Date Filter
                GestureDetector(
                  onTap: _showDatePicker,
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
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _dateFilterText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (_selectedDate != null)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDate = null;
                                _dateFilterText = 'Semua Tanggal';
                                _currentPage = 1;
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          )
                        else
                          TextButton(
                            onPressed: _showDatePicker,
                            child: const Text(
                              'Pilih',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Age Filter and Download
                Row(
                  children: [
                    Expanded(
                      child: _isLoading
                          ? _buildShimmerHeaderFilter()
                          : GestureDetector(
                              onTap: _showAgeFilterDialog,
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
                                    Expanded(
                                      child: Text(
                                        _ageFilterText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.tune,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _exportHistoryToPdf,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.download,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Type Filter
                GestureDetector(
                  onTap: _showTypeFilterDialog,
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
                        const Icon(Icons.list, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _typeFilterText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.filter_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Expanded(
            child: Container(
              color: Colors.orange,
              child: Column(
                children: [
                  // Pagination Controls
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _isLoading
                        ? _buildShimmerHeaderFilter()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Baris per halaman:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButton<int>(
                                      value: _controller.itemsPerPage,
                                      dropdownColor: Colors.orange,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      underline: const SizedBox(),
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.white,
                                      ),
                                      items: [5, 10, 20, 50].map((int value) {
                                        return DropdownMenuItem<int>(
                                          value: value,
                                          child: Text(value.toString()),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          _controller.setItemsPerPage(value);
                                          setState(() {
                                            _currentPage = 1;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chevron_left,
                                      color: Colors.white,
                                    ),
                                    onPressed: _currentPage > 1
                                        ? () {
                                            setState(() {
                                              _currentPage--;
                                            });
                                          }
                                        : null,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$_currentPage/$totalPages',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white,
                                    ),
                                    onPressed: _currentPage < totalPages
                                        ? () {
                                            setState(() {
                                              _currentPage++;
                                            });
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),

                  // Activities List
                  Expanded(
                    child: _isLoading
                        ? _buildShimmerList()
                        : activities.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada data riwayat yang sesuai filter',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: activities.length,
                            itemBuilder: (context, index) {
                              return _buildActivityCard(activities[index]);
                            },
                          ),
                  ),
                ],
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
            _buildBottomNavItem(Icons.bar_chart, 'Grafik', false),
            _buildBottomNavItem(Icons.history, 'Riwayat', true),
            _buildBottomNavItem(Icons.dangerous, 'Kematian', false),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(ActivityModel activity) {
    Color backgroundColor;
    Color headerColor;

    switch (activity.type) {
      case 'normal':
        backgroundColor = Colors.white;
        headerColor = Colors.green;
        break;
      case 'warning':
        backgroundColor = Colors.white;
        headerColor = Colors.yellow.shade700;
        break;
      case 'emergency':
        backgroundColor = Colors.white;
        headerColor = Colors.yellow.shade700;
        break;
      case 'error':
        backgroundColor = Colors.white;
        headerColor = const Color(0xFF8B0000); // Dark red
        break;
      default:
        backgroundColor = Colors.white;
        headerColor = Colors.orange;
        break;
    }

    IconData iconData = activity.iconType == 'monitor'
        ? Icons.monitor
        : Icons.settings;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(iconData, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd/MM/yyyy').format(activity.dateTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  DateFormat('HH:mm').format(activity.dateTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Umur : ${activity.chickenAge} Minggu',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activity.description.isNotEmpty)
                  Text(
                    activity.description,
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatusBadge(
                      'Lampu',
                      activity.lampActive ? 'Aktif' : 'Nonaktif',
                      activity.lampActive,
                      Icons.lightbulb,
                    ),
                    const SizedBox(width: 12),
                    _buildStatusBadge(
                      'Kipas',
                      activity.fanActive ? 'Aktif' : 'Nonaktif',
                      activity.fanActive,
                      Icons.ac_unit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    String label,
    String status,
    bool isActive,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.yellow.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? Colors.orange.shade700 : Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $status',
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.orange.shade900 : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
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

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.orange.shade300,
      highlightColor: Colors.orange.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                ),
                Container(
                  height: 88,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerHeaderFilter() {
    return Shimmer.fromColors(
      baseColor: Colors.orange.shade300,
      highlightColor: Colors.orange.shade100,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
