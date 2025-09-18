import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:lokinid_app/data/models/batch_model_lokin.dart';
import 'package:lokinid_app/data/models/training_model_lokin.dart';

import '../../core/constants/api_constants_lokin.dart';
import '../models/attendance_model_lokin.dart';
import '../models/stats_model_lokin.dart';
import '../models/user_model_lokin.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
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

  // AUTH ENDPOINTS

  /// Register user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required int trainingId,
    required int batchId,
    required String gender, // FIXED: Add gender parameter
  }) async {
    try {
      final url = '${ApiConstantsLokin.baseUrl}/register';
      final payload = {
        'name': name,
        'email': email,
        'password': password,
        'training_id': trainingId,
        'batch_id': batchId,
        'jenis_kelamin': gender, // FIXED: Use correct field name from API
      };

      // Debug logging
      print('=== REGISTER REQUEST ===');
      print('URL: $url');
      print('Headers: $_headers');
      print('Payload: ${jsonEncode(payload)}');

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      // Debug logging
      print('=== REGISTER RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Response Headers: ${response.headers}');

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      print('Registration error: $e');
      throw Exception('Gagal melakukan registrasi: ${e.toString()}');
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = '${ApiConstantsLokin.baseUrl}/login';
      final payload = {
        'email': email,
        'password': password,
      };

      print('=== LOGIN REQUEST ===');
      print('URL: $url');
      print('Payload: ${jsonEncode(payload)}');

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      print('=== LOGIN RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      print('Login error: $e');
      throw Exception('Gagal melakukan login: ${e.toString()}');
    }
  }

  /// Request OTP for forgot password
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstantsLokin.baseUrl}/forgot-password'),
            headers: _headers,
            body: jsonEncode({
              'email': email,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Reset password with OTP
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstantsLokin.baseUrl}/reset-password'),
            headers: _headers,
            body: jsonEncode({
              'email': email,
              'otp': otp,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ATTENDANCE ENDPOINTS

  /// Check in attendance
  Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstantsLokin.baseUrl}/absen/check-in'),
            headers: _headers,
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
              'address': address,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Check out attendance
  Future<Map<String, dynamic>> checkOut({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstantsLokin.baseUrl}/absen/check-out'),
            headers: _headers,
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
              'address': address,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Submit permission/izin
  Future<Map<String, dynamic>> submitPermission({
    required String date,
    required String reason,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstantsLokin.baseUrl}/izin'),
            headers: _headers,
            body: jsonEncode({
              'attendance_date': date,
              'alasan_izin': reason,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get today's attendance
  Future<AttendanceResponseLokin> getTodayAttendance(String date) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '${ApiConstantsLokin.baseUrl}/absen/today?attendance_date=$date'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      final data = _handleResponse(response);
      return AttendanceResponseLokin.fromJson(data);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get attendance statistics
  Future<StatsResponse> getStats({String? start, String? end}) async {
    try {
      String url = '${ApiConstantsLokin.baseUrl}/absen/stats';
      if (start != null && end != null) {
        url += '?start=$start&end=$end';
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      final data = _handleResponse(response);
      return StatsResponse.fromJson(data);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get attendance history
  Future<Map<String, dynamic>> getAttendanceHistory({
    String? start,
    String? end,
  }) async {
    try {
      String url = '${ApiConstantsLokin.baseUrl}/absen/history';
      if (start != null && end != null) {
        url += '?start=$start&end=$end';
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Delete attendance
  Future<Map<String, dynamic>> deleteAttendance(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConstantsLokin.baseUrl}/absen/$id'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // PROFILE ENDPOINTS

  /// Get user profile
  Future<UserResponseLokin> getProfile() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConstantsLokin.baseUrl}/profile'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      final data = _handleResponse(response);
      return UserResponseLokin.fromJson(data);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Update profile
  Future<Map<String, dynamic>> updateProfile({
    required String name,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConstantsLokin.baseUrl}/profile'),
            headers: _headers,
            body: jsonEncode({
              'name': name,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Update profile photo
  Future<Map<String, dynamic>> updateProfilePhoto(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiConstantsLokin.baseUrl}/profile/photo'),
      );

      // Add authorization header
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_photo',
          imageFile.path,
        ),
      );

      var streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
      var response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Save device token for push notifications
  Future<Map<String, dynamic>> saveDeviceToken(String deviceToken) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstantsLokin.baseUrl}/device-token'),
            headers: _headers,
            body: jsonEncode({
              'player_id': deviceToken,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get all users (if needed)
  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConstantsLokin.baseUrl}/users'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get list of trainings
  Future<TrainingResponse> getTrainings() async {
    try {
      final url = '${ApiConstantsLokin.baseUrl}/trainings';
      print('Getting trainings from: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      print('Trainings response status: ${response.statusCode}');
      print('Trainings response body: ${response.body}');

      final data = _handleResponse(response);
      return TrainingResponse.fromJson(data);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      print('Get trainings error: $e');
      throw Exception('Gagal memuat data pelatihan: ${e.toString()}');
    }
  }

  /// Get training detail by ID
  Future<TrainingDetailResponse> getTrainingDetail(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConstantsLokin.baseUrl}/trainings/$id'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      final data = _handleResponse(response);
      return TrainingDetailResponse.fromJson(data);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get all batches
  Future<BatchResponse> getBatches() async {
    try {
      final url = '${ApiConstantsLokin.baseUrl}/batches';
      print('Getting batches from: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      print('Batches response status: ${response.statusCode}');
      print('Batches response body: ${response.body}');

      final data = _handleResponse(response);
      return BatchResponse.fromJson(data);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      print('Get batches error: $e');
      throw Exception('Gagal memuat data batch: ${e.toString()}');
    }
  }

  // PRIVATE HELPER METHOD
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Check if response body is empty
      if (response.body.isEmpty) {
        throw Exception('Server mengembalikan response kosong');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        // Handle different error status codes
        switch (response.statusCode) {
          case 400:
            throw Exception(data['message'] ?? 'Bad Request');
          case 401:
            throw Exception(data['message'] ?? 'Tidak terauthorisasi');
          case 403:
            throw Exception(data['message'] ?? 'Akses ditolak');
          case 404:
            throw Exception(data['message'] ?? 'Endpoint tidak ditemukan');
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
            throw Exception(data['message'] ?? 'Data tidak valid');
          case 500:
            throw Exception(data['message'] ?? 'Terjadi kesalahan pada server');
          default:
            throw Exception(data['message'] ?? 'Unknown error occurred');
        }
      }
    } on FormatException {
      throw Exception('Format response tidak valid dari server');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to parse response: $e');
    }
  }
}
