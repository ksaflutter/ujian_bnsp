class AppConstantsLokin {
  // App Information
  static const String appName = 'LokinID';
  static const String appTagline = 'Absensi Tepat Lokasi';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Aplikasi Absensi PPKD dengan Lokasi';

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String apiDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String dayDateFormat = 'EEEE, dd MMMM yyyy';

  // Validation Messages
  static const String fieldRequiredMessage = 'wajib diisi';
  static const String invalidEmailMessage = 'Format email tidak valid';
  static const String passwordTooShortMessage = 'Password minimal 6 karakter';
  static const String passwordMismatchMessage = 'Password tidak cocok';
  static const String nameMinLengthMessage = 'Nama minimal 2 karakter';
  static const String reasonMinLengthMessage = 'Alasan minimal 3 karakter';

  // SharedPreferences Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String isDarkModeKey = 'is_dark_mode';
  static const String reminderTimeKey = 'reminder_time';
  static const String notificationEnabledKey = 'notification_enabled';
  static const String lastAttendanceKey = 'last_attendance';
  static const String attendanceStatsKey = 'attendance_stats';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  static const double smallPadding = 8.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonHeight = 56.0;
  static const double avatarSize = 120.0;

  // Animation Durations
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 500;
  static const int longAnimationDuration = 1000;
  static const int splashDuration = 3000;

  // Map Settings
  static const double defaultZoom = 16.0;
  static const double maxZoom = 20.0;
  static const double minZoom = 10.0;
  static const double locationAccuracy = 100.0;

  // Attendance Constants
  static const String statusPresent = 'masuk';
  static const String statusPermission = 'izin';
  static const String statusAbsent = 'alpha';

  // Common Permission Reasons
  static const List<String> commonPermissionReasons = [
    'Sakit',
    'Keperluan keluarga',
    'Keperluan pribadi',
    'Acara penting',
    'Kondisi darurat',
    'Lainnya',
  ];

  // Error Messages
  static const String networkErrorMessage = 'Periksa koneksi internet Anda';
  static const String serverErrorMessage = 'Terjadi kesalahan pada server';
  static const String unknownErrorMessage =
      'Terjadi kesalahan yang tidak diketahui';
  static const String timeoutErrorMessage = 'Koneksi timeout, coba lagi';
  static const String locationErrorMessage = 'Gagal mendapatkan lokasi';
  static const String permissionDeniedMessage = 'Izin tidak diberikan';

  // Success Messages
  static const String loginSuccessMessage = 'Login berhasil';
  static const String registerSuccessMessage = 'Registrasi berhasil';
  static const String profileUpdateSuccessMessage =
      'Profil berhasil diperbarui';
  static const String checkInSuccessMessage = 'Absen masuk berhasil';
  static const String checkOutSuccessMessage = 'Absen pulang berhasil';
  static const String permissionSubmitSuccessMessage = 'Izin berhasil diajukan';
  static const String photoUploadSuccessMessage = 'Foto berhasil diperbarui';
  static const String passwordResetSuccessMessage =
      'Password berhasil diperbarui';
  static const String otpSentSuccessMessage = 'OTP telah dikirim ke email';

  // Loading Messages
  static const String loadingMessage = 'Memuat...';
  static const String loadingProfileMessage = 'Memuat profil...';
  static const String loadingHistoryMessage = 'Memuat riwayat...';
  static const String loadingStatsMessage = 'Memuat statistik...';
  static const String savingMessage = 'Menyimpan...';
  static const String updatingMessage = 'Memperbarui...';
  static const String deletingMessage = 'Menghapus...';
  static const String uploadingMessage = 'Mengupload...';

  // Empty State Messages
  static const String noDataMessage = 'Tidak ada data tersedia';
  static const String noHistoryMessage = 'Belum ada riwayat absensi';
  static const String noNotificationMessage = 'Tidak ada notifikasi';

  // Dialog Messages
  static const String logoutConfirmMessage = 'Apakah Anda yakin ingin keluar?';
  static const String deleteConfirmMessage =
      'Apakah Anda yakin ingin menghapus?';
  static const String unsavedChangesMessage =
      'Ada perubahan yang belum disimpan';

  // Notification Settings
  static const String defaultReminderTitle = 'Pengingat Absen';
  static const String defaultReminderBody = 'Jangan lupa untuk absen hari ini!';
  static const String defaultReminderTime = '08:00';

  // Achievement Thresholds
  static const int perfectAttendanceThreshold = 100;
  static const int weeklyStreakThreshold = 7;
  static const int monthlyStreakThreshold = 30;

  // File Upload
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];

  // API Settings
  static const int apiTimeoutDuration = 30;
  static const int maxRetryAttempts = 3;
  static const int defaultPageSize = 20;

  // Cache Duration
  static const int cacheExpirationHours = 24;
  static const int statsRefreshMinutes = 30;

  // Regex Patterns
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^(\+62|62|0)[0-9]{9,13}$';
  static const String numericPattern = r'^[0-9]+$';
  static const String alphaPattern = r'^[a-zA-Z\s]+$';
  static const String alphaNumericPattern = r'^[a-zA-Z0-9\s]+$';
}
