import 'package:flutter/services.dart';

class AccessibilityInterceptService {
  static const _channel =
      MethodChannel('id.amrabdelhameed.tikgood/accessibility');

  /// Opens Android Accessibility Settings
  static Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  /// Returns true if TikTokInterceptService is currently enabled
  static Future<bool> isServiceEnabled() async {
    return await _channel.invokeMethod<bool>('isServiceEnabled') ?? false;
  }

  /// Requests SYSTEM_ALERT_WINDOW permission if not already granted
  static Future<void> requestOverlayPermission() async {
    await _channel.invokeMethod('requestOverlayPermission');
  }
}
