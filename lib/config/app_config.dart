import 'package:flutter/foundation.dart';

/// Application configuration for production readiness
class AppConfig {
  // Environment
  static const bool isProduction = kReleaseMode;
  static const bool isDevelopment = kDebugMode;

  // Logging
  static const bool enableDebugLogs = kDebugMode;
  static const bool enableErrorLogs = true;

  // Feature flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;

  // API Configuration
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

  // File Upload Limits
  static const int maxImageSizeMB = 10;
  static const int maxImageSizeBytes = maxImageSizeMB * 1024 * 1024;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

  // Content Limits
  static const int maxPostTitleLength = 200;
  static const int maxPostContentLength = 5000;
  static const int maxCommentLength = 1000;
  static const int maxBioLength = 500;
  static const int maxUsernameLength = 30;
  static const int minUsernameLength = 3;

  // Pagination
  static const int postsPerPage = 20;
  static const int commentsPerPage = 50;
  static const int notificationsPerPage = 30;

  // Cache settings
  static const Duration cacheValidityDuration = Duration(hours: 24);
  static const int maxCachedImages = 100;

  // Security
  static const bool requireEmailVerification = false; // Set to true for production
  static const int passwordMinLength = 8;
  static const bool requireStrongPassword = true;

  // Rate limiting (client-side suggestions)
  static const Duration postCreationCooldown = Duration(seconds: 10);
  static const Duration commentCooldown = Duration(seconds: 3);
  static const Duration likeCooldown = Duration(milliseconds: 500);
}

/// Logger utility for production-safe logging
class AppLogger {
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (AppConfig.enableDebugLogs) {
      debugPrint('🔵 DEBUG: $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }

  static void info(String message) {
    if (AppConfig.enableDebugLogs) {
      debugPrint('ℹ️ INFO: $message');
    }
  }

  static void warning(String message, [dynamic error]) {
    if (AppConfig.enableDebugLogs || AppConfig.enableErrorLogs) {
      debugPrint('⚠️ WARNING: $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (AppConfig.enableErrorLogs) {
      debugPrint('❌ ERROR: $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
    // In production, you would also send this to a crash reporting service
    // e.g., FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  static void success(String message) {
    if (AppConfig.enableDebugLogs) {
      debugPrint('✅ SUCCESS: $message');
    }
  }

  /// Never log sensitive information
  static String sanitize(String value) {
    if (!AppConfig.enableDebugLogs) {
      return '***REDACTED***';
    }
    // In debug mode, still be careful with passwords, tokens, etc.
    return value;
  }
}
