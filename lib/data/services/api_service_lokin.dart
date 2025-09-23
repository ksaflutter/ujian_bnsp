import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:lokinid_app/data/models/batch_model_lokin.dart';
import 'package:lokinid_app/data/models/training_model_lokin.dart';

import '../../core/constants/api_constants_lokin.dart';
import '../../core/utils/date_helper_lokin.dart';
import '../models/attendance_model_lokin.dart';
import '../models/stats_model_lokin.dart';
import '../models/user_model_lokin.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  static const Duration _defaultTimeout = Duration(seconds: 30);

  /// Headers
  Map<String, String> get _headers {
    Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  /// Set authentication token
  void setToken(String token) {
    _token = token;
    print('API Service: Token set');
  }

  /// Clear authentication token
  void clearToken() {
    _token = null;
    print('API Service: Token cleared');
  }

  /// Get current token
  String? get currentToken => _token;

  // AUTHENTICATION ENDPOINTS

  /// PERBAIKAN: Register new user dengan profilePhoto parameter
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required int trainingId,
    required int batchId,
    required String gender,
    String? profilePhoto, // TAMBAHAN: Parameter profilePhoto
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
          'jenis_kelamin':
              gender, // PERBAIKAN: Gunakan jenis_kelamin sesuai API
          if (profilePhoto != null)
            'profile_photo': profilePhoto, // TAMBAHAN: profile_photo jika ada
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

  /// Forgot password
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    return await _executeRequest(
      () => http.post(
        Uri.parse('${ApiConstantsLokin.baseUrl}/forgot-password'),
        headers: _headers,
        body: jsonEncode({'email': email}),
      ),
      (data) => data,
    );
  }

  /// Reset password
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

  /// Get trainings
  Future<TrainingResponseLokin> getTrainings() async {
    return await _executeRequest(
      () => http.get(
        Uri.parse('${ApiConstantsLokin.baseUrl}/trainings'),
        headers: _headers,
      ),
      (data) => TrainingResponseLokin.fromJson(data),
    );
  }

  /// Get batches by training ID - YANG LAMA (masih dipertahankan untuk compatibility)
  Future<BatchResponseLokin> getBatches(int trainingId) async {
    return await _executeRequest(
      () => http.get(
        Uri.parse('${ApiConstantsLokin.baseUrl}/batches/$trainingId'),
        headers: _headers,
      ),
      (data) => BatchResponseLokin.fromJson(data),
    );
  }

  /// PERBAIKAN: Get all batches tanpa parameter (public endpoint)
  Future<BatchResponseLokin> getBatchesPublic() async {
    return await _executeRequest(
      () => http.get(
        Uri.parse('${ApiConstantsLokin.baseUrl}/batches'),
        headers: _headers,
      ),
      (data) => BatchResponseLokin.fromJson(data),
    );
  }

  /// Save device token
  Future<Map<String, dynamic>> saveDeviceToken(String deviceToken) async {
    return await _executeRequest(
      () => http.post(
        Uri.parse('${ApiConstantsLokin.baseUrl}/save-device-token'),
        headers: _headers,
        body: jsonEncode({'device_token': deviceToken}),
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
    final now = DateTime.now();
    final attendanceDate = DateHelperLokin.formatDateForApi(now);
    final checkInTime = DateHelperLokin.formatTime(now);
    final checkInLocation = "$latitude,$longitude";

    final payload = {
      'attendance_date': attendanceDate,
      'check_in': checkInTime, // Format: HH:mm (e.g., "08:15")
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
    final now = DateTime.now();
    final attendanceDate = DateHelperLokin.formatDateForApi(now);
    final checkOutTime = DateHelperLokin.formatTime(now);
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

  /// Submit permission/izin - TETAP SAMA SEPERTI YANG SUDAH BEKERJA
  Future<Map<String, dynamic>> submitPermission({
    required String date,
    required String reason,
  }) async {
    print('=== API submitPermission START ===');
    print('URL: ${ApiConstantsLokin.baseUrl}/izin');
    print('Headers: $_headers');
    print('Input date: $date');
    print('Input reason: $reason');

    // PERBAIKAN: Coba format pertama berdasarkan error message API
    Map<String, dynamic> payload1 = {
      'date': date,
      'reason': reason,
    };

    print('Trying payload 1: ${jsonEncode(payload1)}');

    try {
      final response1 = await http
          .post(
            Uri.parse('${ApiConstantsLokin.baseUrl}/izin'),
            headers: _headers,
            body: jsonEncode(payload1),
          )
          .timeout(const Duration(seconds: 30));

      print('=== API RESPONSE ATTEMPT 1 ===');
      print('Status Code: ${response1.statusCode}');
      print('Body: ${response1.body}');

      if (response1.statusCode == 200 || response1.statusCode == 201) {
        final data = _handleResponse(response1);
        print('=== API submitPermission SUCCESS (attempt 1) ===');
        print('Response data: $data');
        return data;
      }
    } catch (e) {
      print('Attempt 1 failed: $e');
    }

    // PERBAIKAN: Jika gagal, coba format kedua
    Map<String, dynamic> payload2 = {
      'attendance_date': date,
      'alasan_izin': reason,
    };

    print('Trying payload 2: ${jsonEncode(payload2)}');

    try {
      final response2 = await http
          .post(
            Uri.parse('${ApiConstantsLokin.baseUrl}/izin'),
            headers: _headers,
            body: jsonEncode(payload2),
          )
          .timeout(const Duration(seconds: 30));

      print('=== API RESPONSE ATTEMPT 2 ===');
      print('Status Code: ${response2.statusCode}');
      print('Body: ${response2.body}');

      if (response2.statusCode == 200 || response2.statusCode == 201) {
        final data = _handleResponse(response2);
        print('=== API submitPermission SUCCESS (attempt 2) ===');
        print('Response data: $data');
        return data;
      }
    } catch (e) {
      print('Attempt 2 failed: $e');
    }

    // PERBAIKAN: Coba format ketiga dengan kombinasi fields
    Map<String, dynamic> payload3 = {
      'date': date,
      'attendance_date': date,
      'reason': reason,
      'alasan_izin': reason,
    };

    print('Trying payload 3: ${jsonEncode(payload3)}');

    return await _executeRequest(
      () => http.post(
        Uri.parse('${ApiConstantsLokin.baseUrl}/izin'),
        headers: _headers,
        body: jsonEncode(payload3),
      ),
      (data) {
        print('=== API submitPermission SUCCESS (attempt 3) ===');
        print('Response data: $data');
        return data;
      },
      timeout: const Duration(seconds: 30),
    );
  }

  /// Get today's attendance
  Future<AttendanceResponseLokin> getTodayAttendance(String? date) async {
    // Use provided date or get current date in API format
    final todayDate = date ?? DateHelperLokin.formatDateForApi(DateTime.now());

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

  // TETAP SAMA - Update profile photo yang sudah bekerja
  Future<Map<String, dynamic>> updateProfilePhoto(
    File file, {
    required String photoPath,
  }) async {
    try {
      print('=== UPDATE PROFILE PHOTO (Base64 Approach) ===');
      print('File path: $photoPath');

      // Baca file sebagai bytes
      final bytes = await file.readAsBytes();
      print('File size: ${bytes.length} bytes');

      // Convert ke base64
      final base64String = base64Encode(bytes);
      print('Base64 length: ${base64String.length}');

      // Tentukan mime type
      String mimeType = 'image/jpeg';
      final extension = photoPath.toLowerCase().split('.').last;
      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      }

      // Format data URL
      final dataUrl = 'data:$mimeType;base64,$base64String';
      print('Data URL prefix: data:$mimeType;base64,...');

      // Kirim sebagai JSON POST request
      return await _executeRequest(
        () => http.put(
          Uri.parse('${ApiConstantsLokin.baseUrl}/profile/photo'),
          headers: _headers,
          body: jsonEncode({
            'profile_photo': dataUrl,
          }),
        ),
        (data) => data,
      );
    } catch (e) {
      print('Error in updateProfilePhoto: $e');
      throw Exception('Gagal upload foto: $e');
    }
  }

  Future<Map<String, dynamic>> saveDeviceTokenV2(String deviceToken) async {
    return await _executeRequest(
      () => http.post(
        Uri.parse('${ApiConstantsLokin.baseUrl}/device-token'),
        headers: _headers,
        body: jsonEncode({
          'player_id': deviceToken,
        }),
      ),
      (data) => data,
    );
  }

  // HELPER METHODS

  /// Execute HTTP request with error handling and response parsing
  Future<T> _executeRequest<T>(
    Future<http.Response> Function() request,
    T Function(Map<String, dynamic>) parser, {
    Duration? timeout,
  }) async {
    try {
      print('=== API REQUEST START ===');

      final response = await request().timeout(timeout ?? _defaultTimeout);

      print('=== API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      final responseData = _handleResponse(response);

      print('=== PARSED RESPONSE ===');
      print('Data: $responseData');

      return parser(responseData);
    } on SocketException {
      print('=== NETWORK ERROR ===');
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      print('=== TIMEOUT ERROR ===');
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } on FormatException catch (e) {
      print('=== FORMAT ERROR ===');
      print('Error: $e');
      throw Exception('Format response tidak valid dari server');
    } catch (e) {
      print('=== UNKNOWN ERROR ===');
      print('Error: $e');
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Handle HTTP response and parse JSON
  Map<String, dynamic> _handleResponse(http.Response response) {
    print('=== HANDLING RESPONSE ===');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      switch (response.statusCode) {
        case 200:
        case 201:
          print('=== SUCCESS RESPONSE ===');
          return data;
        case 400:
          print('=== BAD REQUEST ===');
          throw Exception(data['message'] ?? 'Data tidak valid');
        case 401:
          print('=== UNAUTHORIZED ===');
          throw Exception(data['message'] ?? 'Token tidak valid atau expired');
        case 403:
          print('=== FORBIDDEN ===');
          throw Exception(data['message'] ?? 'Akses ditolak');
        case 404:
          print('=== NOT FOUND ===');
          throw Exception(data['message'] ?? 'Data tidak ditemukan');
        case 422:
          print('=== VALIDATION ERROR ===');
          // Handle validation errors specifically
          if (data.containsKey('errors')) {
            final errors = data['errors'] as Map<String, dynamic>;
            final errorMessages = <String>[];
            errors.forEach((key, value) {
              if (value is List) {
                errorMessages.addAll(value.cast<String>());
              } else {
                errorMessages.add(value.toString());
              }
            });
            throw Exception(errorMessages.join('\n'));
          }
          throw Exception(data['message'] ?? 'Data tidak valid');
        case 500:
          print('=== INTERNAL SERVER ERROR ===');
          throw Exception(data['message'] ?? 'Terjadi kesalahan pada server');
        default:
          print('=== UNKNOWN STATUS CODE ===');
          throw Exception(data['message'] ?? 'Unknown error occurred');
      }
    } on FormatException {
      print('=== JSON PARSE ERROR ===');
      throw Exception('Format response tidak valid dari server');
    } catch (e) {
      print('=== RESPONSE HANDLING ERROR ===');
      print('Error: $e');
      if (e is Exception) rethrow;
      throw Exception('Failed to parse response: $e');
    }
  }
}

// Response model classes for complex responses
class UserResponseLokin {
  final String message;
  final UserModelLokin? data;

  UserResponseLokin({required this.message, this.data});

  factory UserResponseLokin.fromJson(Map<String, dynamic> json) {
    return UserResponseLokin(
      message: json['message'] ?? '',
      data: json['data'] != null ? UserModelLokin.fromJson(json['data']) : null,
    );
  }
}

class AttendanceResponseLokin {
  final String message;
  final AttendanceModelLokin? data;

  AttendanceResponseLokin({required this.message, this.data});

  factory AttendanceResponseLokin.fromJson(Map<String, dynamic> json) {
    return AttendanceResponseLokin(
      message: json['message'] ?? '',
      data: json['data'] != null
          ? AttendanceModelLokin.fromJson(json['data'])
          : null,
    );
  }
}

class StatsResponse {
  final String message;
  final StatsModel? data;

  StatsResponse({required this.message, this.data});

  factory StatsResponse.fromJson(Map<String, dynamic> json) {
    return StatsResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? StatsModel.fromJson(json['data']) : null,
    );
  }
}

class TrainingResponseLokin {
  final String message;
  final List<TrainingModel>? data;

  TrainingResponseLokin({required this.message, this.data});

  factory TrainingResponseLokin.fromJson(Map<String, dynamic> json) {
    return TrainingResponseLokin(
      message: json['message'] ?? '',
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) => TrainingModel.fromJson(item))
              .toList()
          : null,
    );
  }
}

class BatchResponseLokin {
  final String message;
  final List<BatchModel>? data;

  BatchResponseLokin({required this.message, this.data});

  factory BatchResponseLokin.fromJson(Map<String, dynamic> json) {
    return BatchResponseLokin(
      message: json['message'] ?? '',
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) => BatchModel.fromJson(item))
              .toList()
          : null,
    );
  }
}
