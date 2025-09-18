class ApiConstantsLokin {
  // Base URL - Pastikan URL ini benar dan dapat diakses
  static const String baseUrl = 'https://appabsensi.mobileprojp.com/api';

  // Untuk testing jika ada masalah dengan HTTPS, bisa dicoba dengan HTTP
  // static const String baseUrl = 'http://appabsensi.mobileprojp.com/api';

  // Authentication Endpoints
  static const String registerEndpoint = '/register';
  static const String loginEndpoint = '/login';
  static const String forgotPasswordEndpoint = '/forgot-password';
  static const String resetPasswordEndpoint = '/reset-password';

  // Attendance Endpoints
  static const String checkInEndpoint = '/absen/check-in';
  static const String checkOutEndpoint = '/absen/check-out';
  static const String todayAttendanceEndpoint = '/absen/today';
  static const String attendanceStatsEndpoint = '/absen/stats';
  static const String attendanceHistoryEndpoint = '/absen/history';
  static const String deleteAttendanceEndpoint = '/absen';

  // Permission Endpoint
  static const String permissionEndpoint = '/izin';

  // Profile Endpoints
  static const String profileEndpoint = '/profile';
  static const String profilePhotoEndpoint = '/profile/photo';

  // Training & Batch Endpoints
  static const String trainingsEndpoint = '/trainings';
  static const String batchesEndpoint = '/batches';
  static const String usersEndpoint = '/users';

  // Device Token Endpoint
  static const String deviceTokenEndpoint = '/device-token';

  // HTTP Headers
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';
  static const String authorizationHeader = 'Authorization';
  static const String applicationJsonValue = 'application/json';
  static const String bearerPrefix = 'Bearer ';

  // Request Parameters
  static const String attendanceDateParam = 'attendance_date';
  static const String startDateParam = 'start';
  static const String endDateParam = 'end';
  static const String latitudeParam = 'latitude';
  static const String longitudeParam = 'longitude';
  static const String addressParam = 'address';
  static const String reasonParam = 'alasan_izin';
  static const String nameParam = 'name';
  static const String emailParam = 'email';
  static const String passwordParam = 'password';
  static const String otpParam = 'otp';
  static const String trainingIdParam = 'training_id';
  static const String batchIdParam = 'batch_id';
  static const String playerIdParam = 'player_id';
  static const String profilePhotoParam = 'profile_photo';

  // Response Keys
  static const String messageKey = 'message';
  static const String dataKey = 'data';
  static const String errorsKey = 'errors';
  static const String tokenKey = 'token';
  static const String userKey = 'user';

  // Status Codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusAccepted = 202;
  static const int statusNoContent = 204;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusMethodNotAllowed = 405;
  static const int statusConflict = 409;
  static const int statusUnprocessableEntity = 422;
  static const int statusInternalServerError = 500;
  static const int statusBadGateway = 502;
  static const int statusServiceUnavailable = 503;
  static const int statusGatewayTimeout = 504;

  // Timeout Settings
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds

  // File Upload Settings
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png'];
  static const String multipartFormData = 'multipart/form-data';

  // API Response Messages (from documentation)
  static const String registrationSuccessMessage = 'Registrasi berhasil';
  static const String loginSuccessMessage = 'Login berhasil';
  static const String emailAlreadyRegisteredMessage = 'Email sudah terdaftar';
  static const String emailNotRegisteredMessage = 'Email belum terdaftar';
  static const String invalidCredentialsMessage = 'Email atau password salah';
  static const String checkInSuccessMessage = 'Absen masuk berhasil';
  static const String checkOutSuccessMessage = 'Absen keluar berhasil';
  static const String alreadyCheckedInMessage =
      'Anda sudah melakukan absen hari ini';
  static const String alreadyCheckedOutMessage =
      'Anda sudah melakukan absen keluar hari ini';
  static const String notCheckedInMessage =
      'Anda belum melakukan absen masuk hari ini';
  static const String permissionSuccessMessage = 'Izin berhasil diajukan';
  static const String alreadyPermissionMessage =
      'Anda sudah mengajukan izin pada tanggal ini';
  static const String profileUpdateSuccessMessage =
      'Profil berhasil diperbarui';
  static const String photoUpdateSuccessMessage =
      'Foto profil berhasil diperbarui';
  static const String deleteSuccessMessage = 'Data absen berhasil dihapus';
  static const String attendanceNotFoundMessage =
      'Data absen tidak ditemukan atau bukan milik Anda';
  static const String otpSentMessage = 'OTP berhasil dikirim ke email';
  static const String passwordResetSuccessMessage =
      'Password berhasil diperbarui';
  static const String invalidOtpMessage =
      'OTP tidak valid atau telah kadaluarsa';
  static const String deviceTokenSavedMessage = 'Player ID berhasil disimpan';
  static const String unauthenticatedMessage = 'Unauthenticated.';
  static const String attendanceFoundMessage = 'Data absensi ditemukan';
  static const String attendanceStatsMessage = 'Statistik absensi pengguna';
  static const String attendanceHistoryMessage =
      'Berhasil mengambil riwayat absensi';
  static const String noAttendanceHistoryMessage = 'Tidak ada riwayat absensi';
  static const String profileFoundMessage =
      'Berhasil mengambil data profil pengguna';
  static const String allUsersMessage =
      'Berhasil mengambil seluruh data pengguna';
  static const String trainingsListMessage = 'List data pelatihan';
  static const String trainingDetailMessage = 'Detail pelatihan';
  static const String batchesListMessage = 'List batch pelatihan';
  static const String missingParametersMessage =
      'Harap kirimkan kedua tanggal: start dan end';

  // Common Error Messages
  static const String nameRequiredMessage = 'Nama wajib diisi';
  static const String emailRequiredMessage = 'Email wajib diisi';
  static const String passwordRequiredMessage = 'Password wajib diisi';
  static const String fieldRequiredMessage = 'wajib diisi';

  // Attendance Status Values
  static const String attendanceStatusPresent = 'masuk';
  static const String attendanceStatusPermission = 'izin';

  // Retry Settings
  static const int maxRetryAttempts = 3;
  static const int retryDelayMilliseconds = 1000;
  static const double retryBackoffMultiplier = 2.0;

  // Debug Settings
  static const bool enableDebugPrint = true; // Set to false in production

  // Helper method untuk debugging
  static void debugPrint(String message) {
    if (enableDebugPrint) {
      print('[API_DEBUG] $message');
    }
  }

  // Method untuk memvalidasi URL
  static bool validateBaseUrl() {
    try {
      final uri = Uri.parse(baseUrl);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      debugPrint('Invalid base URL: $baseUrl');
      return false;
    }
  }

  // Method untuk membangun URL lengkap
  static String buildUrl(String endpoint) {
    if (endpoint.startsWith('/')) {
      return baseUrl + endpoint;
    } else {
      return '$baseUrl/$endpoint';
    }
  }
}
