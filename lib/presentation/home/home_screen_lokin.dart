import 'package:flutter/material.dart';

import '../../core/constants/app_colors_lokin.dart';
import '../../core/utils/date_helper_lokin.dart';
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
              ? 'Pilih Lokasi Absen Masuk'
              : 'Pilih Lokasi Absen Keluar',
          subtitle:
              'Pastikan lokasi sudah sesuai dengan tempat kerja Anda\n(Default: Jakarta, Indonesia)',
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

    print(
        'DEBUG: Starting _processAttendance for ${isCheckIn ? 'check-in' : 'check-out'}');

    setState(() {
      _isLoading = true;
    });

    try {
      final confirm = await _showConfirmationDialog(
        title: isCheckIn ? 'Konfirmasi Absen Masuk' : 'Konfirmasi Absen Keluar',
        message:
            'Lokasi: $address\n\nApakah Anda yakin ingin ${isCheckIn ? 'absen masuk' : 'absen keluar'}?',
      );

      if (!confirm) {
        print('DEBUG: User cancelled confirmation');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('DEBUG: User confirmed, calling API...');

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
          'DEBUG: API result - success: ${result.isSuccess}, message: ${result.message}');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result.isSuccess) {
          _showSuccessDialog(result.message);

          print('DEBUG: Attendance success, reloading data...');

          // PERBAIKAN: Delay lebih lama untuk memastikan data tersimpan di server
          await Future.delayed(const Duration(milliseconds: 2000)); // 2 detik
          await _forceReloadData();
        } else {
          print('DEBUG: Attendance failed: ${result.message}');
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

  // PERBAIKAN: Method baru untuk force reload data dengan debug yang lebih baik
  Future<void> _forceReloadData() async {
    print('DEBUG HOME: Force reloading data...');

    setState(() {
      _todayAttendance = null;
      _stats = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    // PERBAIKAN: Gunakan method force refresh yang baru
    final attendanceResult =
        await _attendanceRepository.forceRefreshTodayAttendance();
    if (attendanceResult.isSuccess && mounted) {
      setState(() {
        _todayAttendance = attendanceResult.attendance;
      });
      print(
          'DEBUG HOME: Attendance refreshed - hasCheckedIn: ${_todayAttendance?.checkInTime != null}');
    }

    // Load stats
    await _loadStats();

    print('DEBUG HOME: Data reload completed');
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
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsLokin.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Ya, Yakin'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorsLokin.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppColorsLokin.success,
                size: 48,
              ),
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
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColorsLokin.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsLokin.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColorsLokin.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColorsLokin.primary,
            AppColorsLokin.darker(AppColorsLokin.primary, 0.2),
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
                      _getGreeting(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  Widget _buildAttendanceStatus() {
    final hasCheckedIn = _todayAttendance?.checkInTime != null;
    final hasCheckedOut = _todayAttendance?.checkOutTime != null;
    final isPermission = _todayAttendance?.status == 'izin';

    print(
        'DEBUG: Building attendance status - hasCheckedIn: $hasCheckedIn, hasCheckedOut: $hasCheckedOut, isPermission: $isPermission');

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

    print(
        'DEBUG: Building action buttons - hasCheckedIn: $hasCheckedIn, hasCheckedOut: $hasCheckedOut, isPermission: $isPermission, isLoading: $_isLoading');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (!isPermission) ...[
            if (!hasCheckedIn) ...[
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColorsLokin.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _handleCheckIn,
                        icon: const Icon(Icons.login, size: 20),
                        label: const Text('Absen Masuk'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorsLokin.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
            ],
            if (hasCheckedIn && !hasCheckedOut) ...[
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColorsLokin.error.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _handleCheckOut,
                        icon: const Icon(Icons.logout, size: 20),
                        label: const Text('Absen Keluar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorsLokin.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
            ],
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
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColorsLokin.success,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Anda sudah menyelesaikan absensi hari ini',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColorsLokin.success,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ] else ...[
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
                    child: Text(
                      'Anda sedang izin hari ini',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColorsLokin.warning,
                            fontWeight: FontWeight.w600,
                          ),
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

  Widget _buildStatsCard() {
    if (_stats == null) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
            'Statistik Bulan Ini',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColorsLokin.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.calendar_month,
                  title: 'Total Absen',
                  value: '${_stats?.totalAbsen ?? 0}',
                  color: AppColorsLokin.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle,
                  title: 'Hadir',
                  value: '${_stats?.totalMasuk ?? 0}',
                  color: AppColorsLokin.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.assignment,
                  title: 'Izin',
                  value: '${_stats?.totalIzin ?? 0}',
                  color: AppColorsLokin.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColorsLokin.textSecondary),
            textAlign: TextAlign.center,
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
