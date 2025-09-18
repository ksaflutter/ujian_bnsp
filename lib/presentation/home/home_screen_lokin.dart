import 'package:flutter/material.dart';

import '../../core/constants/app_colors_lokin.dart';
import '../../core/utils/date_helper_lokin.dart';
import '../../core/widgets/custom_button_lokin.dart';
import '../../data/models/attendance_model_lokin.dart';
import '../../data/models/stats_model_lokin.dart';
import '../../data/models/user_model_lokin.dart';
import '../../data/repositories/attendance_repository_lokin.dart';
import '../../data/repositories/auth_repository_lokin.dart';
import '../auth/login_screen_lokin.dart';
import '../widgets/attendance_map_widget.dart';

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
    _currentUser = _authRepository.currentUser;
    if (_currentUser == null) {
      _navigateToLogin();
      return;
    }

    await Future.wait([_loadTodayAttendance(), _loadStats()]);
  }

  Future<void> _loadTodayAttendance() async {
    try {
      final result = await _attendanceRepository.getTodayAttendance();
      if (result.isSuccess && mounted) {
        setState(() {
          _todayAttendance = result.attendance;
        });
      }
    } catch (e) {
      // Silently handle error
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

  Future<void> _handleCheckIn() async {
    await _handleAttendanceWithMap(isCheckIn: true);
  }

  Future<void> _handleCheckOut() async {
    await _handleAttendanceWithMap(isCheckIn: false);
  }

  Future<void> _handleAttendanceWithMap({required bool isCheckIn}) async {
    try {
      // Show map selection dialog with Jakarta default
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AttendanceLocationSelector(
          title: isCheckIn
              ? 'Pilih Lokasi Absen Masuk'
              : 'Pilih Lokasi Absen Keluar',
          subtitle:
              'Pastikan lokasi sudah sesuai dengan tempat kerja Anda\n(Default: Jakarta, Indonesia)',
          onLocationConfirmed: (lat, lng, address) async {
            // This callback will be called when user confirms location
            print('Location confirmed: $lat, $lng, $address'); // Debug print
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
      print('Error in _handleAttendanceWithMap: $e'); // Debug print
      _showErrorSnackBar('Terjadi kesalahan: $e');
    }
  }

  Future<void> _processAttendance({
    required bool isCheckIn,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    print('Processing attendance: isCheckIn=$isCheckIn'); // Debug print

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Show confirmation dialog
      final confirm = await _showConfirmationDialog(
        title: isCheckIn ? 'Konfirmasi Absen Masuk' : 'Konfirmasi Absen Keluar',
        message:
            'Lokasi: $address\n\nApakah Anda yakin ingin ${isCheckIn ? 'absen masuk' : 'absen keluar'}?',
      );

      if (!confirm) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Calling API...'); // Debug print

      // Call API
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

      print(
          'API result: ${result.isSuccess}, ${result.message}'); // Debug print

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result.isSuccess) {
          _showSuccessDialog(result.message);
          // Refresh data after successful attendance
          await Future.wait([_loadTodayAttendance(), _loadStats()]);
        } else {
          _showErrorSnackBar(result.message);
        }
      }
    } catch (e) {
      print('Error in _processAttendance: $e'); // Debug print
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Terjadi kesalahan: $e');
      }
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: AppColorsLokin.textSecondary),
                ),
              ),
              CustomButton(
                text: 'Ya, Yakin',
                onPressed: () => Navigator.of(context).pop(true),
                width: 100,
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColorsLokin.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
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
          CustomButton(
            text: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColorsLokin.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateHelperLokin.getGreeting(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUser?.name ?? 'User',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  DateHelperLokin.formatDateWithDay(now),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStatus() {
    final hasCheckedIn = _todayAttendance?.checkInTime != null;
    final hasCheckedOut = _todayAttendance?.checkOutTime != null;
    final isPermission = _todayAttendance?.status == 'izin';

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
            'Status Absensi Hari Ini',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColorsLokin.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          if (isPermission) ...[
            _buildStatusItem(
              icon: Icons.assignment_outlined,
              title: 'Izin',
              subtitle: _todayAttendance?.alasanIzin ?? 'Sedang izin',
              color: AppColorsLokin.warning,
            ),
          ] else ...[
            _buildStatusItem(
              icon: hasCheckedIn
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              title: 'Absen Masuk',
              subtitle: hasCheckedIn
                  ? 'Pukul ${_todayAttendance?.checkInTime ?? '-'}'
                  : 'Belum absen masuk',
              color: hasCheckedIn
                  ? AppColorsLokin.success
                  : AppColorsLokin.textSecondary,
            ),
            const SizedBox(height: 12),
            _buildStatusItem(
              icon: hasCheckedOut
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              title: 'Absen Keluar',
              subtitle: hasCheckedOut
                  ? 'Pukul ${_todayAttendance?.checkOutTime ?? '-'}'
                  : 'Belum absen keluar',
              color: hasCheckedOut
                  ? AppColorsLokin.success
                  : AppColorsLokin.textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColorsLokin.textPrimary,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColorsLokin.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final hasCheckedIn = _todayAttendance?.checkInTime != null;
    final hasCheckedOut = _todayAttendance?.checkOutTime != null;
    final isPermission = _todayAttendance?.status == 'izin';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (!isPermission) ...[
            // Check In Button
            if (!hasCheckedIn)
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColorsLokin.success.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Memproses Absensi...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : CustomButton(
                        text: 'Absen Masuk',
                        onPressed: _handleCheckIn,
                        backgroundColor: AppColorsLokin.success,
                        icon: Icons.login,
                      ),
              ),

            // Check Out Button
            if (hasCheckedIn && !hasCheckedOut) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColorsLokin.error.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Memproses Absensi...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : CustomButton(
                        text: 'Absen Keluar',
                        onPressed: _handleCheckOut,
                        backgroundColor: AppColorsLokin.error,
                        icon: Icons.logout,
                      ),
              ),
            ],

            // Completed Status
            if (hasCheckedIn && hasCheckedOut) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColorsLokin.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColorsLokin.success.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColorsLokin.success),
                    const SizedBox(width: 8),
                    Text(
                      'Absensi Hari Ini Selesai',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColorsLokin.success,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            // Permission Status
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment, color: AppColorsLokin.warning),
                  const SizedBox(width: 8),
                  Text(
                    'Anda Sedang Izin Hari Ini',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColorsLokin.warning,
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

  Widget _buildStatsCard() {
    if (_stats == null) return const SizedBox.shrink();

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

          // Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColorsLokin.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: _stats!.persentaseKehadiran / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColorsLokin.success,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_stats!.persentaseKehadiran.toStringAsFixed(1)}% Kehadiran',
            style: Theme.of(
              context,
            )
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColorsLokin.textSecondary),
          ),

          const SizedBox(height: 16),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  title: 'Total Absen',
                  value: '${_stats!.totalAbsen}',
                  color: AppColorsLokin.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  title: 'Hadir',
                  value: '${_stats!.totalMasuk}',
                  color: AppColorsLokin.success,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  title: 'Izin',
                  value: '${_stats!.totalIzin}',
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
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColorsLokin.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
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
