import 'package:flutter/material.dart';
import 'package:lokinid_app/presentation/widgets/attendance_map_widget.dart';

import '../../core/constants/app_colors_lokin.dart';
import '../../core/utils/date_helper_lokin.dart';
import '../../data/models/attendance_model_lokin.dart';
import '../../data/models/stats_model_lokin.dart';
import '../../data/models/user_model_lokin.dart';
import '../../data/repositories/attendance_repository_lokin.dart';
import '../../data/repositories/auth_repository_lokin.dart';
import '../auth/login_screen_lokin.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final _authRepository = AuthRepository();
  final _attendanceRepository = AttendanceRepository();

  UserModelLokin? _currentUser;
  AttendanceModelLokin? _todayAttendance;
  StatsModel? _stats;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    print('=== HOME SCREEN INITIALIZE ===');

    // Load user from local storage first
    _currentUser = _authRepository.currentUser;
    print('Local user found: ${_currentUser?.name}');

    if (_currentUser == null) {
      print('No user found, navigating to login');
      _navigateToLogin();
      return;
    }

    // Refresh UI with local data first
    setState(() {});

    // Then load attendance and stats data
    await Future.wait([
      _loadTodayAttendance(),
      _loadStats(),
      _refreshUserData(), // Also refresh user data from server
    ]);
  }

  Future<void> _refreshUserData() async {
    try {
      print('=== REFRESHING USER DATA IN HOME ===');
      final result = await _authRepository.getProfile();

      if (result.isSuccess && result.user != null) {
        print('User data refreshed in home: ${result.user!.name}');
        setState(() {
          _currentUser = result.user;
        });
      } else {
        print('Failed to refresh user data in home: ${result.message}');
      }
    } catch (e) {
      print('Exception refreshing user data in home: $e');
      // Silently handle error - user can still use the app with local data
    }
  }

  Future<void> _loadTodayAttendance() async {
    try {
      print('DEBUG HOME: Loading today attendance...');
      final result = await _attendanceRepository.getTodayAttendance();

      print('DEBUG HOME: API Result - isSuccess: ${result.isSuccess}');
      print('DEBUG HOME: API Message: ${result.message}');

      if (result.isSuccess && mounted) {
        setState(() {
          _todayAttendance = result.attendance;
        });
        print(
            'DEBUG HOME: Today attendance set - data: ${_todayAttendance?.toJson()}');
        print(
            'DEBUG HOME: hasCheckedIn: ${_todayAttendance?.checkInTime != null}');
        print(
            'DEBUG HOME: hasCheckedOut: ${_todayAttendance?.checkOutTime != null}');
        print('DEBUG HOME: status: ${_todayAttendance?.status}');
      } else {
        print('DEBUG HOME: No attendance data or API failed');
        if (mounted) {
          setState(() {
            _todayAttendance = null;
          });
        }
      }
    } catch (e) {
      print('DEBUG HOME: Error loading today attendance: $e');
      if (mounted) {
        setState(() {
          _todayAttendance = null;
        });
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final result = await _attendanceRepository.getStats();
      if (result.isSuccess && mounted) {
        setState(() {
          _stats = result.stats;
        });
      }
    } catch (e) {
      // Silently handle error
    }
  }

  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _handleCheckIn() async {
    await _handleAttendanceWithMap(isCheckIn: true);
  }

  Future<void> _handleCheckOut() async {
    await _handleAttendanceWithMap(isCheckIn: false);
  }

  Future<void> _handleAttendanceWithMap({required bool isCheckIn}) async {
    if (_isLoading) return;

    try {
      print(
          'DEBUG: Opening location selector dialog for ${isCheckIn ? 'check-in' : 'check-out'}');

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AttendanceLocationSelector(
          title: isCheckIn
              ? 'Pilih Lokasi untuk Absen Masuk'
              : 'Pilih Lokasi untuk Absen Keluar',
          onLocationConfirmed: (lat, lng, address) async {
            print(
                'DEBUG: Location confirmed - lat: $lat, lng: $lng, address: $address');
            await _processAttendance(
              isCheckIn: isCheckIn,
              latitude: lat,
              longitude: lng,
              address: address,
            );
          },
        ),
      );
    } catch (e) {
      print('DEBUG: Error in _handleAttendanceWithMap: $e');
      _showErrorSnackBar('Terjadi kesalahan: $e');
    }
  }

  Future<void> _processAttendance({
    required bool isCheckIn,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG: Processing ${isCheckIn ? 'check-in' : 'check-out'}');
      print('DEBUG: Coordinates - lat: $latitude, lng: $longitude');
      print('DEBUG: Address: $address');

      final result = isCheckIn
          ? await _attendanceRepository.checkIn(
              latitude: latitude,
              longitude: longitude,
              address: address,
            )
          : await _attendanceRepository.checkOut(
              latitude: latitude,
              longitude: longitude,
              address: address,
            );

      print('DEBUG: Attendance result - success: ${result.isSuccess}');
      print('DEBUG: Attendance message: ${result.message}');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result.isSuccess) {
          _showSuccessDialog(result.message);
          await _loadTodayAttendance(); // Refresh attendance data
          await _loadStats(); // Refresh stats
        } else {
          _showErrorSnackBar(result.message);
        }
      }
    } catch (e) {
      print('DEBUG: Exception in _processAttendance: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Terjadi kesalahan: $e');
      }
    }
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final greeting = DateHelperLokin.getGreeting();
    final dateString = DateHelperLokin.formatDateIndonesian(now);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColorsLokin.primary, AppColorsLokin.secondary],
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
                          greeting,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentUser?.name ?? 'Memuat...',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigate to profile or show user menu
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dateString,
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorsLokin.surface,
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildStatusCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_todayAttendance == null) {
      return _buildEmptyStatusCard();
    }

    final hasCheckedIn = _todayAttendance!.checkInTime != null;
    final hasCheckedOut = _todayAttendance!.checkOutTime != null;
    final isPermission = _todayAttendance!.status == 'izin';

    if (isPermission) {
      return _buildPermissionStatusCard();
    }

    return Column(
      children: [
        _buildStatusItem(
          title: 'Absen Masuk',
          time: hasCheckedIn ? _todayAttendance!.checkInTime! : null,
          address: hasCheckedIn ? _todayAttendance!.checkInAddress : null,
          isCompleted: hasCheckedIn,
        ),
        const SizedBox(height: 12),
        _buildStatusItem(
          title: 'Absen Keluar',
          time: hasCheckedOut ? _todayAttendance!.checkOutTime! : null,
          address: hasCheckedOut ? _todayAttendance!.checkOutAddress : null,
          isCompleted: hasCheckedOut,
        ),
      ],
    );
  }

  Widget _buildEmptyStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorsLokin.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColorsLokin.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.access_time,
            size: 48,
            color: AppColorsLokin.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum Ada Absen',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColorsLokin.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lakukan absen masuk untuk memulai hari belajar Anda',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColorsLokin.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorsLokin.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColorsLokin.warning.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 48,
            color: AppColorsLokin.warning,
          ),
          const SizedBox(height: 12),
          Text(
            'Sedang Izin',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColorsLokin.warning,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          if (_todayAttendance!.alasanIzin != null)
            Text(
              'Alasan: ${_todayAttendance!.alasanIzin}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColorsLokin.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required String title,
    required String? time,
    required String? address,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColorsLokin.success.withOpacity(0.1)
            : AppColorsLokin.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? AppColorsLokin.success.withOpacity(0.3)
              : AppColorsLokin.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColorsLokin.success
                  : AppColorsLokin.textSecondary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.access_time,
              color: isCompleted ? Colors.white : AppColorsLokin.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isCompleted
                            ? AppColorsLokin.success
                            : AppColorsLokin.textSecondary,
                      ),
                ),
                if (isCompleted && time != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColorsLokin.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (address != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      address,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColorsLokin.textSecondary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ] else if (!isCompleted) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Belum absen',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColorsLokin.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasCheckedIn = _todayAttendance?.checkInTime != null;
    final hasCheckedOut = _todayAttendance?.checkOutTime != null;
    final isPermission = _todayAttendance?.status == 'izin';

    if (isPermission) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              title: 'Absen Masuk',
              icon: Icons.login,
              color: AppColorsLokin.success,
              isEnabled: !hasCheckedIn && !_isLoading,
              onTap: _handleCheckIn,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              title: 'Absen Keluar',
              icon: Icons.logout,
              color: AppColorsLokin.error,
              isEnabled: hasCheckedIn && !hasCheckedOut && !_isLoading,
              onTap: _handleCheckOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required VoidCallback onTap,
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorsLokin.surface,
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
            'Statistik Absensi',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  title: 'Total Absen',
                  value: '${_stats!.totalAbsen}',
                  icon: Icons.calendar_today,
                  color: AppColorsLokin.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  title: 'Masuk',
                  value: '${_stats!.totalMasuk}',
                  icon: Icons.check_circle,
                  color: AppColorsLokin.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  title: 'Izin',
                  value: '${_stats!.totalIzin}',
                  icon: Icons.assignment,
                  color: AppColorsLokin.warning,
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
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColorsLokin.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColorsLokin.success,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Berhasil!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColorsLokin.success,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: AppColorsLokin.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColorsLokin.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColorsLokin.background,
      body: RefreshIndicator(
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
