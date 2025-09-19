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
    required String gender,
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
        gender: gender,
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

  /// Get current user from local storage
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

  /// Get user profile from server - FIXED IMPLEMENTATION
  Future<AuthResult> getProfile() async {
    try {
      print('=== GET PROFILE FROM SERVER ===');
      final response = await _apiService.getProfile();

      print('Profile API response: ${response.message}');
      print('Profile data received: ${response.data != null ? 'Yes' : 'No'}');

      if (response.data != null) {
        // Convert UserResponse data to UserModel
        final userData = response.data!;
        final user = UserModelLokin(
          id: userData.id,
          name: userData.name,
          email: userData.email,
          emailVerifiedAt: userData.emailVerifiedAt,
          createdAt: userData.createdAt,
          updatedAt: userData.updatedAt,
        );

        // Save user data to local storage
        await _preferenceService.saveUser(user);
        print('User data saved to local storage: ${user.name}');

        return AuthResult.success(
          message: response.message,
          user: user,
        );
      } else {
        print('Get profile failed - no data in response');
        return AuthResult.failure(
          message: response.message ?? 'Gagal mengambil data profil',
        );
      }
    } catch (e) {
      print('Get profile exception: $e');
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

      final response = await _apiService.updateProfilePhoto(
        file,
        photoPath: imagePath,
      );

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
      print('Get trainings exception: $e');
      return AuthResult.failure(
        message: _getErrorMessage(e),
      );
    }
  }

  /// Get list of batches for specific training
  Future<AuthResult> getBatches(int trainingId) async {
    try {
      print('=== GET BATCHES ===');
      print('Fetching batches for training ID: $trainingId');

      final response = await _apiService.getBatches(trainingId);

      print('Batches response message: ${response.message}');
      print('Batches data count: ${response.data?.length ?? 0}');

      return AuthResult.success(
        message: response.message,
        data: response.data,
      );
    } catch (e) {
      print('Get batches exception: $e');
      return AuthResult.failure(
        message: _getErrorMessage(e),
      );
    }
  }

  /// Helper method to format error messages
  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }

  Future isSessionValid() async {}
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

  /// Get all error messages as a single string
  String get allErrors {
    if (errors == null || errors!.isEmpty) return message;

    List<String> errorMessages = [];
    errors!.forEach((key, value) {
      if (value is List) {
        errorMessages.addAll(value.map((e) => e.toString()));
      } else {
        errorMessages.add(value.toString());
      }
    });

    return errorMessages.isNotEmpty ? errorMessages.join('\n') : message;
  }
}
