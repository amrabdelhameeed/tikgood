import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../database/storage_service.dart';

/// Handles daily streak tracking and local notification reminders.
class StreakService {
  final StorageService _storage;
  final FlutterLocalNotificationsPlugin _notifications;

  static const int _reminderNotificationId = 42;
  static const String _channelId = 'tikgood_streak_reminder';
  static const String _channelName = 'Daily Study Reminder';
  static const String _channelDesc =
      'Reminds you to open TikGood and keep your study streak';

  /// Motivating messages — randomly picks one per notification.
  static const List<String> _messages = [
    "📚 Your future self will thank you. Study for 10 mins.",
    "🚀 Momentum is everything — open TikGood and keep going!",
    "🧠 Even 5 minutes of learning beats zero. You've got this.",
    "💡 Curiosity never sleeps. Neither should your streak!",
    "⚡ Legends don't skip days. Time to learn something great.",
    "🏆 Champions show up every day. You're one tap away.",
    "🎯 Small steps, big results. Keep the streak alive!",
    "🔥 Don't let the flame die — open TikGood and study now.",
  ];

  StreakService(this._storage, this._notifications);

  // ── Streak Logic ────────────────────────────────────────────────────────────

  /// Call on every app open. Updates streak count and returns the new count.
  Future<int> checkAndUpdateStreak() async {
    final today = _dateOnly(DateTime.now());
    final lastOpenStr = _storage.getLastOpenDate();

    int streak = _storage.getStreakCount();

    if (lastOpenStr == null) {
      // First ever open
      streak = 1;
    } else {
      final lastOpen = DateTime.parse(lastOpenStr);
      final diff = today.difference(_dateOnly(lastOpen)).inDays;
      if (diff == 0) {
        // Already opened today — no change
      } else if (diff == 1) {
        // Consecutive day → increment
        streak += 1;
      } else {
        // Missed one or more days → reset
        streak = 1;
      }
    }

    await _storage.saveStreakCount(streak);
    await _storage.saveLastOpenDate(today.toIso8601String());
    return streak;
  }

  int getStreak() => _storage.getStreakCount();

  // ── Notification ────────────────────────────────────────────────────────────

  /// Initialise notification channels (call once in main).
  static Future<void> initNotifications(
      FlutterLocalNotificationsPlugin plugin) async {
    // Initialize timezone data for scheduled notifications
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create the Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Note: Scheduling is automatically enabled on Android 12+
    // No explicit call needed for basic scheduled notifications

    // Request POST_NOTIFICATIONS permission on Android 13+
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      if (granted == true) {
        debugPrint('Notification permission granted');
      } else {
        debugPrint('Notification permission denied or not available');
      }
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to specific screen
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Schedule a daily repeating notification.
  /// Uses [zonedSchedule] to fire every day at the specified time.
  Future<void> scheduleReminder(TimeOfDay time) async {
    // Cancel any existing reminder first
    await cancelReminder();

    final streak = _storage.getStreakCount();
    final body = _pickMessage(streak);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Study reminder',
      icon: 'ic_notification',
    );

    // Calculate the next occurrence of the reminder time
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Convert to timezone-aware DateTime
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notifications.zonedSchedule(
      id: _reminderNotificationId,
      title: '🔥 Time to Study',
      body: body,
      scheduledDate: tzScheduledDate,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.time, // Repeat daily at same time
      notificationDetails: const NotificationDetails(android: androidDetails),
    );

    // Persist reminder state
    final hhmm =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await _storage.saveReminderTime(hhmm);
    await _storage.saveReminderEnabled(true);

    debugPrint('Scheduled daily reminder at ${time.hour}:${time.minute}');
  }

  Future<void> cancelReminder() async {
    await _notifications.cancel(id: _reminderNotificationId);
    await _storage.saveReminderEnabled(false);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _pickMessage(int streak) {
    final index = Random().nextInt(_messages.length);
    final base = _messages[index];
    if (streak > 1) {
      return '🔥 Day $streak streak — $base';
    }
    return base;
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
