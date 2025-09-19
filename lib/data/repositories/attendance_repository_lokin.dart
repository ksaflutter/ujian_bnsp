import '../../core/utils/date_helper_lokin.dart';
import '../models/attendance_model_lokin.dart';
import '../models/stats_model_lokin.dart';
import '../services/api_service_lokin.dart';

class AttendanceRepository {
  final ApiService _apiService = ApiService();

  static final AttendanceRepository _instance =
      AttendanceRepository._internal();
  factory AttendanceRepository() => _instance;
  AttendanceRepository._internal();

  /// Check in attendance
  Future<AttendanceResult> checkIn({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      final response = await _apiService.checkIn(
        latitude: latitude,
        longitude: longitude,
        address: address,
      );

      if (response['data'] != null) {
        return AttendanceResult.success(
          message: response['message'] ?? 'Absen masuk berhasil',
          data: response['data'],
        );
      } else {
        return AttendanceResult.failure(
          message: response['message'] ?? 'Absen masuk gagal',
        );
      }
    } catch (e) {
      return AttendanceResult.failure(message: e.toString());
    }
  }

  /// Check out attendance
  Future<AttendanceResult> checkOut({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      final response = await _apiService.checkOut(
        latitude: latitude,
        longitude: longitude,
        address: address,
      );

      if (response['data'] != null) {
        return AttendanceResult.success(
          message: response['message'] ?? 'Absen keluar berhasil',
          data: response['data'],
        );
      } else {
        return AttendanceResult.failure(
          message: response['message'] ?? 'Absen keluar gagal',
        );
      }
    } catch (e) {
      return AttendanceResult.failure(message: e.toString());
    }
  }

