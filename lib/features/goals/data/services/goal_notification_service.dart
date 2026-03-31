import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for managing the persistent goal reminder notification.
/// This notification stays visible while the app is in the foreground
/// and is canceled when the app goes to background or is closed.
class GoalNotificationService {
  static const int _goalNotificationId = 1001;
  static const String _channelId = 'tikgood_goal_reminder';
  static const String _channelName = 'Goal Reminder';
  static const String _channelDesc =
      'Shows your current goal while using the app';

  final FlutterLocalNotificationsPlugin _notifications;

  GoalNotificationService(this._notifications);

  /// Initialize the notification channel
  static Future<void> init(FlutterLocalNotificationsPlugin plugin) async {
    // Create the Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance:
          Importance.low, // Low importance so it stays in notification panel
      playSound: false,
      enableVibration: false,
    );

    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Show a persistent notification with the current goal text
  Future<void> showGoalNotification(String goalText) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.low,
      ongoing: true, // Makes the notification persistent
      autoCancel: false, // Cancels when user taps on it
      playSound: false,
      category: AndroidNotificationCategory.service,
      enableVibration: false,
      showWhen: false, // Don't show timestamp
      icon: 'ic_notification', // Use notification icon from res folder
    );

    // Truncate long goals for notification display
    final displayText =
        goalText.length > 100 ? '${goalText.substring(0, 97)}...' : goalText;

    await _notifications.show(
      _goalNotificationId,
      '🎯 Your Goal',
      displayText,
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Cancel the goal notification (when app goes to background/closes)
  Future<void> cancelGoalNotification() async {
    await _notifications.cancel(_goalNotificationId);
  }
}
