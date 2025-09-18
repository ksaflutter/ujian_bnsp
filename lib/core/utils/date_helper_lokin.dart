import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants_lokin.dart';

class DateHelperLokin {
  static bool _isInitialized = false;

  // Initialize locale data
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      try {
        await initializeDateFormatting('id_ID', null);
        _isInitialized = true;
      } catch (e) {
        print('Error initializing date formatting: $e');
        // Fallback to default locale
        _isInitialized = true;
      }
    }
  }

  // Date formatters - will be initialized lazily
  static DateFormat? _dateFormatter;
  static DateFormat? _timeFormatter;
  static DateFormat? _dateTimeFormatter;
  static DateFormat? _apiDateFormatter;
  static DateFormat? _apiDateTimeFormatter;
  static DateFormat? _dayDateFormatter;

  // Getter for date formatter
  static DateFormat get dateFormatter {
    _dateFormatter ??= DateFormat(AppConstantsLokin.dateFormat);
    return _dateFormatter!;
  }

  // Getter for time formatter
  static DateFormat get timeFormatter {
    _timeFormatter ??= DateFormat(AppConstantsLokin.timeFormat);
    return _timeFormatter!;
  }

  // Getter for datetime formatter
  static DateFormat get dateTimeFormatter {
    _dateTimeFormatter ??= DateFormat(AppConstantsLokin.dateTimeFormat);
    return _dateTimeFormatter!;
  }

  // Getter for API date formatter
  static DateFormat get apiDateFormatter {
    _apiDateFormatter ??= DateFormat(AppConstantsLokin.apiDateFormat);
    return _apiDateFormatter!;
  }

  // Getter for API datetime formatter
  static DateFormat get apiDateTimeFormatter {
    _apiDateTimeFormatter ??= DateFormat(AppConstantsLokin.apiDateTimeFormat);
    return _apiDateTimeFormatter!;
  }

  // Getter for day date formatter with locale
  static DateFormat get dayDateFormatter {
    if (_dayDateFormatter == null) {
      try {
        _dayDateFormatter =
            DateFormat(AppConstantsLokin.dayDateFormat, 'id_ID');
      } catch (e) {
        // Fallback to default locale if id_ID is not available
        _dayDateFormatter = DateFormat(AppConstantsLokin.dayDateFormat);
      }
    }
    return _dayDateFormatter!;
  }

  // Format date for display (dd/MM/yyyy)
  static String formatDate(DateTime date) {
    return dateFormatter.format(date);
  }

  // Format time for display (HH:mm)
  static String formatTime(DateTime time) {
    return timeFormatter.format(time);
  }

  // Format datetime for display (dd/MM/yyyy HH:mm)
  static String formatDateTime(DateTime dateTime) {
    return dateTimeFormatter.format(dateTime);
  }

  // Format date for API (yyyy-MM-dd)
  static String formatDateForApi(DateTime date) {
    return apiDateFormatter.format(date);
  }

  // Format datetime for API (yyyy-MM-dd HH:mm:ss)
  static String formatDateTimeForApi(DateTime dateTime) {
    return apiDateTimeFormatter.format(dateTime);
  }

  // Format date with day name (Rabu, 24 September 2025)
  static String formatDateWithDay(DateTime date) {
    try {
      return dayDateFormatter.format(date);
    } catch (e) {
      // Fallback to simple format if locale fails
      return '${_getDayName(date.weekday)}, ${formatDate(date)}';
    }
  }

  // Parse API date string to DateTime
  static DateTime parseApiDate(String dateString) {
    return apiDateFormatter.parse(dateString);
  }

  // Parse API datetime string to DateTime
  static DateTime parseApiDateTime(String dateTimeString) {
    return apiDateTimeFormatter.parse(dateTimeString);
  }

  // Parse time string to DateTime (for today's date)
  static DateTime parseTime(String timeString) {
    final now = DateTime.now();
    final timeParts = timeString.split(':');
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  // Get current date as string for API
  static String getCurrentDateForApi() {
    return formatDateForApi(DateTime.now());
  }

  // Get current datetime as string for API
  static String getCurrentDateTimeForApi() {
    return formatDateTimeForApi(DateTime.now());
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  // Check if date is this week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  // Check if date is this month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  // Get start of day
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get end of day
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  // Get start of week (Monday)
  static DateTime getStartOfWeek(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return getStartOfDay(startOfWeek);
  }

  // Get end of week (Sunday)
  static DateTime getEndOfWeek(DateTime date) {
    final endOfWeek = date.add(Duration(days: 7 - date.weekday));
    return getEndOfDay(endOfWeek);
  }

  // Get start of month
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get end of month
  static DateTime getEndOfMonth(DateTime date) {
    final nextMonth = date.month == 12
        ? DateTime(date.year + 1, 1, 1)
        : DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1));
  }

  // Get difference in days
  static int getDifferenceInDays(DateTime start, DateTime end) {
    return end.difference(start).inDays;
  }

  // Get difference in hours
  static int getDifferenceInHours(DateTime start, DateTime end) {
    return end.difference(start).inHours;
  }

  // Get difference in minutes
  static int getDifferenceInMinutes(DateTime start, DateTime end) {
    return end.difference(start).inMinutes;
  }

  // Get relative time string (e.g., "2 jam yang lalu")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  // Get greeting based on time
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  // Get work day status
  static bool isWorkDay(DateTime date) {
    // Monday = 1, Sunday = 7
    return date.weekday >= 1 && date.weekday <= 5;
  }

  // Get weekend status
  static bool isWeekend(DateTime date) {
    return date.weekday == 6 || date.weekday == 7; // Saturday or Sunday
  }

  // Add business days (skip weekends)
  static DateTime addBusinessDays(DateTime date, int days) {
    var result = date;
    var remainingDays = days;

    while (remainingDays > 0) {
      result = result.add(const Duration(days: 1));
      if (isWorkDay(result)) {
        remainingDays--;
      }
    }

    return result;
  }

  // Format duration to readable string
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Get month name in Indonesian
  static String getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }

  // Get day name in Indonesian
  static String getDayName(int weekday) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return days[weekday - 1];
  }

  // Helper method to get day name (internal use)
  static String _getDayName(int weekday) {
    return getDayName(weekday);
  }

  // Check if time is within work hours
  static bool isWithinWorkHours(
    DateTime time, {
    int startHour = 8,
    int endHour = 17,
  }) {
    return time.hour >= startHour && time.hour < endHour;
  }

  // Get age from birth date
  static int getAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  // Initialize method (call this early in app lifecycle)
  static Future<void> initialize() async {
    await _ensureInitialized();
  }
}
