import 'dart:async';

import 'package:flutter/material.dart';

// Simple In-App Notification Service
// Tidak menggunakan flutter_local_notifications
// Hanya menampilkan notification di dalam app

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  BuildContext? _context;
  final List<NotificationData> _pendingNotifications = [];
  Timer? _notificationTimer;

  // Initialize service (simplified version)
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;

    // Start checking for pending notifications
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _showPendingNotifications(),
    );
  }

  // Set context for showing notifications
  void setContext(BuildContext context) {
    _context = context;
  }

  // Show notification (in-app only)
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
      // Queue notification if context not available
      _pendingNotifications.add(notification);
    }
  }

  // Schedule notification (simplified - just saves for later)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // In-app version: just schedule to show at the time
    Timer(
      scheduledTime.difference(DateTime.now()),
      () {
        if (scheduledTime.isAfter(DateTime.now())) {
          showNotification(
            title: title,
            body: body,
            payload: payload,
          );
        }
      },
    );
  }

  // Show in-app notification
  void _showInAppNotification(NotificationData notification) {
    if (_context == null || !_context!.mounted) return;

    final scaffold = ScaffoldMessenger.of(_context!);

    // Show as SnackBar
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
        duration: const Duration(seconds: 5),
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

  // Show pending notifications
  void _showPendingNotifications() {
    if (_pendingNotifications.isEmpty || _context == null) return;

    final notification = _pendingNotifications.removeAt(0);
    _showInAppNotification(notification);
  }

  // Cancel notification (simplified)
  Future<void> cancelNotification(int id) async {
    // In-app version: just clear pending notifications with this id
    _pendingNotifications.clear();
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    _pendingNotifications.clear();
  }

  // Dispose
  void dispose() {
    _notificationTimer?.cancel();
    _pendingNotifications.clear();
  }
}

// Data class for notifications
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
