import 'dart:async';

import 'package:flutter/material.dart';

// Enhanced In-App Notification Service
// Dengan sistem timer yang lebih akurat dan responsif

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  BuildContext? _context;
  final List<NotificationData> _pendingNotifications = [];
  final List<ScheduledNotification> _scheduledNotifications = [];
  Timer? _notificationTimer;
  Timer? _scheduledTimer;

  // Initialize service dengan timer yang lebih responsif
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;

    // Check pending notifications setiap 1 detik
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _showPendingNotifications(),
    );

    // PERBAIKAN: Timer khusus untuk scheduled notifications
    // Cek setiap 5 detik untuk responsivitas yang lebih baik
    _scheduledTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkScheduledNotifications(),
    );
  }

  // Set context untuk menampilkan notifications
  void setContext(BuildContext context) {
    _context = context;
  }

  // Show notification langsung (in-app only)
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final notification = NotificationData(
      title: title,
      body: body,
      payload: payload,
      timestamp: DateTime.now(),
    );

    if (_context != null && _context!.mounted) {
      _showInAppNotification(notification);
    } else {
      // Queue notification jika context tidak tersedia
      _pendingNotifications.add(notification);
    }
  }

  // PERBAIKAN: Schedule notification dengan sistem yang lebih akurat
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    print('DEBUG NOTIFICATION: Scheduling notification for $scheduledTime');

    // Hapus notification lama dengan ID yang sama
    _scheduledNotifications.removeWhere((notif) => notif.id == id);

    // Tambah ke daftar scheduled notifications
    final scheduledNotif = ScheduledNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      payload: payload,
    );

    _scheduledNotifications.add(scheduledNotif);

    print(
        'DEBUG NOTIFICATION: Added to schedule. Total scheduled: ${_scheduledNotifications.length}');
  }

  // PERBAIKAN: Method untuk mengecek scheduled notifications
  void _checkScheduledNotifications() {
    if (_scheduledNotifications.isEmpty) return;

    final now = DateTime.now();
    final toRemove = <ScheduledNotification>[];

    for (final scheduled in _scheduledNotifications) {
      // PERBAIKAN: Toleransi 30 detik untuk memastikan notification muncul
      final timeDiff = now.difference(scheduled.scheduledTime).inSeconds;

      if (timeDiff >= 0 && timeDiff <= 30) {
        print(
            'DEBUG NOTIFICATION: Triggering scheduled notification: ${scheduled.title}');

        // Tampilkan notification
        showNotification(
          title: scheduled.title,
          body: scheduled.body,
          payload: scheduled.payload,
        );

        // Tandai untuk dihapus
        toRemove.add(scheduled);
      }
    }

    // Hapus notifications yang sudah ditampilkan
    for (final notif in toRemove) {
      _scheduledNotifications.remove(notif);
      print(
          'DEBUG NOTIFICATION: Removed scheduled notification: ${notif.title}');
    }
  }

  // PERBAIKAN: Schedule daily reminder dengan sistem yang lebih akurat
  Future<void> scheduleDailyReminder({
    required String time, // Format: "HH:mm"
    required String title,
    required String body,
  }) async {
    print('DEBUG NOTIFICATION: Setting up daily reminder for $time');

    // Parse time
    final timeParts = time.split(':');
    if (timeParts.length != 2) return;

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);

    if (hour == null || minute == null) return;

    // Hitung waktu reminder untuk hari ini
    final now = DateTime.now();
    var reminderTime = DateTime(now.year, now.month, now.day, hour, minute);

    // Jika waktu sudah lewat hari ini, set untuk besok
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    await scheduleNotification(
      id: 999, // ID khusus untuk daily reminder
      title: title,
      body: body,
      scheduledTime: reminderTime,
    );

    print('DEBUG NOTIFICATION: Daily reminder scheduled for $reminderTime');
  }

  // Show in-app notification dengan design yang lebih menarik
  void _showInAppNotification(NotificationData notification) {
    if (_context == null || !_context!.mounted) return;

    print('DEBUG NOTIFICATION: Showing notification: ${notification.title}');

    // PERBAIKAN: Tampilkan dialog yang lebih prominent untuk reminder
    if (notification.title.contains('Pengingat')) {
      _showReminderDialog(notification);
    } else {
      _showNotificationSnackBar(notification);
    }
  }

  // PERBAIKAN: Dialog khusus untuk reminder yang lebih prominent
  void _showReminderDialog(NotificationData notification) {
    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon dengan animasi
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53E3E).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Color(0xFFE53E3E),
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE53E3E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Body
              Text(
                notification.body,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Set reminder untuk besok
                        _setNextDayReminder();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Nanti',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Arahkan ke halaman absen (Home tab)
                        _navigateToAbsence();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53E3E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Absen Sekarang',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show notification sebagai SnackBar untuk notifikasi biasa
  void _showNotificationSnackBar(NotificationData notification) {
    final scaffold = ScaffoldMessenger.of(_context!);

    scaffold.showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        notification.body,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  // Set reminder untuk hari berikutnya
  void _setNextDayReminder() {
    // Logic untuk mengatur reminder hari berikutnya
    // Ini akan dihandle oleh profile screen
    print('DEBUG NOTIFICATION: Setting reminder for next day');
  }

  // Navigate ke halaman absensi
  void _navigateToAbsence() {
    // Logic untuk navigate ke tab Home
    // Ini bisa menggunakan callback atau navigation service
    print('DEBUG NOTIFICATION: Navigating to absence page');
  }

  // Show pending notifications
  void _showPendingNotifications() {
    if (_pendingNotifications.isEmpty || _context == null || !_context!.mounted)
      return;

    final notification = _pendingNotifications.removeAt(0);
    _showInAppNotification(notification);
  }

  // Cancel notification
  Future<void> cancelNotification(int id) async {
    _scheduledNotifications.removeWhere((notif) => notif.id == id);
    print('DEBUG NOTIFICATION: Cancelled notification with ID: $id');
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    _pendingNotifications.clear();
    _scheduledNotifications.clear();
    print('DEBUG NOTIFICATION: Cancelled all notifications');
  }

  // Get scheduled notifications count (untuk debugging)
  int get scheduledCount => _scheduledNotifications.length;

  // Dispose resources
  void dispose() {
    _notificationTimer?.cancel();
    _scheduledTimer?.cancel();
    _pendingNotifications.clear();
    _scheduledNotifications.clear();
    print('DEBUG NOTIFICATION: Service disposed');
  }
}

// Data class untuk notifications
class NotificationData {
  final String title;
  final String body;
  final String? payload;
  final DateTime timestamp;

  NotificationData({
    required this.title,
    required this.body,
    this.payload,
    required this.timestamp,
  });
}

// Data class untuk scheduled notifications
class ScheduledNotification {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final String? payload;

  ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.payload,
  });
}