  /// Submit permission/izin - PERBAIKAN: Menambahkan logging dan validation
  Future<AttendanceResult> submitPermission({
    required String date,
    required String reason,
  }) async {
    try {
      print('=== ATTENDANCE REPOSITORY: submitPermission ===');
      print('Date parameter: $date');
      print('Reason parameter: $reason');

      // Validate parameters before sending to API
      if (date.isEmpty) {
        print('ERROR: Date is empty');
        return AttendanceResult.failure(
          message: 'Tanggal wajib diisi',
        );
      }

      if (reason.isEmpty) {
        print('ERROR: Reason is empty');
        return AttendanceResult.failure(
          message: 'Alasan wajib diisi',
        );
      }

      // Validate date format (should be yyyy-MM-dd)
      try {
        DateTime.parse(date);
      } catch (e) {
        print('ERROR: Invalid date format: $date');
        return AttendanceResult.failure(
          message: 'Format tanggal tidak valid',
        );
      }

      print('Calling API service submitPermission...');
      final response = await _apiService.submitPermission(
        date: date,
        reason: reason,
      );

      print('API response received: $response');

      if (response['message'] != null) {
        // Check if response indicates success
        final message = response['message'].toString().toLowerCase();
        if (message.contains('berhasil') || message.contains('success')) {
          return AttendanceResult.success(
            message: response['message'] ?? 'Izin berhasil diajukan',
            data: response['data'],
          );
        }
      }

      // Handle error response
      return AttendanceResult.failure(
        message: response['message'] ?? 'Pengajuan izin gagal',
      );
    } catch (e) {
      print('ERROR in submitPermission: $e');
      return AttendanceResult.failure(
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

  /// Get today's attendance - PERBAIKAN: Menggunakan format API yang benar
  Future<AttendanceResult> getTodayAttendance([String? date]) async {
    try {
      // PERBAIKAN: Gunakan formatDateForApi() bukan formatDate()
      final targetDate =
          date ?? DateHelperLokin.formatDateForApi(DateTime.now());

      print(
          'DEBUG ATTENDANCE REPO: Calling getTodayAttendance with date: $targetDate');

      final response = await _apiService.getTodayAttendance(targetDate);

      print('DEBUG ATTENDANCE REPO: API response: ${response.message}');
      print('DEBUG ATTENDANCE REPO: API data: ${response.data?.toJson()}');

      return AttendanceResult.success(
        message: response.message,
        attendance: response.data,
      );
    } catch (e) {
      print('DEBUG ATTENDANCE REPO: Error in getTodayAttendance: $e');
      return AttendanceResult.failure(message: e.toString());
    }
  }

  /// Get attendance statistics
  Future<StatsResult> getStats({String? start, String? end}) async {
    try {
      final response = await _apiService.getStats(start: start, end: end);

      return StatsResult.success(
        message: response.message,
        stats: response.data,
      );
    } catch (e) {
      return StatsResult.failure(message: e.toString());
    }
  }

  /// Get attendance history
  Future<AttendanceHistoryResult> getAttendanceHistory({
    String? start,
    String? end,
  }) async {
    try {
      final response = await _apiService.getAttendanceHistory(
        start: start,
        end: end,
      );

      if (response['data'] != null) {
        final List<dynamic> dataList = response['data'];
        final List<AttendanceModelLokin> attendances = dataList
            .map((json) => AttendanceModelLokin.fromJson(json))
            .toList();

        return AttendanceHistoryResult.success(
          message: response['message'] ?? 'Berhasil mengambil riwayat absensi',
          attendances: attendances,
        );
      } else {
        return AttendanceHistoryResult.success(
          message: response['message'] ?? 'Tidak ada riwayat absensi',
          attendances: [],
        );
      }
    } catch (e) {
      return AttendanceHistoryResult.failure(message: e.toString());
    }
  }

  /// Delete attendance record
  Future<AttendanceResult> deleteAttendance(int id) async {
    try {
      final response = await _apiService.deleteAttendance(id);

      return AttendanceResult.success(
        message: response['message'] ?? 'Data absen berhasil dihapus',
        data: response['data'],
      );
    } catch (e) {
      return AttendanceResult.failure(message: e.toString());
    }
  }

  /// Check if user can check in today
  Future<bool> canCheckInToday() async {
    try {
      final result = await getTodayAttendance();
      if (result.isSuccess && result.attendance != null) {
        final attendance = result.attendance!;
        // Can check in if no attendance record or not checked in yet
        return attendance.checkInTime == null;
      }
      return true; // Allow check-in if no record found
    } catch (e) {
      return true; // Allow check-in on error (fail-safe)
    }
  }

  /// Check if user can check out today
  Future<bool> canCheckOutToday() async {
    try {
      final result = await getTodayAttendance();
      if (result.isSuccess && result.attendance != null) {
        final attendance = result.attendance!;
        // Can check out if checked in but not checked out yet
        return attendance.checkInTime != null &&
            attendance.checkOutTime == null;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has submitted permission today
  Future<bool> hasPermissionToday() async {
    try {
      final result = await getTodayAttendance();
      if (result.isSuccess && result.attendance != null) {
        return result.attendance!.status == 'izin';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// PERBAIKAN: Method untuk force refresh today attendance dengan debug
  Future<AttendanceResult> forceRefreshTodayAttendance() async {
    try {
      final today = DateTime.now();
      final todayFormatted = DateHelperLokin.formatDateForApi(today);

      print(
          'DEBUG FORCE REFRESH: Today date formatted for API: $todayFormatted');
      print(
          'DEBUG FORCE REFRESH: Current date: ${DateHelperLokin.formatDate(today)}');

      // Clear any cache if exists
      await Future.delayed(const Duration(milliseconds: 200));

      return await getTodayAttendance(todayFormatted);
    } catch (e) {
      print('DEBUG FORCE REFRESH: Error: $e');
      return AttendanceResult.failure(message: e.toString());
    }
  }
}

/// Result class for attendance operations
class AttendanceResult {
  final bool isSuccess;
  final String message;
  final AttendanceModelLokin? attendance;
  final dynamic data;

  AttendanceResult._({
    required this.isSuccess,
    required this.message,
    this.attendance,
    this.data,
  });

  factory AttendanceResult.success({
    required String message,
    AttendanceModelLokin? attendance,
    dynamic data,
  }) {
    return AttendanceResult._(
      isSuccess: true,
      message: message,
      attendance: attendance,
      data: data,
    );
  }

  factory AttendanceResult.failure({required String message}) {
    return AttendanceResult._(isSuccess: false, message: message);
  }
}

/// Result class for stats operations
class StatsResult {
  final bool isSuccess;
  final String message;
  final StatsModel? stats;

  StatsResult._({required this.isSuccess, required this.message, this.stats});

  factory StatsResult.success({required String message, StatsModel? stats}) {
    return StatsResult._(isSuccess: true, message: message, stats: stats);
  }

  factory StatsResult.failure({required String message}) {
    return StatsResult._(isSuccess: false, message: message);
  }
}

/// Result class for attendance history operations
class AttendanceHistoryResult {
  final bool isSuccess;
  final String message;
  final List<AttendanceModelLokin> attendances;

  AttendanceHistoryResult._({
    required this.isSuccess,
    required this.message,
    required this.attendances,
  });

  factory AttendanceHistoryResult.success({
    required String message,
    required List<AttendanceModelLokin> attendances,
  }) {
    return AttendanceHistoryResult._(
      isSuccess: true,
      message: message,
      attendances: attendances,
    );
  }

  factory AttendanceHistoryResult.failure({required String message}) {
    return AttendanceHistoryResult._(
      isSuccess: false,
      message: message,
      attendances: [],
    );
  }
}
