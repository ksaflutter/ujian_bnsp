import 'dart:io';

import '../models/user_model_lokin.dart';
import '../services/api_service_lokin.dart';
import '../services/preference_service_lokin.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();
  final PreferenceService _preferenceService = PreferenceService();

  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  AuthRepository._internal();

  /// Register new user
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required int trainingId,
    required int batchId,
    required String gender, // FIXED: Add gender parameter
  }) async {
    try {
      print('=== AUTH REPOSITORY REGISTER ===');
      print('Starting registration process...');

      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        trainingId: trainingId,
        batchId: batchId,
        gender: gender, // FIXED: Pass gender to API service
      );

      print('API response received: $response');

      if (response['data'] != null) {
        final token = response['data']['token'];
        final userData = response['data']['user'];

        print('Token received: ${token != null ? 'Yes' : 'No'}');
        print('User data received: ${userData != null ? 'Yes' : 'No'}');

        // Save token and user data
        await _preferenceService.saveToken(token);
        final user = UserModelLokin.fromJson(userData);
        await _preferenceService.saveUser(user);

        // Set token in API service
        _apiService.setToken(token);

        print('Registration successful for user: ${user.name}');

        return AuthResult.success(
          message: response['message'] ?? 'Registrasi berhasil',
          user: user,
          token: token,
        );
      } else {
        print('Registration failed - no data in response');
        return AuthResult.failure(
          message: response['message'] ?? 'Registrasi gagal',
          errors: response['errors'],
        );
      }
    } catch (e) {
      print('Registration exception in repository: $e');
      return AuthResult.failure(
        message: _getErrorMessage(e),
      );
    }
  }

  /// Login user
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      print('=== AUTH REPOSITORY LOGIN ===');
      print('Starting login process for: $email');

      final response = await _apiService.login(
        email: email,
        password: password,
      );

      print('Login API response received: $response');

      if (response['data'] != null) {
        final token = response['data']['token'];
        final userData = response['data']['user'];

        // Save token and user data
        await _preferenceService.saveToken(token);
        final user = UserModelLokin.fromJson(userData);
        await _preferenceService.saveUser(user);

        // Set token in API service
        _apiService.setToken(token);

        print('Login successful for user: ${user.name}');

        return AuthResult.success(
          message: response['message'] ?? 'Login berhasil',
          user: user,
          token: token,
        );
      } else {
        print('Login failed - no data in response');
        return AuthResult.failure(
          message: response['message'] ?? 'Login gagal',
        );
      }
    } catch (e) {
      print('Login exception in repository: $e');
      return AuthResult.failure(
        message: _getErrorMessage(e),
      );
    }
  }

  /// Request OTP for forgot password
  Future<AuthResult> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await _apiService.forgotPassword(email: email);

      return AuthResult.success(
        message: response['message'] ?? 'OTP berhasil dikirim ke email',
      );
    } catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e),
      );
    }
  }

  /// Reset password with OTP
  Future<AuthResult> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      final response = await _apiService.resetPassword(
        email: email,
        otp: otp,
        password: password,
      );

      return AuthResult.success(
        message: response['message'] ?? 'Password berhasil diperbarui',
      );
    } catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e),
      );
    }
  }

  /// Initialize authentication state
  Future<void> initAuth() async {
    try {
      await _preferenceService.init();
      final token = _preferenceService.getToken();
      if (token != null && token.isNotEmpty) {
        _apiService.setToken(token);
        print('Auth initialized with existing token');
      } else {
        print('No existing token found');
      }
    } catch (e) {
      print('Error initializing auth: $e');
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _preferenceService.isLoggedIn;

  /// Get current user
  UserModelLokin? get currentUser => _preferenceService.getUser();

  /// Get current token
  String? get currentToken => _preferenceService.getToken();

  /// Logout user
  Future<void> logout() async {
    try {
      // Clear token from API service
      _apiService.clearToken();

      // Clear all user data from preferences
      await _preferenceService.clearAllUserData();
      print('Logout completed successfully');
    } catch (e) {
      // Even if there's an error, ensure local data is cleared
      await _preferenceService.clearAllUserData();
      _apiService.clearToken();
      print('Logout error: $e');
      throw Exception('Logout error: $e');
    }
  }

  /// Update user profile
  Future<AuthResult> updateProfile({
    required String name,
  }) async {
    try {
      final response = await _apiService.updateProfile(name: name);

      if (response['data'] != null) {
        final user = UserModelLokin.fromJson(response['data']);
        await _preferenceService.saveUser(user);

        return AuthResult.success(
          message: response['message'] ?? 'Profil berhasil diperbarui',
          user: user,
        );
      } else {
        return AuthResult.failure(
          message: response['message'] ?? 'Gagal memperbarui profil',
          errors: response['errors'],
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e),
      );
    }
  }

  /// Get user profile from server
  Future<AuthResult> getProfile() async {
    try {
      final response = await _apiService.getProfile();

      if (response.data != null) {
        // Convert UserResponse data to UserModel
        final userDataMap = response.data!.toJson();
        final user = UserModelLokin.fromJson(userDataMap);
        await _preferenceService.saveUser(user);

        return AuthResult.success(
          message: response.message,
          user: user,
        );
      } else {
        return AuthResult.failure(
          message: response.message,
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e),
      );
    }
  }

  /// Update profile photo
  Future<AuthResult> updateProfilePhoto(String imagePath) async {
    try {
      // Validate file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        return AuthResult.failure(
          message: 'File gambar tidak ditemukan',
        );
      }

      // Check file size (max 5MB)
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        return AuthResult.failure(
          message: 'Ukuran file terlalu besar (maksimal 5MB)',
        );
      }

      final response = await _apiService.updateProfilePhoto(file,
          photoPath: 'profile_photo');

      return AuthResult.success(
        message: response['message'] ?? 'Foto profil berhasil diperbarui',
        data: response['data'],
      );
    } catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e),
      );
    }
  }

  /// Save device token for push notifications
  Future<AuthResult> saveDeviceToken(String deviceToken) async {
    try {
      final response = await _apiService.saveDeviceToken(deviceToken);

      return AuthResult.success(
        message: response['message'] ?? 'Device token berhasil disimpan',
        data: response['data'],
      );
    } catch (e) {
      // Silently fail for device token, not critical
      return AuthResult.failure(
        message: 'Failed to save device token: ${_getErrorMessage(e)}',
      );
    }
  }

  /// Get list of trainings (for registration)
  Future<AuthResult> getTrainings() async {
    try {
      print('=== GET TRAININGS ===');
      print('Fetching trainings list...');

      final response = await _apiService.getTrainings();

      print('Trainings response message: ${response.message}');
      print('Trainings data count: ${response.data?.length ?? 0}');

      return AuthResult.success(
        message: response.message,
        data: response.data,
      );
    } catch (e) {
      print('Get trainings error in repository: $e');
      return AuthResult.failure(
        message: _getErrorMessage(e),
      );
    }
  }

  /// Get training detail by ID
  Future<AuthResult> getTrainingDetail(int id) async {
    try {
      final response = await _apiService.getTrainingDetail(id);

      return AuthResult.success(
        message: response.message,
        data: response.data,
      );
    } catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e),
      );
    }
  }

  /// Get list of batches
  Future<AuthResult> getBatches() async {
    try {
      print('=== GET BATCHES ===');
      print('Fetching batches list...');

      final response = await _apiService.getBatches();

      print('Batches response message: ${response.message}');
      print('Batches data count: ${response.data?.length ?? 0}');

      return AuthResult.success(
        message: response.message,
        data: response.data,
      );
    } catch (e) {
      print('Get batches error in repository: $e');
      return AuthResult.failure(
        message: _getErrorMessage(e),
      );
    }
  }

  /// Check if user session is still valid
  Future<bool> isSessionValid() async {
    try {
      if (!isAuthenticated) return false;

      final result = await getProfile();
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }

  /// Refresh user session
  Future<AuthResult> refreshSession() async {
    try {
      if (!isAuthenticated) {
        return AuthResult.failure(
          message: 'User tidak terautentikasi',
        );
      }

      return await getProfile();
    } catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e),
      );
    }
  }

  /// Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password strength
  Map<String, bool> validatePasswordStrength(String password) {
    return {
      'minLength': password.length >= 6,
      'hasLowercase': password.contains(RegExp(r'[a-z]')),
      'hasUppercase': password.contains(RegExp(r'[A-Z]')),
      'hasDigit': password.contains(RegExp(r'[0-9]')),
      'hasSpecialChar': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  }

  /// Get password strength score (0-5)
  int getPasswordStrengthScore(String password) {
    final validation = validatePasswordStrength(password);
    return validation.values.where((v) => v).length;
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _preferenceService.clearAllData();
    _apiService.clearToken();
  }

  /// Export user data (for backup purposes)
  Map<String, dynamic>? exportUserData() {
    final user = currentUser;
    if (user == null) return null;

    return {
      'user': user.toJson(),
      'preferences': _preferenceService.createBackup(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Import user data (for restore purposes)
  Future<AuthResult> importUserData(Map<String, dynamic> data) async {
    try {
      if (data['user'] != null) {
        final user = UserModelLokin.fromJson(data['user']);
        await _preferenceService.saveUser(user);
      }

      if (data['preferences'] != null) {
        await _preferenceService.restoreFromBackup(data['preferences']);
      }

      return AuthResult.success(
        message: 'Data berhasil dipulihkan',
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'Gagal memulihkan data: ${_getErrorMessage(e)}',
      );
    }
  }

  /// Helper method to extract meaningful error messages
  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();

      print('Processing error message: $message');

      // Remove "Exception: " prefix if present
      String cleanMessage = message.replaceFirst('Exception: ', '');

      if (cleanMessage.contains('Tidak ada koneksi internet')) {
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      } else if (cleanMessage.contains('SocketException') ||
          cleanMessage.contains('No address associated with hostname')) {
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      } else if (cleanMessage.contains('TimeoutException') ||
          cleanMessage.contains('timeout')) {
        return 'Koneksi timeout. Coba lagi nanti.';
      } else if (cleanMessage.contains('FormatException')) {
        return 'Format data tidak valid dari server.';
      } else if (cleanMessage.contains('Gagal melakukan registrasi') ||
          cleanMessage.contains('Gagal melakukan login')) {
        return cleanMessage;
      } else {
        return cleanMessage.isNotEmpty
            ? cleanMessage
            : 'Terjadi kesalahan yang tidak diketahui';
      }
    }

    return error.toString();
  }
}

/// Result class for authentication operations
class AuthResult {
  final bool isSuccess;
  final String message;
  final UserModelLokin? user;
  final String? token;
  final Map<String, dynamic>? errors;
  final dynamic data;

  AuthResult._({
    required this.isSuccess,
    required this.message,
    this.user,
    this.token,
    this.errors,
    this.data,
  });

  factory AuthResult.success({
    required String message,
    UserModelLokin? user,
    String? token,
    dynamic data,
  }) {
    return AuthResult._(
      isSuccess: true,
      message: message,
      user: user,
      token: token,
      data: data,
    );
  }

  factory AuthResult.failure({
    required String message,
    Map<String, dynamic>? errors,
  }) {
    return AuthResult._(
      isSuccess: false,
      message: message,
      errors: errors,
    );
  }

  /// Get first error message from errors map
  String? get firstError {
    if (errors == null) return null;

    for (var errorList in errors!.values) {
      if (errorList is List && errorList.isNotEmpty) {
        return errorList.first.toString();
      }
    }
    return null;
  }

  /// Get all error messages as a single string
  String get allErrors {
    if (errors == null) return message;

    List<String> errorMessages = [];
    for (var errorList in errors!.values) {
      if (errorList is List) {
        errorMessages.addAll(errorList.map((e) => e.toString()));
      }
    }

    return errorMessages.isEmpty ? message : errorMessages.join('\n');
  }

  /// Get formatted error message for display
  String get displayMessage {
    if (isSuccess) return message;

    // For login/register errors, show specific field errors
    if (errors != null && errors!.isNotEmpty) {
      return allErrors;
    }

    return message;
  }

  /// Check if error is network related
  bool get isNetworkError {
    return message.toLowerCase().contains('network') ||
        message.toLowerCase().contains('connection') ||
        message.toLowerCase().contains('internet') ||
        message.toLowerCase().contains('timeout') ||
        message.toLowerCase().contains('server');
  }

  /// Check if error is validation related
  bool get isValidationError {
    return errors != null && errors!.isNotEmpty;
  }

  /// Check if error is authentication related
  bool get isAuthError {
    return message.toLowerCase().contains('unauthorized') ||
        message.toLowerCase().contains('unauthenticated') ||
        message.toLowerCase().contains('token') ||
        message.toLowerCase().contains('login') ||
        message.toLowerCase().contains('password');
  }

  @override
  String toString() {
    return 'AuthResult(isSuccess: $isSuccess, message: $message, user: $user, token: $token, errors: $errors, data: $data)';
  }
}
