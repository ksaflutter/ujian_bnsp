import '../constants/app_constants_lokin.dart';

class ValidationHelperLokin {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }

    final emailRegex = RegExp(AppConstantsLokin.emailPattern);

    if (!emailRegex.hasMatch(value.trim())) {
      return AppConstantsLokin.invalidEmailMessage;
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }

    if (value.length < 6) {
      return AppConstantsLokin.passwordTooShortMessage;
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }

    if (value != password) {
      return AppConstantsLokin.passwordMismatchMessage;
    }

    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama wajib diisi';
    }

    if (value.trim().length < 2) {
      return AppConstantsLokin.nameMinLengthMessage;
    }

    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName wajib diisi'
          : AppConstantsLokin.fieldRequiredMessage;
    }

    return null;
  }

  // Reason validation (for permission)
  static String? validateReason(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Alasan wajib diisi';
    }

    if (value.trim().length < 3) {
      return AppConstantsLokin.reasonMinLengthMessage;
    }

    return null;
  }

  // OTP validation
  static String? validateOTP(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kode OTP wajib diisi';
    }

    if (value.trim().length < 4) {
      return 'Kode OTP minimal 4 karakter';
    }

    final otpRegex = RegExp(AppConstantsLokin.numericPattern);
    if (!otpRegex.hasMatch(value.trim())) {
      return 'Kode OTP hanya boleh berisi angka';
    }

    return null;
  }

  // Date validation
  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'Tanggal wajib diisi';
    }

    return null;
  }

  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Alamat wajib diisi';
    }

    if (value.trim().length < 5) {
      return 'Alamat minimal 5 karakter';
    }

    return null;
  }

  // Latitude validation
  static String? validateLatitude(double? value) {
    if (value == null) {
      return 'Latitude wajib diisi';
    }

    if (value < -90 || value > 90) {
      return 'Latitude tidak valid';
    }

    return null;
  }

  // Longitude validation
  static String? validateLongitude(double? value) {
    if (value == null) {
      return 'Longitude wajib diisi';
    }

    if (value < -180 || value > 180) {
      return 'Longitude tidak valid';
    }

    return null;
  }

  // Training ID validation
  static String? validateTrainingId(int? value) {
    if (value == null || value <= 0) {
      return 'Pilih training terlebih dahulu';
    }

    return null;
  }

  // Batch ID validation
  static String? validateBatchId(int? value) {
    if (value == null || value <= 0) {
      return 'Pilih batch terlebih dahulu';
    }

    return null;
  }

  // Min length validation
  static String? validateMinLength(String? value, int minLength) {
    if (value == null || value.trim().isEmpty) {
      return 'Field ini wajib diisi';
    }

    if (value.trim().length < minLength) {
      return 'Minimal $minLength karakter';
    }

    return null;
  }

  // Max length validation
  static String? validateMaxLength(String? value, int maxLength) {
    if (value != null && value.trim().length > maxLength) {
      return 'Maksimal $maxLength karakter';
    }

    return null;
  }

  // Clean input text
  static String cleanInput(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Sanitize input for search
  static String sanitizeSearchInput(String input) {
    return cleanInput(input).toLowerCase();
  }

  // Check if string contains only letters and spaces
  static bool isAlpha(String input) {
    return RegExp(AppConstantsLokin.alphaPattern).hasMatch(input);
  }

  // Check if string contains only numbers
  static bool isNumeric(String input) {
    return RegExp(AppConstantsLokin.numericPattern).hasMatch(input);
  }

  // Check if string is alphanumeric
  static bool isAlphaNumeric(String input) {
    return RegExp(AppConstantsLokin.alphaNumericPattern).hasMatch(input);
  }

  // Validate check-in parameters
  static Map<String, String?> validateCheckInParams({
    required double? latitude,
    required double? longitude,
    required String? address,
  }) {
    Map<String, String?> errors = {};

    final latError = validateLatitude(latitude);
    if (latError != null) errors['latitude'] = latError;

    final lngError = validateLongitude(longitude);
    if (lngError != null) errors['longitude'] = lngError;

    final addressError = validateAddress(address);
    if (addressError != null) errors['address'] = addressError;

    return errors;
  }

  // Validate permission parameters
  static Map<String, String?> validatePermissionParams({
    required String? date,
    required String? reason,
  }) {
    Map<String, String?> errors = {};

    if (date == null || date.isEmpty) {
      errors['date'] = 'Tanggal wajib diisi';
    }

    final reasonError = validateReason(reason);
    if (reasonError != null) errors['reason'] = reasonError;

    return errors;
  }

  // Validate registration parameters
  static Map<String, String?> validateRegistrationParams({
    required String? name,
    required String? email,
    required String? password,
    required int? trainingId,
    required int? batchId,
  }) {
    Map<String, String?> errors = {};

    final nameError = validateName(name);
    if (nameError != null) errors['name'] = nameError;

    final emailError = validateEmail(email);
    if (emailError != null) errors['email'] = emailError;

    final passwordError = validatePassword(password);
    if (passwordError != null) errors['password'] = passwordError;

    final trainingError = validateTrainingId(trainingId);
    if (trainingError != null) errors['training'] = trainingError;

    final batchError = validateBatchId(batchId);
    if (batchError != null) errors['batch'] = batchError;

    return errors;
  }

  // Validate login parameters
  static Map<String, String?> validateLoginParams({
    required String? email,
    required String? password,
  }) {
    Map<String, String?> errors = {};

    final emailError = validateEmail(email);
    if (emailError != null) errors['email'] = emailError;

    final passwordError = validateRequired(password, fieldName: 'Password');
    if (passwordError != null) errors['password'] = passwordError;

    return errors;
  }

  // Validate profile update parameters
  static Map<String, String?> validateProfileParams({
    required String? name,
    String? email,
  }) {
    Map<String, String?> errors = {};

    final nameError = validateName(name);
    if (nameError != null) errors['name'] = nameError;

    if (email != null && email.isNotEmpty) {
      final emailError = validateEmail(email);
      if (emailError != null) errors['email'] = emailError;
    }

    return errors;
  }

  // Validate reset password parameters
  static Map<String, String?> validateResetPasswordParams({
    required String? email,
    required String? otp,
    required String? password,
  }) {
    Map<String, String?> errors = {};

    final emailError = validateEmail(email);
    if (emailError != null) errors['email'] = emailError;

    final otpError = validateOTP(otp);
    if (otpError != null) errors['otp'] = otpError;

    final passwordError = validatePassword(password);
    if (passwordError != null) errors['password'] = passwordError;

    return errors;
  }

  static String? validateNotEmpty(String? value, String s) {
    return null;
  }
}
