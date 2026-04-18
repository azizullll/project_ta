import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/death_controller.dart';
import '../models/death_model.dart';
import 'history_page.dart';
import 'statistics_page.dart';
import 'dashboard_page.dart';

class DeathPage extends StatefulWidget {
  const DeathPage({super.key});

  @override
  State<DeathPage> createState() => _DeathPageState();
}

class _DeathPageState extends State<DeathPage> {
  final DeathController _controller = DeathController();
  int _currentPage = 1;
  DateTimeRange? _selectedDateRange;
  String _dateFilterText = 'Semua tanggal';

  // Form controllers
  final TextEditingController _countController = TextEditingController();
  int _selectedAge = 1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _countController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateRange?.start ?? DateTime.now(),
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
        _selectedDateRange = DateTimeRange(start: picked, end: picked);
        _dateFilterText = DateFormat('dd/MM/yyyy').format(picked);
        _currentPage = 1;
      });
    }
  }

  List<DeathModel> _getFilteredRecords() {
    final allRecords = _controller.deathRecords;
    if (_selectedDateRange == null) {
      return allRecords;
    }

    final start = DateTime(
      _selectedDateRange!.start.year,
      _selectedDateRange!.start.month,
      _selectedDateRange!.start.day,
    );
    final end = DateTime(
      _selectedDateRange!.end.year,
      _selectedDateRange!.end.month,
      _selectedDateRange!.end.day,
      23,
      59,
      59,
      999,
    );

    return allRecords
        .where(
          (record) =>
              !record.dateTime.isBefore(start) && !record.dateTime.isAfter(end),
        )
        .toList();
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
      _dateFilterText = 'Semua tanggal';
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecords = _getFilteredRecords();
    final totalRecords = filteredRecords.length;
    final totalDeaths = filteredRecords.fold<int>(
      0,
      (sum, record) => sum + record.count,
    );
    final totalPages = totalRecords == 0
        ? 0
        : (totalRecords / _controller.itemsPerPage).ceil();

    if (totalPages > 0 && _currentPage > totalPages) {
      _currentPage = totalPages;
    }

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
          'Data Angka Kematian',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.black),
            onPressed: () async {
              if (filteredRecords.isEmpty) {
                if (!mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tidak ada data kematian untuk diunduh'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                final filePath = await _controller.exportRecordsToPdf(
                  filteredRecords,
                );

                if (!mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('PDF tersimpan: $filePath'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal export PDF: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
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
                      vertical: 16,
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
                const SizedBox(height: 16),

                // Statistics Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Kematian',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$totalDeaths',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Jumlah Data',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$totalRecords',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
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

          // Content Section
          Expanded(
            child: Container(
              color: Colors.orange,
              child: Column(
                children: [
                  // Items per page control
                  if (filteredRecords.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            'Baris per halaman:',
                            style: TextStyle(color: Colors.white, fontSize: 14),
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
                        ],
                      ),
                    ),

                  // Content or Empty State
                  Expanded(
                    child: filteredRecords.isNotEmpty
                        ? _buildDataList(filteredRecords)
                        : _buildEmptyState(),
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
            _buildBottomNavItem(Icons.dangerous, 'Kematian', true),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDeathDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDeathDialog() {
    // Reset form
    _countController.clear();
    _selectedAge = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Tambah Data Kematian',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Jumlah Kematian
                const Text(
                  'Jumlah Kematian',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Masukkan jumlah',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Umur Ayam
                const Text(
                  'Umur Ayam (Minggu)',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<int>(
                    value: _selectedAge,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: List.generate(
                      4,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1} Minggu'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          _selectedAge = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validasi
                if (_countController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Jumlah kematian harus diisi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final count = int.tryParse(_countController.text);
                if (count == null || count <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Jumlah harus berupa angka positif'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Tambah data
                final newRecord = DeathModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  dateTime: DateTime.now(),
                  count: count,
                  cause: 'Tidak dicatat',
                  chickenAge: _selectedAge,
                  notes: '',
                );

                await _controller.addDeathRecord(newRecord);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data kematian berhasil ditambahkan'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data kematian',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteRecord(DeathModel record) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Yakin ingin menghapus data kematian ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await _controller.deleteDeathRecord(record.id);

    if (!mounted) {
      return;
    }

    final filteredRecords = _getFilteredRecords();
    final totalPages = filteredRecords.isEmpty
        ? 0
        : (filteredRecords.length / _controller.itemsPerPage).ceil();
    setState(() {
      if (totalPages == 0) {
        _currentPage = 1;
      } else if (_currentPage > totalPages) {
        _currentPage = totalPages;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data kematian berhasil dihapus'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildDataList(List<DeathModel> filteredRecords) {
    final startIndex = (_currentPage - 1) * _controller.itemsPerPage;
    final endIndex = (startIndex + _controller.itemsPerPage).clamp(
      0,
      filteredRecords.length,
    );

    final records = startIndex >= filteredRecords.length
        ? <DeathModel>[]
        : filteredRecords.sublist(startIndex, endIndex);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Jumlah: ${record.count}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Umur ${record.chickenAge} Mg',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(record.dateTime),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    child: IconButton(
                      onPressed: () => _confirmDeleteRecord(record),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Hapus data',
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
