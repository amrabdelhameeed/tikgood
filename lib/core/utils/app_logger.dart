import 'package:flutter/foundation.dart';

/// Debug-only logger that suppresses all output in release builds.
///
/// Replaces raw `print()` statements to prevent sensitive data leakage
/// via `adb logcat` or iOS Console in production.
class AppLogger {
  AppLogger._();

  /// Debug log — only prints in debug mode.
  static void d(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  /// Warning log — only prints in debug mode.
  static void w(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('⚠️ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  /// Error log — only prints in debug mode.
  static void e(String message,
      {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('❌ ${tag != null ? '[$tag] ' : ''}$message');
      if (error != null) debugPrint('   Error: $error');
      if (stackTrace != null) debugPrint('   StackTrace: $stackTrace');
    }
  }
}
