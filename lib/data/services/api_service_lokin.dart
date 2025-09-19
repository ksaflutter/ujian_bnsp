import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants_lokin.dart';
import '../../core/utils/date_helper_lokin.dart';
import '../models/attendance_model_lokin.dart';
import '../models/batch_model_lokin.dart';
import '../models/stats_model_lokin.dart';
import '../models/training_model_lokin.dart';
import '../models/user_model_lokin.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String token) {
    _token = token;
    print('=== API TOKEN SET ===');
    print('Token: $_token');
  }

  void clearToken() {
    _token = null;
    print('=== API TOKEN CLEARED ===');
  }

  Map<String, String> get _headers {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // Enhanced timeout and retry mechanism
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _maxRetries = 2;

  Future<T> _executeRequest<T>(
    Future<http.Response> Function() request,
    T Function(Map<String, dynamic>) parser, {
    Duration? timeout,
    int maxRetries = _maxRetries,
  }) async {
    timeout ??= _defaultTimeout;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('=== API REQUEST ATTEMPT $attempt ===');

        final response = await request().timeout(timeout);
        final data = _handleResponse(response);

        return parser(data);
      } on SocketException catch (e) {
        print('SocketException on attempt $attempt: $e');
        if (attempt == maxRetries) {
          throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
        }
        await Future.delayed(Duration(seconds: attempt)); // Progressive delay
      } on TimeoutException catch (e) {
        print('TimeoutException on attempt $attempt: $e');
        if (attempt == maxRetries) {
          throw Exception('Koneksi timeout. Coba lagi nanti.');
        }
        await Future.delayed(Duration(seconds: attempt)); // Progressive delay
      } on HttpException catch (e) {
        print('HttpException on attempt $attempt: $e');
        throw Exception('HTTP error: $e');
      } catch (e) {
        print('Generic error on attempt $attempt: $e');
        if (attempt == maxRetries) {
          throw Exception('Network error: $e');
        }
        await Future.delayed(Duration(seconds: attempt)); // Progressive delay
      }
    }

    throw Exception('All retry attempts failed');
  }

  // AUTH ENDPOINTS

  /// Register user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required int trainingId,
    required int batchId,
    required String gender,
  }) async {
    return await _executeRequest(
      () => http.post(
        Uri.parse('${ApiConstantsLokin.baseUrl}/register'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'training_id': trainingId,
          'batch_id': batchId,
          'jenis_kelamin': gender,
        }),
      ),
      (data) => data,
    );
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await _executeRequest(
      () => http.post(
        Uri.parse('${ApiConstantsLokin.baseUrl}/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ),
      (data) => data,
    );
  }

  /// Request OTP for forgot password
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    return await _executeRequest(
      () => http.post(
        Uri.parse('${ApiConstantsLokin.baseUrl}/forgot-password'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
        }),
      ),
      (data) => data,
    );
  }

  /// Reset password with OTP
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    return await _executeRequest(
      () => http.post(
        Uri.parse('${ApiConstantsLokin.baseUrl}/reset-password'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'password': password,
        }),
      ),
      (data) => data,
    );
  }

  // ATTENDANCE ENDPOINTS

  /// Check in attendance
  Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    // Get current date and time in correct API format
    final now = DateTime.now();
    final attendanceDate = DateHelperLokin.formatDateForApi(now);
    final checkInTime =
        DateHelperLokin.formatTime(now); // Format: HH:mm (e.g., "22:52")
    final checkInLocation = "$latitude,$longitude";

    final payload = {
      'attendance_date': attendanceDate,
      'check_in': checkInTime, // Format: HH:mm (e.g., "22:52")
      'check_in_lat': latitude,
      'check_in_lng': longitude,
      'check_in_location': checkInLocation, // Format: lat,lng
      'check_in_address': address,
    };

    print('=== API checkIn START ===');
    print('URL: ${ApiConstantsLokin.baseUrl}/absen/check-in');
    print('Headers: $_headers');
    print('Payload: ${jsonEncode(payload)}');

    return await _executeRequest(
      () => http.post(
        Uri.parse('${ApiConstantsLokin.baseUrl}/absen/check-in'),
        headers: _headers,
        body: jsonEncode(payload),
      ),
      (data) {
        print('=== API checkIn SUCCESS ===');
        print('Response data: $data');
        return data;
      },
      timeout: const Duration(seconds: 45), // Increased timeout for attendance
    );
  }

  /// Check out attendance
  Future<Map<String, dynamic>> checkOut({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    // Get current date and time in correct API format
    final now = DateTime.now();
    final attendanceDate = DateHelperLokin.formatDateForApi(now);
    final checkOutTime =
        DateHelperLokin.formatTime(now); // Format: HH:mm (e.g., "22:52")
    final checkOutLocation = "$latitude,$longitude";

    final payload = {
      'attendance_date': attendanceDate,
      'check_out': checkOutTime, // Format: HH:mm (e.g., "22:52")
      'check_out_lat': latitude,
      'check_out_lng': longitude,
      'check_out_location': checkOutLocation, // Format: lat,lng
      'check_out_address': address,
    };

    print('=== API checkOut START ===');
    print('URL: ${ApiConstantsLokin.baseUrl}/absen/check-out');
    print('Headers: $_headers');
    print('Payload: ${jsonEncode(payload)}');

    return await _executeRequest(
      () => http.post(
        Uri.parse('${ApiConstantsLokin.baseUrl}/absen/check-out'),
        headers: _headers,
        body: jsonEncode(payload),
      ),
      (data) {
        print('=== API checkOut SUCCESS ===');
        print('Response data: $data');
        return data;
      },
      timeout: const Duration(seconds: 45), // Increased timeout for attendance
    );
  }

  /// Submit permission/izin
  Future<Map<String, dynamic>> submitPermission({
    required String date,
    required String reason,
  }) async {
    return await _executeRequest(
      () => http.post(
        Uri.parse('${ApiConstantsLokin.baseUrl}/izin'),
        headers: _headers,
        body: jsonEncode({
          'attendance_date': date,
          'alasan_izin': reason,
        }),
      ),
      (data) => data,
    );
  }

  /// Get today's attendance
  Future<AttendanceResponseLokin> getTodayAttendance(String? date) async {
    // Use provided date or get current date in API format
    final todayDate = date ?? DateHelperLokin.getCurrentDateForApi();

    return await _executeRequest(
      () => http.get(
        Uri.parse(
            '${ApiConstantsLokin.baseUrl}/absen/today?attendance_date=$todayDate'),
        headers: _headers,
      ),
      (data) => AttendanceResponseLokin.fromJson(data),
    );
  }

  /// Get attendance statistics
  Future<StatsResponse> getStats({String? start, String? end}) async {
    String url = '${ApiConstantsLokin.baseUrl}/absen/stats';
    if (start != null && end != null) {
      url += '?start=$start&end=$end';
    }

    return await _executeRequest(
      () => http.get(
        Uri.parse(url),
        headers: _headers,
      ),
      (data) => StatsResponse.fromJson(data),
    );
  }

  /// Get attendance history
  Future<Map<String, dynamic>> getAttendanceHistory({
    String? start,
    String? end,
  }) async {
    String url = '${ApiConstantsLokin.baseUrl}/absen/history';
    if (start != null && end != null) {
      url += '?start=$start&end=$end';
    }

    return await _executeRequest(
      () => http.get(
        Uri.parse(url),
        headers: _headers,
      ),
      (data) => data,
    );
  }

  /// Delete attendance
  Future<Map<String, dynamic>> deleteAttendance(int id) async {
    return await _executeRequest(
      () => http.delete(
        Uri.parse('${ApiConstantsLokin.baseUrl}/absen/$id'),
        headers: _headers,
      ),
      (data) => data,
    );
  }

  // PROFILE ENDPOINTS

  /// Get user profile
  Future<UserResponseLokin> getProfile() async {
    return await _executeRequest(
      () => http.get(
        Uri.parse('${ApiConstantsLokin.baseUrl}/profile'),
        headers: _headers,
      ),
      (data) => UserResponseLokin.fromJson(data),
    );
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String name,
  }) async {
    return await _executeRequest(
      () => http.put(
        Uri.parse('${ApiConstantsLokin.baseUrl}/profile'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
        }),
      ),
      (data) => data,
    );
  }

  /// Update profile photo
  Future<Map<String, dynamic>> updateProfilePhoto(
    File file, {
    required String photoPath,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiConstantsLokin.baseUrl}/profile/photo'),
      );

      // Add headers (without Content-Type as it's set automatically for multipart)
      Map<String, String> requestHeaders = {
        'Accept': 'application/json',
      };
      if (_token != null) {
        requestHeaders['Authorization'] = 'Bearer $_token';
      }
      request.headers.addAll(requestHeaders);

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('profile_photo', photoPath),
      );

      final streamedResponse = await request.send().timeout(_defaultTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // TRAINING & BATCH ENDPOINTS

  /// Get list of trainings
  Future<TrainingResponse> getTrainings() async {
    return await _executeRequest(
      () => http.get(
        Uri.parse('${ApiConstantsLokin.baseUrl}/trainings'),
        headers: _headers,
      ),
      (data) => TrainingResponse.fromJson(data),
    );
  }

  /// Get training detail by ID
  Future<TrainingDetailResponse> getTrainingDetail(int id) async {
    return await _executeRequest(
      () => http.get(
        Uri.parse('${ApiConstantsLokin.baseUrl}/trainings/$id'),
        headers: _headers,
      ),
      (data) => TrainingDetailResponse.fromJson(data),
    );
  }

  /// Get all batches
  Future<BatchResponse> getBatches(int trainingId) async {
    return await _executeRequest(
      () => http.get(
        Uri.parse('${ApiConstantsLokin.baseUrl}/batches'),
        headers: _headers,
      ),
      (data) => BatchResponse.fromJson(data),
    );
  }

  /// Get all users (if needed)
  Future<Map<String, dynamic>> getAllUsers() async {
    return await _executeRequest(
      () => http.get(
        Uri.parse('${ApiConstantsLokin.baseUrl}/users'),
        headers: _headers,
      ),
      (data) => data,
    );
  }

  // PRIVATE HELPER METHOD
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      print('=== API RESPONSE ===');
      print('Status code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      // Check if response body is empty
      if (response.body.isEmpty) {
        throw Exception('Server mengembalikan response kosong');
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        throw Exception(
            'Response tidak dalam format JSON yang valid: ${response.body}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        // Handle different error status codes
        String errorMessage =
            data['message'] ?? 'Terjadi kesalahan pada server';

        switch (response.statusCode) {
          case 400:
            throw Exception(errorMessage);
          case 401:
            throw Exception('Sesi sudah berakhir. Silakan login kembali.');
          case 403:
            throw Exception('Akses ditolak: $errorMessage');
          case 404:
            throw Exception('Endpoint tidak ditemukan: $errorMessage');
          case 422:
            // Validation errors
            if (data['errors'] != null) {
              final errors = data['errors'] as Map<String, dynamic>;
              final errorMessages = <String>[];
              errors.forEach((key, value) {
                if (value is List) {
                  errorMessages.addAll(value.map((e) => e.toString()));
                } else {
                  errorMessages.add(value.toString());
                }
              });
              throw Exception(errorMessages.join('\n'));
            }
            throw Exception(errorMessage);
          case 429:
            throw Exception('Terlalu banyak permintaan. Coba lagi nanti.');
          case 500:
            throw Exception('Terjadi kesalahan pada server. Coba lagi nanti.');
          case 502:
            throw Exception('Server sedang bermasalah. Coba lagi nanti.');
          case 503:
            throw Exception(
                'Server sedang dalam pemeliharaan. Coba lagi nanti.');
          case 504:
            throw Exception('Server timeout. Coba lagi nanti.');
          default:
            throw Exception('Error ${response.statusCode}: $errorMessage');
        }
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Error memproses response: $e');
      }
    }
  }

  // Health check method
  Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstantsLokin.baseUrl}/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  Future saveDeviceToken(String deviceToken) async {}
}
