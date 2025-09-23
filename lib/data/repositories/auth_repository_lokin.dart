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

  /// PERBAIKAN: Register new user dengan profilePhoto parameter
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required int trainingId,
    required int batchId,
    required String gender,
    String? profilePhoto, // TAMBAHAN: Parameter profilePhoto
  }) async {
    try {
      print('=== AUTH REPOSITORY REGISTER ===');
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        trainingId: trainingId,
        batchId: batchId,
        gender: gender,
        profilePhoto:
            profilePhoto, // TAMBAHAN: Pass profilePhoto ke API service
      );

      if (response['data'] != null) {
        final token = response['data']['token'];
        final userData = response['data']['user'];

        await _preferenceService.saveToken(token);
        final user = UserModelLokin.fromJson(userData);
        await _preferenceService.saveUser(user);

        _apiService.setToken(token);

        return AuthResult.success(
          message: response['message'] ?? 'Registrasi berhasil',
          user: user,
          token: token,
        );
      } else {
        return AuthResult.failure(
          message: response['message'] ?? 'Registrasi gagal',
          errors: response['errors'],
        );
      }
    } catch (e) {
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
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response['data'] != null) {
        final token = response['data']['token'];
        final userData = response['data']['user'];

        await _preferenceService.saveToken(token);
        final user = UserModelLokin.fromJson(userData);
        await _preferenceService.saveUser(user);

        _apiService.setToken(token);

        return AuthResult.success(
          message: response['message'] ?? 'Login berhasil',
          user: user,
          token: token,
        );
      } else {
        return AuthResult.failure(
          message: response['message'] ?? 'Login gagal',
        );
      }
    } catch (e) {
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
      _apiService.clearToken();
      await _preferenceService.clearAllUserData();
      print('Logout completed successfully');
    } catch (e) {
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
        final user = response.data!;
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

  /// Update profile photo - TETAP SAMA SEPERTI YANG SUDAH BEKERJA
  Future<AuthResult> updateProfilePhoto(String imagePath) async {
    try {
      print('=== AUTH REPOSITORY: updateProfilePhoto ===');
      print('Image path: $imagePath');

      final file = File(imagePath);
      if (!await file.exists()) {
        return AuthResult.failure(message: 'File gambar tidak ditemukan');
      }

      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        return AuthResult.failure(
            message: 'Ukuran file terlalu besar (maksimal 5MB)');
      }

      print('Calling API service updateProfilePhoto...');
      final response = await _apiService.updateProfilePhoto(
        file,
        photoPath: imagePath,
      );

      print('API response received: $response');

      // Check if response has success message
      final message = response['message'] ?? '';
      if (message.toLowerCase().contains('berhasil') ||
          message.toLowerCase().contains('success') ||
          response.containsKey('data')) {
        // Success - refresh profile to get updated photo URL
        try {
          await getProfile();
        } catch (e) {
          print('Error refreshing profile: $e');
        }

        return AuthResult.success(
          message:
              message.isNotEmpty ? message : 'Foto profil berhasil diperbarui',
          data: response['data'],
        );
      } else {
        return AuthResult.failure(
          message: message.isNotEmpty ? message : 'Gagal update foto',
        );
      }
    } catch (e) {
      print('Error in updateProfilePhoto: $e');
      return AuthResult.failure(message: _getErrorMessage(e));
    }
  }

  /// Save device token
  Future<AuthResult> saveDeviceToken(String deviceToken) async {
    try {
      final response = await _apiService.saveDeviceToken(deviceToken);
      return AuthResult.success(
        message: response['message'] ?? 'Device token berhasil disimpan',
        data: response['data'],
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'Failed to save device token: ${_getErrorMessage(e)}',
      );
    }
  }

  /// Get list of trainings
  Future<AuthResult> getTrainings() async {
    try {
      final response = await _apiService.getTrainings();
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

  /// PERBAIKAN: Get list of batches tanpa parameter (public endpoint)
  Future<AuthResult> getBatches() async {
    try {
      final response = await _apiService.getBatchesPublic();
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

  /// Error message helper
  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }

  Future isSessionValid() async {}

  Future getCurrentUser() async {}
}

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
