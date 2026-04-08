import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';
import 'history_page.dart';
import 'death_page.dart';
import 'statistics_page.dart';
import 'dashboard_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationController _controller = NotificationController();
  int _currentPage = 1;
  DateTimeRange? _selectedDateRange;
  String _dateFilterText = 'Semua Tanggal';
  int? _selectedAge;
  bool _isLoading = false;

  int _resolveDefaultAge() {
    if (_controller.notifications.isNotEmpty) {
      return _controller.notifications.first.chickenAge;
    }
    return 1;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) {
        if (_selectedAge == null && _controller.notifications.isNotEmpty) {
          _selectedAge = _controller.notifications.first.chickenAge;
        }
        setState(() {});
      }
    });
    _refreshNotifications();
  }

  Future<void> _refreshNotifications() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      await _controller.refreshNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                                  if (endDate != null &&
                                      picked.isAfter(endDate!)) {
                                    endDate = picked;
                                  }
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
                          child: GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    endDate ?? startDate ?? DateTime.now(),
                                firstDate: startDate ?? DateTime(2020),
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
                                  endDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
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
                            'End Date',
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
                          onPressed: () {
                            if (startDate != null && endDate != null) {
                              this.setState(() {
                                _selectedDateRange = DateTimeRange(
                                  start: startDate!,
                                  end: endDate!,
                                );
                                _dateFilterText =
                                    '${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}';
                              });
                              Navigator.of(context).pop();
                            }
                          },
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

  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
      _dateFilterText = 'Semua Tanggal';
      _currentPage = 1;
    });
  }

  Future<void> _showAgeFilterDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
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
                  'Pilih Umur Ayam',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildAgeOption(1),
                const Divider(),
                _buildAgeOption(2),
                const Divider(),
                _buildAgeOption(3),
                const Divider(),
                _buildAgeOption(4),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Tutup',
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

  Future<void> _exportNotificationsToPdf() async {
    if (_isLoading) {
      return;
    }

    final dataToExport = _getFilteredNotifications();
    if (dataToExport.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada notifikasi untuk diunduh'),
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
            (notification) => [
              DateFormat('dd/MM/yyyy').format(notification.dateTime),
              DateFormat('HH:mm').format(notification.dateTime),
              notification.title,
              notification.description,
              notification.severity.toUpperCase(),
              notification.chickenAge.toString(),
            ],
          )
          .toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Text(
              'Laporan Notifikasi',
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
                'Judul',
                'Deskripsi',
                'Severity',
                'Umur',
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
      final ageLabel = _selectedAge ?? _resolveDefaultAge();
      final fileName =
          'notifikasi_umur_${ageLabel}_minggu_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
            content: Text('Gagal export PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAgeOption(int age) {
    final isSelected = _selectedAge == age;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAge = age;
          _currentPage = 1;
        });
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: Colors.orange,
            ),
            const SizedBox(width: 12),
            Text(
              '$age Minggu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.orange : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<NotificationModel> _getFilteredNotifications() {
    return _controller.getFilteredNotifications(
      dateRange: _selectedDateRange,
      selectedAge: _selectedAge,
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _getFilteredNotifications();
    final defaultAge = _resolveDefaultAge();

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
        title: Flexible(
          child: Text(
            'Notifikasi (Umur : ${_controller.notifications.isNotEmpty ? _controller.notifications.first.chickenAge : 1} minggu)',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
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
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _dateFilterText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selectedDateRange != null)
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _clearDateFilter,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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
                                    Text(
                                      _selectedAge != null
                                          ? 'Umur: $_selectedAge Minggu'
                                          : 'Umur Saat Ini ($defaultAge minggu)',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
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
                      onTap: _exportNotificationsToPdf,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left side controls - wrapped in Flexible
                        Flexible(
                          flex: 2,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
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
                                    style: const TextStyle(color: Colors.white),
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
                                const SizedBox(width: 8),
                                // Action buttons in smaller format
                                IconButton(
                                  onPressed: _refreshNotifications,
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  tooltip: 'Refresh',
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _controller.addDemoNotifications();
                                  },
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  tooltip: 'Add demo',
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _controller.clearAndReload();
                                  },
                                  icon: const Icon(
                                    Icons.clear_all,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  tooltip: 'Clear all',
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Right side info - wrapped in Flexible
                        Flexible(
                          flex: 1,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Total: ${notifications.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'New: ${_controller.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Debug info button - smaller
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Debug Info'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Firebase Status: Connected 🔥',
                                            ),
                                            Text(
                                              'Total Notifications: ${notifications.length}',
                                            ),
                                            Text(
                                              'Unread: ${_controller.unreadCount}',
                                            ),
                                            Text(
                                              'Last Update: ${DateTime.now().toString().substring(11, 19)}',
                                            ),
                                            const SizedBox(height: 16),
                                            const Text('Sensor Data:'),
                                            const Text(
                                              'Temperature: Live from Firebase',
                                            ),
                                            const Text(
                                              'Humidity: Live from Firebase',
                                            ),
                                            const Text(
                                              'Detection: Auto notifications enabled',
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 48,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'DEBUG',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notifications List
                  Expanded(
                    child: _isLoading
                        ? _buildShimmerList()
                        : notifications.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  size: 64,
                                  color: Colors.white70,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Tidak ada notifikasi',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshNotifications,
                            color: Colors.orange,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: notifications.length,
                              itemBuilder: (context, index) {
                                return _buildNotificationCard(
                                  notifications[index],
                                );
                              },
                            ),
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
            _buildBottomNavItem(Icons.history, 'Riwayat', false),
            _buildBottomNavItem(Icons.dangerous, 'Kematian', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    Color backgroundColor;
    Color headerColor;

    switch (notification.severity) {
      case 'high':
        backgroundColor = Colors.white;
        headerColor = const Color(0xFFF44336); // Red for high priority
        break;
      case 'low':
        backgroundColor = Colors.white;
        headerColor = const Color(0xFF4CAF50); // Green for low priority
        break;
      case 'medium':
      default:
        backgroundColor = Colors.white;
        headerColor = const Color(0xFFFFA726); // Orange for medium priority
        break;
    }

    IconData iconData;
    switch (notification.type) {
      case 'humidity':
        iconData = Icons.water_drop;
        break;
      case 'temperature':
        iconData = Icons.thermostat;
        break;
      case 'alert':
        iconData = Icons.warning;
        break;
      case 'fuzzy':
        iconData = Icons.psychology;
        break;
      default:
        iconData = Icons.notifications;
        break;
    }

    return GestureDetector(
      onTap: () {
        // Mark as read when tapped
        if (!notification.isRead) {
          _controller.markAsRead(notification.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: notification.isRead
              ? null
              : Border.all(color: Colors.white, width: 2),
        ),
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
                    DateFormat('dd/MM/yyyy').format(notification.dateTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    DateFormat('HH:mm').format(notification.dateTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: 8),
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
                      'Umur : ${notification.chickenAge} Minggu',
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
                color: backgroundColor.withOpacity(
                  notification.isRead ? 0.8 : 1.0,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notification.description != notification.title) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.description,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontStyle: notification.isRead
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: headerColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: headerColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            notification.severity.toUpperCase(),
                            style: TextStyle(
                              color: headerColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          DateFormat(
                            'dd MMM yyyy, HH:mm',
                          ).format(notification.dateTime),
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
}
