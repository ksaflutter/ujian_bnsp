import 'package:intl/intl.dart';

import '../constants/app_constants_lokin.dart';

class DateHelperLokin {
  // Private static formatters to avoid recreating them
  static DateFormat? _dateFormatter;
  static DateFormat? _timeFormatter;
  static DateFormat? _dateTimeFormatter;
  static DateFormat? _apiDateFormatter;
  static DateFormat? _apiDateTimeFormatter;
  static DateFormat? _dayDateFormatter;

  // Initialize formatters
  static void _initializeFormatters() {
    _dateFormatter ??= DateFormat(AppConstantsLokin.dateFormat);
    _timeFormatter ??= DateFormat(AppConstantsLokin.timeFormat);
    _dateTimeFormatter ??= DateFormat(AppConstantsLokin.dateTimeFormat);
    _apiDateFormatter ??= DateFormat(AppConstantsLokin.apiDateFormat);
    _apiDateTimeFormatter ??= DateFormat(AppConstantsLokin.apiDateTimeFormat);

    try {
      _dayDateFormatter ??=
          DateFormat(AppConstantsLokin.dayDateFormat, 'id_ID');
    } catch (e) {
      // Fallback to default locale if id_ID is not available
      _dayDateFormatter = DateFormat(AppConstantsLokin.dayDateFormat);
    }
  }

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

  // PERBAIKAN: Format date for API (yyyy-MM-dd) - method yang digunakan untuk izin
  static String formatDateForApi(DateTime date) {
    return apiDateFormatter.format(date);
  }

  // Format datetime for API (yyyy-MM-dd HH:mm:ss)
  static String formatDateTimeForApi(DateTime dateTime) {
    return apiDateTimeFormatter.format(dateTime);
  }

  // PERBAIKAN: Method untuk mendapatkan tanggal hari ini dalam format API
  static String getCurrentDateForApi() {
    return formatDateForApi(DateTime.now());
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

  // Format date for Indonesian display
  static String formatDateIndonesian(DateTime date) {
    try {
      _initializeFormatters();
      return dayDateFormatter.format(date);
    } catch (e) {
      // Fallback implementation
      return '${_getDayName(date.weekday)}, ${date.day} ${_getMonthName(date.month)} ${date.year}';
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

  // Parse display date string to DateTime
  static DateTime parseDate(String dateString) {
    return dateFormatter.parse(dateString);
  }

  // Parse time string to DateTime (today's date with given time)
  static DateTime parseTime(String timeString) {
    final now = DateTime.now();
    final time = timeFormatter.parse(timeString);
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  // Get current time as formatted string
  static String getCurrentTime() {
    return formatTime(DateTime.now());
  }

  // Get current date as formatted string
  static String getCurrentDate() {
    return formatDate(DateTime.now());
  }

  // Get current datetime as formatted string
  static String getCurrentDateTime() {
    return formatDateTime(DateTime.now());
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

  // Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  // Get relative date string (Today, Yesterday, Tomorrow, or formatted date)
  static String getRelativeDateString(DateTime date) {
    if (isToday(date)) {
      return 'Hari ini';
    } else if (isYesterday(date)) {
      return 'Kemarin';
    } else if (isTomorrow(date)) {
      return 'Besok';
    } else {
      return formatDateWithDay(date);
    }
  }

  // Get greeting based on current time
  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Selamat Pagi';
    } else if (hour >= 12 && hour < 15) {
      return 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  // Get time difference in human readable format
  static String getTimeDifference(DateTime from, DateTime to) {
    final difference = to.difference(from);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit';
    } else {
      return 'Baru saja';
    }
  }

  // Calculate age from birth date
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  // Get start of day
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get end of day
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  // Get start of week (Monday)
  static DateTime getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return getStartOfDay(date.subtract(Duration(days: daysFromMonday)));
  }

  // Get end of week (Sunday)
  static DateTime getEndOfWeek(DateTime date) {
    final daysToSunday = 7 - date.weekday;
    return getEndOfDay(date.add(Duration(days: daysToSunday)));
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
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  // Check if year is leap year
  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  // Get weekday name in Indonesian
  static String _getDayName(int weekday) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    return days[weekday - 1];
  }

  // Get month name in Indonesian
  static String _getMonthName(int month) {
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
      'Desember'
    ];
    return months[month - 1];
  }

  // Get short weekday name in Indonesian
  static String getShortDayName(int weekday) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[weekday - 1];
  }

  // Get short month name in Indonesian
  static String getShortMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return months[month - 1];
  }

  // Format duration in human readable format
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} hari ${duration.inHours % 24} jam';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} jam ${duration.inMinutes % 60} menit';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} menit';
    } else {
      return '${duration.inSeconds} detik';
    }
  }

  // Get business days between two dates (excludes weekends)
  static int getBusinessDaysBetween(DateTime start, DateTime end) {
    int count = 0;
    DateTime current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }

    return count;
  }

  // Check if date is weekend
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  // Check if date is weekday
  static bool isWeekday(DateTime date) {
    return !isWeekend(date);
  }

  // Get next weekday
  static DateTime getNextWeekday(DateTime date) {
    DateTime next = date.add(const Duration(days: 1));
    while (isWeekend(next)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  // Get previous weekday
  static DateTime getPreviousWeekday(DateTime date) {
    DateTime previous = date.subtract(const Duration(days: 1));
    while (isWeekend(previous)) {
      previous = previous.subtract(const Duration(days: 1));
    }
    return previous;
  }
}
