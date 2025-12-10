import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:versewing/utils/crashlytics_helper.dart';

/// Service for managing Firebase Cloud Messaging (FCM) tokens and push notifications
class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Global navigator key to handle navigation from anywhere
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Initialize FCM and request notification permissions
  Future<void> initialize() async {
    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permission for notifications (iOS)
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted permission for notifications');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('✅ User granted provisional permission for notifications');
      } else {
        debugPrint(
          '⚠️ User declined or has not accepted notification permissions',
        );
      }

      // Set foreground notification presentation options
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle messages when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 Received a message while in foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint(
            'Message also contained a notification: ${message.notification}',
          );
          _showLocalNotification(message);
        }
      });

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📬 A notification was tapped and opened the app!');
        debugPrint('Message data: ${message.data}');
        _handleNotificationTap(message);
      });

      // Handle messages when app is terminated
      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📭 App opened from terminated state via notification!');
        debugPrint('Message data: ${initialMessage.data}');
        _handleNotificationTap(initialMessage);
      }

      debugPrint('✅ FCM Service initialized successfully');
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Error initializing FCM Service',
        additionalInfo: {'method': 'initialize'},
        fatal: false,
      );
      debugPrint('❌ Error initializing FCM Service: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    // ✅ FIXED: Use proper notification icon
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification', // Changed from @mipmap/ic_launcher
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Local notification tapped: ${response.payload}');
        // Handle notification tap with payload
        if (response.payload != null) {
          try {
            final data = json.decode(response.payload!);
            _navigateBasedOnData(data);
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    // ✅ FIXED: Use proper notification icon and brand color
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@drawable/ic_notification', // Changed from @mipmap/ic_launcher
      color: Color(0xFF6366F1), // VerseWing brand color
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      notificationDetails,
      payload: json.encode(message.data),
    );
  }

  /// ✅ FIXED: Handle notification tap with proper navigation
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    _navigateBasedOnData(data);
  }

  /// Navigate to appropriate screen based on notification data
  void _navigateBasedOnData(Map<String, dynamic> data) {
    final type = data['type'];
    debugPrint('🧭 Navigating based on notification type: $type');

    // Get the navigator context
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('❌ Navigator context is null, cannot navigate');
      return;
    }

    try {
      switch (type) {
        case 'like':
        case 'comment':
          // Navigate to the specific post
          final postId = data['postId'];
          if (postId != null) {
            debugPrint('📍 Navigating to post: $postId');
            // Navigate to post detail screen
            Navigator.of(
              context,
            ).pushNamed('/post-detail', arguments: {'postId': postId});
          } else {
            // If no postId, go to home feed
            _navigateToHome(context);
          }
          break;

        case 'follow':
          // Navigate to the follower's profile
          final userId = data['userId'] ?? data['followerId'];
          if (userId != null) {
            debugPrint('📍 Navigating to user profile: $userId');
            Navigator.of(
              context,
            ).pushNamed('/profile', arguments: {'userId': userId});
          } else {
            _navigateToHome(context);
          }
          break;

        case 'message':
          // Navigate to the chat
          final chatId = data['chatId'];
          if (chatId != null) {
            debugPrint('📍 Navigating to chat: $chatId');
            Navigator.of(
              context,
            ).pushNamed('/chat', arguments: {'chatId': chatId});
          } else {
            _navigateToHome(context);
          }
          break;

        case 'report_update':
          // Navigate to notifications screen
          debugPrint('📍 Navigating to notifications screen');
          Navigator.of(context).pushNamed('/notifications');
          break;

        default:
          // Default: Navigate to home feed
          debugPrint('📍 Unknown notification type, navigating to home');
          _navigateToHome(context);
          break;
      }
    } catch (e) {
      debugPrint('❌ Error during navigation: $e');
      // Fallback to home
      _navigateToHome(context);
    }
  }

  /// Navigate to home feed (default action)
  void _navigateToHome(BuildContext context) {
    debugPrint('🏠 Navigating to home feed');
    // Navigate to home and clear stack
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  /// Get the current FCM token for this device
  Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token: $token');
      return token;
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Error getting FCM token',
        additionalInfo: {'method': 'getToken'},
        fatal: false,
      );
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Update FCM token for a user in Firestore
  Future<void> updateUserToken(String userId) async {
    try {
      final token = await getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ FCM token updated for user: $userId');
      }
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Error updating user FCM token in Firestore',
        additionalInfo: {'method': 'updateUserToken', 'userId': userId},
        fatal: false,
      );
      debugPrint('❌ Error updating user FCM token: $e');
    }
  }

  /// Delete FCM token from Firestore when user signs out
  Future<void> deleteUserToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });
      await _firebaseMessaging.deleteToken();
      debugPrint('✅ FCM token deleted for user: $userId');
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Error deleting user FCM token from Firestore',
        additionalInfo: {'method': 'deleteUserToken', 'userId': userId},
        fatal: false,
      );
      debugPrint('❌ Error deleting user FCM token: $e');
    }
  }

  /// Listen to token refresh
  void listenToTokenRefresh(String userId) {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM token refreshed: $newToken');
      _firestore.collection('users').doc(userId).update({
        'fcmToken': newToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ✅ ADDED: Stub methods for backward compatibility with existing code
  // These methods don't actually send notifications anymore - Cloud Functions handle that
  // They just log that the notification will be sent by Cloud Functions

  /// Send notification when someone likes a post
  /// Note: This is now handled automatically by Cloud Functions
  /// This method exists for backward compatibility
  Future<void> sendLikeNotification({
    required String postOwnerId,
    required String likerName,
    required String postTitle,
  }) async {
    debugPrint('📤 Like notification will be sent by Cloud Functions');
    debugPrint('  Post Owner: $postOwnerId');
    debugPrint('  Liker: $likerName');
    debugPrint('  Post: $postTitle');

    // Cloud Functions automatically trigger when a like is added to Firestore
    // No need to do anything here - the notification is handled server-side
  }

  /// Send notification when someone comments on a post
  /// Note: This is now handled automatically by Cloud Functions
  /// This method exists for backward compatibility
  Future<void> sendCommentNotification({
    required String postOwnerId,
    required String commenterName,
    required String postTitle,
    required String commentText,
  }) async {
    debugPrint('📤 Comment notification will be sent by Cloud Functions');
    debugPrint('  Post Owner: $postOwnerId');
    debugPrint('  Commenter: $commenterName');
    debugPrint('  Post: $postTitle');
    debugPrint(
      '  Comment: ${commentText.substring(0, commentText.length > 50 ? 50 : commentText.length)}...',
    );

    // Cloud Functions automatically trigger when a comment is added to Firestore
    // No need to do anything here - the notification is handled server-side
  }

  /// Send notification when someone follows a user
  /// Note: This is now handled automatically by Cloud Functions
  /// This method exists for backward compatibility
  Future<void> sendFollowNotification({
    required String userId,
    required String followerName,
  }) async {
    debugPrint('📤 Follow notification will be sent by Cloud Functions');
    debugPrint('  User: $userId');
    debugPrint('  Follower: $followerName');

    // Cloud Functions automatically trigger when a follower is added to Firestore
    // No need to do anything here - the notification is handled server-side
  }

  /// Subscribe to a topic (for broadcast notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Error subscribing to FCM topic',
        additionalInfo: {'method': 'subscribeToTopic', 'topic': topic},
        fatal: false,
      );
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Error unsubscribing from FCM topic',
        additionalInfo: {'method': 'unsubscribeFromTopic', 'topic': topic},
        fatal: false,
      );
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📨 Handling a background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');

  if (message.notification != null) {
    debugPrint('Message notification: ${message.notification}');
  }
}
