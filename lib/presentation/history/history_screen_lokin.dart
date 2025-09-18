import 'package:flutter/material.dart';

import '../../core/constants/app_colors_lokin.dart';
import '../../core/utils/date_helper_lokin.dart';
import '../../core/widgets/loading_widget_lokin.dart';
import '../../data/models/attendance_model_lokin.dart';
import '../../data/repositories/attendance_repository_lokin.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with AutomaticKeepAliveClientMixin {
  final _attendanceRepository = AttendanceRepository();

  List<AttendanceModelLokin> _attendances = [];
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedFilter = 'Semua';

  final List<String> _filterOptions = [
    'Semua',
    'Minggu Ini',
    'Bulan Ini',
    'Bulan Lalu',
    'Custom',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAttendanceHistory();
  }

  Future<void> _loadAttendanceHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? startDate;
      String? endDate;

      // Apply filter
      if (_selectedFilter != 'Semua') {
        final dates = _getDateRange(_selectedFilter);
        if (dates != null) {
          startDate = DateHelperLokin.formatDate(dates['start']!);
          endDate = DateHelperLokin.formatDate(dates['end']!);
        }
      }

      // Use custom date range if selected
      if (_selectedFilter == 'Custom' &&
          _startDate != null &&
          _endDate != null) {
        startDate = DateHelperLokin.formatDate(_startDate!);
        endDate = DateHelperLokin.formatDate(_endDate!);
      }

      final result = await _attendanceRepository.getAttendanceHistory(
        start: startDate,
        end: endDate,
      );

      if (result.isSuccess && mounted) {
        setState(() {
          _attendances = result.attendances;
        });
      } else {
        _showErrorSnackBar(result.message);
      }
    } catch (e) {
      _showErrorSnackBar('Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, DateTime>? _getDateRange(String filter) {
    final now = DateTime.now();

    switch (filter) {
      case 'Minggu Ini':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return {
          'start': DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          ),
          'end': DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day),
        };

      case 'Bulan Ini':
        return {
          'start': DateTime(now.year, now.month, 1),
          'end': DateTime(now.year, now.month + 1, 0),
        };

      case 'Bulan Lalu':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        return {
          'start': lastMonth,
          'end': DateTime(lastMonth.year, lastMonth.month + 1, 0),
        };

      default:
        return null;
    }
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColorsLokin.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedFilter = 'Custom';
      });
      await _loadAttendanceHistory();
    }
  }

  Future<void> _showDeleteConfirmation(AttendanceModelLokin attendance) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Absensi'),
        content: Text(
          'Apakah Anda yakin ingin menghapus data absensi tanggal ${attendance.attendanceDate}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColorsLokin.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColorsLokin.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteAttendance(attendance.id!);
    }
  }

  Future<void> _deleteAttendance(int id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _attendanceRepository.deleteAttendance(id);

      if (result.isSuccess) {
        _showSuccessSnackBar(result.message);
        await _loadAttendanceHistory();
      } else {
        _showErrorSnackBar(result.message);
      }
    } catch (e) {
      _showErrorSnackBar('Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColorsLokin.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColorsLokin.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorsLokin.primary,
            AppColorsLokin.primary.withOpacity(0.8)
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riwayat Absensi',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lihat riwayat kehadiran Anda',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Periode',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColorsLokin.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _filterOptions.map((filter) {
              final isSelected = _selectedFilter == filter;
              return GestureDetector(
                onTap: () async {
                  if (filter == 'Custom') {
                    await _showDateRangePicker();
                  } else {
                    setState(() {
                      _selectedFilter = filter;
                      _startDate = null;
                      _endDate = null;
                    });
                    await _loadAttendanceHistory();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColorsLokin.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColorsLokin.primary
                          : AppColorsLokin.border,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    filter,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColorsLokin.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedFilter == 'Custom' &&
              _startDate != null &&
              _endDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColorsLokin.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.date_range,
                    color: AppColorsLokin.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${DateHelperLokin.formatDate(_startDate!)} - ${DateHelperLokin.formatDate(_endDate!)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColorsLokin.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    if (_isLoading) {
      return const Center(
        child:
            Padding(padding: EdgeInsets.all(40), child: LoadingWidgetLokin()),
      );
    }

    if (_attendances.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: AppColorsLokin.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada riwayat absensi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColorsLokin.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Riwayat absensi akan muncul setelah Anda melakukan absensi',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColorsLokin.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _attendances.length,
      itemBuilder: (context, index) {
        final attendance = _attendances[index];
        return _buildAttendanceItem(attendance);
      },
    );
  }

  Widget _buildAttendanceItem(AttendanceModelLokin attendance) {
    final isPermission = attendance.status == 'izin';
    final hasCheckedOut = attendance.checkOutTime != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              attendance.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getStatusIcon(attendance.status),
                            color: _getStatusColor(attendance.status),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateHelperLokin.formatDateWithDay(
                                DateTime.parse(attendance.attendanceDate),
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColorsLokin.textPrimary,
                                  ),
                            ),
                            Text(
                              _getStatusText(attendance.status),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: _getStatusColor(attendance.status),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteConfirmation(attendance);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: AppColorsLokin.error),
                              SizedBox(width: 8),
                              Text('Hapus'),
                            ],
                          ),
                        ),
                      ],
                      child: const Icon(
                        Icons.more_vert,
                        color: AppColorsLokin.textSecondary,
                      ),
                    ),
                  ],
                ),

                if (isPermission) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColorsLokin.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColorsLokin.warning,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            attendance.alasanIzin ?? 'Tanpa keterangan',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColorsLokin.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  // Time and Location Info
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeLocationInfo(
                          title: 'Masuk',
                          time: attendance.checkInTime,
                          address: attendance.checkInAddress,
                          icon: Icons.login,
                        ),
                      ),
                      if (hasCheckedOut) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTimeLocationInfo(
                            title: 'Keluar',
                            time: attendance.checkOutTime,
                            address: attendance.checkOutAddress,
                            icon: Icons.logout,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLocationInfo({
    required String title,
    String? time,
    String? address,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColorsLokin.textSecondary),
            const SizedBox(width: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColorsLokin.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time ?? '-',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColorsLokin.textPrimary,
              ),
        ),
        if (address != null) ...[
          const SizedBox(height: 2),
          Text(
            address,
            style: Theme.of(
              context,
            )
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColorsLokin.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'masuk':
        return AppColorsLokin.success;
      case 'izin':
        return AppColorsLokin.warning;
      default:
        return AppColorsLokin.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'masuk':
        return Icons.check_circle;
      case 'izin':
        return Icons.assignment;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'masuk':
        return 'Hadir';
      case 'izin':
        return 'Izin';
      default:
        return 'Tidak Diketahui';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColorsLokin.background,
      body: RefreshIndicator(
        onRefresh: _loadAttendanceHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              _buildFilterSection(),
              _buildAttendanceList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
