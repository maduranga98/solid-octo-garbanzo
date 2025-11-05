import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

/// Service for managing Firebase Cloud Messaging (FCM) tokens and push notifications
class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM and request notification permissions
  Future<void> initialize() async {
    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permission for notifications (iOS)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
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
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('✅ User granted provisional permission for notifications');
      } else {
        debugPrint('⚠️ User declined or has not accepted notification permissions');
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
          debugPrint('Message also contained a notification: ${message.notification}');
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
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📭 App opened from terminated state via notification!');
        debugPrint('Message data: ${initialMessage.data}');
        _handleNotificationTap(initialMessage);
      }

      debugPrint('✅ FCM Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing FCM Service: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
        // Handle notification tap
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
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
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

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    debugPrint('Handling notification of type: $type');
    // TODO: Navigate to appropriate screen based on notification type
    // This can be implemented based on your app's routing logic
  }

  /// Get the current FCM token for this device
  Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token: $token');
      return token;
    } catch (e) {
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
        });
        debugPrint('✅ FCM token updated for user: $userId');
      }
    } catch (e) {
      debugPrint('❌ Error updating user FCM token: $e');
    }
  }

  /// Delete FCM token from Firestore when user signs out
  Future<void> deleteUserToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
      await _firebaseMessaging.deleteToken();
      debugPrint('✅ FCM token deleted for user: $userId');
    } catch (e) {
      debugPrint('❌ Error deleting user FCM token: $e');
    }
  }

  /// Listen to token refresh
  void listenToTokenRefresh(String userId) {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM token refreshed: $newToken');
      _firestore.collection('users').doc(userId).update({
        'fcmToken': newToken,
      });
    });
  }

  /// Send a notification to a specific user
  /// Note: This requires a backend server with Firebase Admin SDK
  /// For client-side implementation, you'll need to use Cloud Functions or your backend
  Future<void> sendNotificationToUser({
    required String recipientUserId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get recipient's FCM token from Firestore
      final userDoc = await _firestore.collection('users').doc(recipientUserId).get();

      if (!userDoc.exists) {
        debugPrint('❌ User document not found for: $recipientUserId');
        return;
      }

      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ No FCM token found for user: $recipientUserId');
        return;
      }

      // TODO: This should be called from a backend server or Cloud Function
      // For now, we'll just log the notification details
      debugPrint('📤 Would send notification:');
      debugPrint('  To: $fcmToken');
      debugPrint('  Title: $title');
      debugPrint('  Body: $body');
      debugPrint('  Data: $data');

      // NOTE: Sending notifications from client is NOT recommended for production
      // You should set up a backend service or Firebase Cloud Function
      // Example Cloud Function implementation is provided below:
      /*

      // Firebase Cloud Function (Node.js)
      const functions = require('firebase-functions');
      const admin = require('firebase-admin');
      admin.initializeApp();

      exports.sendNotification = functions.https.onCall(async (data, context) => {
        const { token, title, body, data: notificationData } = data;

        const message = {
          notification: { title, body },
          data: notificationData || {},
          token: token,
        };

        try {
          const response = await admin.messaging().send(message);
          return { success: true, response };
        } catch (error) {
          throw new functions.https.HttpsError('internal', error.message);
        }
      });

      */
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  /// Send notification when someone likes a post
  Future<void> sendLikeNotification({
    required String postOwnerId,
    required String likerName,
    required String postTitle,
  }) async {
    // Don't send notification if user likes their own post
    // This check should be done before calling this method

    await sendNotificationToUser(
      recipientUserId: postOwnerId,
      title: '❤️ New Like',
      body: '$likerName liked your post "$postTitle"',
      data: {
        'type': 'like',
        'postOwnerId': postOwnerId,
        'likerName': likerName,
      },
    );
  }

  /// Send notification when someone comments on a post
  Future<void> sendCommentNotification({
    required String postOwnerId,
    required String commenterName,
    required String postTitle,
    required String commentText,
  }) async {
    // Don't send notification if user comments on their own post
    // This check should be done before calling this method

    await sendNotificationToUser(
      recipientUserId: postOwnerId,
      title: '💬 New Comment',
      body: '$commenterName commented on your post "$postTitle"',
      data: {
        'type': 'comment',
        'postOwnerId': postOwnerId,
        'commenterName': commenterName,
        'commentText': commentText,
      },
    );
  }

  /// Subscribe to a topic (for broadcast notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
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
