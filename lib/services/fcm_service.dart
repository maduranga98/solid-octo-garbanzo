import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for managing Firebase Cloud Messaging (FCM) tokens and push notifications
class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize FCM and request notification permissions
  Future<void> initialize() async {
    try {
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
        }
      });

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📬 A notification was tapped and opened the app!');
        debugPrint('Message data: ${message.data}');
      });

      // Handle messages when app is terminated
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📭 App opened from terminated state via notification!');
        debugPrint('Message data: ${initialMessage.data}');
      }

      debugPrint('✅ FCM Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing FCM Service: $e');
    }
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
