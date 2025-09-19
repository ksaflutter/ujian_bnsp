import 'package:intl/intl.dart';

import '../constants/app_constants_lokin.dart';

class DateHelperLokin {
  // Private formatters - initialized once for performance
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

  // Enhanced API datetime formatter with consistent format
  static String formatDateTimeForApiConsistent(DateTime dateTime) {
    return "${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
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

  // Format date in Indonesian format
  static String formatDateIndonesian(DateTime date) {
    try {
      final dayName = _getDayName(date.weekday);
      final monthName = _getMonthName(date.month);
      return '$dayName, ${date.day} $monthName ${date.year}';
    } catch (e) {
      return formatDate(date);
    }
  }

  // Get Indonesian day name
  static String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Senin';
      case DateTime.tuesday:
        return 'Selasa';
      case DateTime.wednesday:
        return 'Rabu';
      case DateTime.thursday:
        return 'Kamis';
      case DateTime.friday:
        return 'Jumat';
      case DateTime.saturday:
        return 'Sabtu';
      case DateTime.sunday:
        return 'Minggu';
      default:
        return 'Unknown';
    }
  }

  // Get Indonesian month name
  static String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Januari';
      case 2:
        return 'Februari';
      case 3:
        return 'Maret';
      case 4:
        return 'April';
      case 5:
        return 'Mei';
      case 6:
        return 'Juni';
      case 7:
        return 'Juli';
      case 8:
        return 'Agustus';
      case 9:
        return 'September';
      case 10:
        return 'Oktober';
      case 11:
        return 'November';
      case 12:
        return 'Desember';
      default:
        return 'Unknown';
    }
  }

  // Parse API date string to DateTime
  static DateTime parseApiDate(String dateString) {
    try {
      return apiDateFormatter.parse(dateString);
    } catch (e) {
      // Fallback parsing
      return DateTime.parse(dateString);
    }
  }

  // Parse API datetime string to DateTime
  static DateTime parseApiDateTime(String dateTimeString) {
    try {
      return apiDateTimeFormatter.parse(dateTimeString);
    } catch (e) {
      // Fallback parsing
      return DateTime.parse(dateTimeString.replaceAll(' ', 'T'));
    }
  }

  // Parse flexible datetime string
  static DateTime? parseFlexibleDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return null;
    }

    try {
      // Try different formats
      final formats = [
        'yyyy-MM-dd HH:mm:ss',
        'yyyy-MM-dd HH:mm',
        'yyyy-MM-dd',
        'dd/MM/yyyy HH:mm:ss',
        'dd/MM/yyyy HH:mm',
        'dd/MM/yyyy',
      ];

      for (String format in formats) {
        try {
          return DateFormat(format).parse(dateTimeString);
        } catch (e) {
          continue;
        }
      }

      // Last resort - ISO format
      return DateTime.parse(dateTimeString);
    } catch (e) {
      print('Failed to parse datetime: $dateTimeString, error: $e');
      return null;
    }
  }

  // Get current date in API format
  static String getCurrentDateForApi() {
    return formatDateForApi(DateTime.now());
  }

  // Get current datetime in API format
  static String getCurrentDateTimeForApi() {
    return formatDateTimeForApiConsistent(DateTime.now());
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  // Get relative date string (Today, Yesterday, or formatted date)
  static String getRelativeDateString(DateTime date) {
    if (isToday(date)) {
      return 'Hari ini';
    } else if (isYesterday(date)) {
      return 'Kemarin';
    } else {
      return formatDateIndonesian(date);
    }
  }

  // Get time difference in minutes
  static int getTimeDifferenceInMinutes(DateTime start, DateTime end) {
    return end.difference(start).inMinutes;
  }

  // Get time difference in hours
  static double getTimeDifferenceInHours(DateTime start, DateTime end) {
    return end.difference(start).inMinutes / 60.0;
  }

  // Format duration to readable string
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}j ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Get start of day
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get end of day
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  // Get start of month
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get end of month
  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  // Get days in month
  static int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  // Add business days (skip weekends)
  static DateTime addBusinessDays(DateTime date, int days) {
    DateTime result = date;
    int addedDays = 0;

    while (addedDays < days) {
      result = result.add(const Duration(days: 1));
      if (result.weekday != DateTime.saturday &&
          result.weekday != DateTime.sunday) {
        addedDays++;
      }
    }

    return result;
  }

  // Check if date is weekend
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  // Get age from birthdate
  static int getAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  // Validate date range
  static bool isDateInRange(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start.subtract(const Duration(days: 1))) &&
        date.isBefore(end.add(const Duration(days: 1)));
  }

  // Get time zone offset
  static String getTimeZoneOffset() {
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours.abs();
    final minutes = (offset.inMinutes % 60).abs();
    final sign = offset.isNegative ? '-' : '+';

    return '$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  // Format time with AM/PM
  static String formatTimeWithAmPm(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  // Format time in 24 hour format
  static String formatTime24Hour(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  // Parse time string to DateTime (today with specified time)
  static DateTime? parseTimeString(String timeString) {
    try {
      final now = DateTime.now();
      final parts = timeString.split(':');

      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final second = parts.length > 2 ? int.parse(parts[2]) : 0;

        return DateTime(now.year, now.month, now.day, hour, minute, second);
      }
    } catch (e) {
      print('Failed to parse time string: $timeString, error: $e');
    }

    return null;
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat pagi';
    } else if (hour < 17) {
      return 'Selamat siang';
    } else if (hour < 20) {
      return 'Selamat sore';
    } else {
      return 'Selamat malam';
    }
  }
}
