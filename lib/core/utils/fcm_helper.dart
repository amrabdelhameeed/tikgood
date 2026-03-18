import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final messaging = FirebaseMessaging.instance;

  // Call this in main() - only basic setup
  static Future<void> initializeBasic() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon_adaptive_fore');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings);

    // Request permissions
    final NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Notification: Permission granted');
    } else {
      debugPrint('Notification: Permission denied');
    }

    // When the app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Notification: onMessage received');
      await handleNotification(message.toMap());
    });
  }

  static Future<void> handleNotification(Map<String, dynamic> message) async {
    final NotificationData data = NotificationData.fromMap(message);
    if (data.title.isNotEmpty && data.body.isNotEmpty) {
      await _showLocalNotification(data);
    }
  }

  static Future<void> _showLocalNotification(NotificationData data) async {
    final int notificationId = Random().nextInt(54552);

    const androidDetails = AndroidNotificationDetails(
      'TikGood',
      'TikGood Notifications',
      icon: '@mipmap/ic_launcher',
      visibility: NotificationVisibility.public,
      groupAlertBehavior: GroupAlertBehavior.all,
      color: Color(0xFFFE2C55),
      colorized: true,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    final String payload = json.encode(
        {"id": data.id?.toString() ?? "", "type": data.screenName ?? ""});

    await flutterLocalNotificationsPlugin.show(
      id: notificationId,
      title: data.title,
      body: data.body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  static Future subscribeToTopic(String topic) async =>
      await messaging.subscribeToTopic(topic);
  static Future unSubscribeToTopic(String topic) async =>
      await messaging.unsubscribeFromTopic(topic);
}

class NotificationData {
  final String title;
  final String body;
  final int? id;
  final String? screenName;

  NotificationData(
      {required this.title, required this.body, this.id, this.screenName});

  factory NotificationData.fromMap(Map<String, dynamic> map) {
    return NotificationData(
      title: map['notification']?['title'] ?? '',
      body: map['notification']?['body'] ?? '',
      id: int.tryParse((map['data']?['id'] ?? "").toString()),
      screenName: map['data']?['type']?.toString(),
    );
  }
}
