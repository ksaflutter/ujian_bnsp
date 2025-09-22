import 'package:flutter/material.dart';

import '../../core/constants/app_colors_lokin.dart';
import '../../core/utils/date_helper_lokin.dart';
import '../../core/utils/location_helper_lokin.dart';
import '../../core/widgets/loading_widget_lokin.dart';
import '../../data/models/attendance_model_lokin.dart';
import '../../data/models/stats_model_lokin.dart';
import '../../data/repositories/attendance_repository_lokin.dart';
import '../../data/repositories/auth_repository_lokin.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final _attendanceRepository = AttendanceRepository();
  final _authRepository = AuthRepository();

  AttendanceModelLokin? _todayAttendance;
  StatsModel? _stats;
  bool _isLoading = false;
  String _userName = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Load user data
      await _loadUserData();

      // Load attendance data
      await _loadTodayAttendance();

      // Load statistics
      await _loadStats();
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      // PERBAIKAN: Gunakan currentUser property dari AuthRepository
      final user = _authRepository.currentUser;
      if (user != null && mounted) {
        setState(() {
          _userName = user.name;
        });
        print('User name loaded from local: ${user.name}');
      } else {
        // PERBAIKAN: Jika tidak ada user lokal, coba ambil dari server
        final result = await _authRepository.getProfile();
        if (result.isSuccess && result.user != null && mounted) {
          setState(() {
            _userName = result.user!.name;
          });
          print('User name loaded from server: ${result.user!.name}');
        } else {
          print('Failed to load user data: ${result.message}');
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

/*************  ✨ Windsurf Command ⭐  *************/
  /// Load today's attendance data
  ///
  /// This function calls the attendance repository to get the attendance
  /// data for today, and then updates the state with the result.
  ///
  /// Throws an exception if there is an error loading the data.
/*******  ae3d85b5-b8d1-43ce-b759-a4470469b9e0  *******/ Future<void>
      _loadTodayAttendance() async {
    try {
      final result = await _attendanceRepository.getTodayAttendance();
      if (mounted && result.isSuccess) {
        setState(() {
          _todayAttendance = result.attendance;
        });
      }
    } catch (e) {
      print('Error loading today attendance: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final result = await _attendanceRepository.getStats();
      if (mounted && result.isSuccess) {
        setState(() {
          _stats = result.stats;
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _handleCheckIn() async {
    try {
      final location = await LocationHelperLokin.getCurrentLocation();

      if (location != null) {
        setState(() {
          _isLoading = true;
        });

        final result = await _attendanceRepository.checkIn(
          latitude: location.latitude,
          longitude: location.longitude,
          address: location.address,
        );

        if (mounted) {
          if (result.isSuccess) {
            _showSnackBar(result.message, isError: false);
            await _loadTodayAttendance();
            await _loadStats();
          } else {
            _showSnackBar(result.message, isError: true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Terjadi kesalahan: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCheckOut() async {
    try {
      final location = await LocationHelperLokin.getCurrentLocation();

      if (location != null) {
        setState(() {
          _isLoading = true;
        });

        final result = await _attendanceRepository.checkOut(
          latitude: location.latitude,
          longitude: location.longitude,
          address: location.address,
        );

        if (mounted) {
          if (result.isSuccess) {
            _showSnackBar(result.message, isError: false);
            await _loadTodayAttendance();
            await _loadStats();
          } else {
            _showSnackBar(result.message, isError: true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Terjadi kesalahan: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColorsLokin.error : AppColorsLokin.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColorsLokin.primary, AppColorsLokin.secondary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateHelperLokin.getGreeting(),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          // PERBAIKAN: Logika yang lebih robust untuk menampilkan nama user
                          _userName.isNotEmpty ? _userName : 'User',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateHelperLokin.formatDateWithDay(DateTime.now()),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceStatus() {
    if (_todayAttendance == null) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColorsLokin.surface.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColorsLokin.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColorsLokin.textSecondary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Belum ada data absensi hari ini',
                style: TextStyle(color: AppColorsLokin.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            'Status Absen Hari Ini',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColorsLokin.textPrimary,
                ),
          ),
          const SizedBox(height: 16),

          // Check In Status
          if (_todayAttendance!.checkInTime != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorsLokin.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColorsLokin.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColorsLokin.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.login,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Absen Masuk',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColorsLokin.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          _todayAttendance!.checkInTime!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColorsLokin.success,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        if (_todayAttendance!.checkInAddress?.isNotEmpty ==
                            true)
                          Text(
                            _todayAttendance!.checkInAddress!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColorsLokin.textSecondary,
                                    ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Check Out Status
          if (_todayAttendance!.checkOutTime != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorsLokin.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColorsLokin.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColorsLokin.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Absen Keluar',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColorsLokin.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          _todayAttendance!.checkOutTime!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColorsLokin.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        if (_todayAttendance!.checkOutAddress?.isNotEmpty ==
                            true)
                          Text(
                            _todayAttendance!.checkOutAddress!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColorsLokin.textSecondary,
                                    ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Permission Status
          if (_todayAttendance!.status == 'izin') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorsLokin.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColorsLokin.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    color: AppColorsLokin.warning,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Anda Sedang Izin Hari Ini',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColorsLokin.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        if (_todayAttendance!.alasanIzin?.isNotEmpty == true)
                          Text(
                            _todayAttendance!.alasanIzin!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColorsLokin.textSecondary,
                                    ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final canCheckIn = _todayAttendance?.checkInTime == null &&
        _todayAttendance?.status != 'izin';
    final canCheckOut = _todayAttendance?.checkInTime != null &&
        _todayAttendance?.checkOutTime == null &&
        _todayAttendance?.status != 'izin';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.login,
              title: 'Absen Masuk',
              color: AppColorsLokin.success,
              isEnabled: canCheckIn && !_isLoading,
              onTap: _handleCheckIn,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              icon: Icons.logout,
              title: 'Absen Keluar',
              color: AppColorsLokin.primary,
              isEnabled: canCheckOut && !_isLoading,
              onTap: _handleCheckOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required bool isEnabled,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isEnabled ? color : AppColorsLokin.border,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_stats == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Statistik Absensi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColorsLokin.textPrimary,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColorsLokin.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Bulan Ini',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColorsLokin.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // PERBAIKAN: Fixed consistent layout for statistics cards
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildStatItem(
                  title: 'Total\nAbsen',
                  value: '${_stats!.totalAbsen}',
                  color: AppColorsLokin.primary,
                  icon: Icons.calendar_month,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildStatItem(
                  title: 'Masuk',
                  value: '${_stats!.totalMasuk}',
                  color: AppColorsLokin.success,
                  icon: Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildStatItem(
                  title: 'Izin',
                  value: '${_stats!.totalIzin}',
                  color: AppColorsLokin.warning,
                  icon: Icons.assignment,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      // PERBAIKAN: Fixed height dan padding untuk konsistensi
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColorsLokin.textSecondary,
                  fontSize: 8,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColorsLokin.background,
      body: _isLoading
          ? const Center(child: LoadingWidgetLokin())
          : RefreshIndicator(
              onRefresh: _initializeData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildAttendanceStatus(),
                    _buildActionButtons(),
                    _buildStatsCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
