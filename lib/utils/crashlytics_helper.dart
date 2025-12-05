import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Helper class for consistent Crashlytics error reporting throughout the app
class CrashlyticsHelper {
  /// Records a non-fatal error to Crashlytics with context
  static Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? additionalInfo,
    bool fatal = false,
  }) async {
    try {
      // Set custom keys for additional context
      if (additionalInfo != null) {
        additionalInfo.forEach((key, value) {
          FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
        });
      }

      // Record the error
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      // Silently fail if Crashlytics recording fails
      // We don't want error logging to crash the app
      print('Failed to record error to Crashlytics: $e');
    }
  }

  /// Records a FlutterError to Crashlytics
  static Future<void> recordFlutterError(dynamic error) async {
    try {
      await FirebaseCrashlytics.instance.recordFlutterFatalError(error);
    } catch (e) {
      print('Failed to record Flutter error to Crashlytics: $e');
    }
  }

  /// Logs a message to Crashlytics (useful for debugging crash context)
  static void log(String message) {
    try {
      FirebaseCrashlytics.instance.log(message);
    } catch (e) {
      print('Failed to log message to Crashlytics: $e');
    }
  }

  /// Sets user identifier for crash reports
  static Future<void> setUserIdentifier(String userId) async {
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    } catch (e) {
      print('Failed to set user identifier in Crashlytics: $e');
    }
  }

  /// Sets custom key-value data for crash reports
  static void setCustomKey(String key, dynamic value) {
    try {
      FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
    } catch (e) {
      print('Failed to set custom key in Crashlytics: $e');
    }
  }
}
