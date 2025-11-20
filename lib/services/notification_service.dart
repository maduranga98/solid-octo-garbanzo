// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inkwing/models/notification_model.dart';
import 'package:inkwing/models/post_model.dart';
import 'package:inkwing/utils/crashlytics_helper.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============ CREATE NOTIFICATIONS ============

  /// Create a notification for a like on a post
  Future<void> createLikeNotification({
    required PostModel post,
    required String senderName,
    String? senderPhotoUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Don't create notification if user likes their own post
    if (currentUser.uid == post.createdBy) return;

    try {
      final notification = NotificationModel(
        recipientId: post.createdBy,
        senderId: currentUser.uid,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        type: NotificationType.like,
        postId: post.docId,
        postTitle: post.title.isNotEmpty
            ? post.title
            : post.plainText.substring(0, 50),
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(post.createdBy)
          .collection('notifications')
          .add(notification.toFirestore());

      // Update unread count
      await _incrementUnreadCount(post.createdBy);
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Error in createLikeNotification creating like notification',
        additionalInfo: {
          'postId': post.docId,
          'postOwnerId': post.createdBy,
          'senderId': currentUser?.uid,
        },
        fatal: false,
      );
      print('Error creating like notification: $e');
    }
  }

  /// Create a notification for a comment on a post
  Future<void> createCommentNotification({
    required PostModel post,
    required String commentText,
    required String senderName,
    String? senderPhotoUrl,
    String? commentId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Don't create notification if user comments on their own post
    if (currentUser.uid == post.createdBy) return;

    try {
      final notification = NotificationModel(
        recipientId: post.createdBy,
        senderId: currentUser.uid,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        type: NotificationType.comment,
        postId: post.docId,
        postTitle: post.title.isNotEmpty
            ? post.title
            : post.plainText.substring(0, 50),
        commentId: commentId,
        commentText: commentText.length > 100
            ? '${commentText.substring(0, 100)}...'
            : commentText,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(post.createdBy)
          .collection('notifications')
          .add(notification.toFirestore());

      // Update unread count
      await _incrementUnreadCount(post.createdBy);
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Error in createCommentNotification creating comment notification',
        additionalInfo: {
          'postId': post.docId,
          'postOwnerId': post.createdBy,
          'senderId': currentUser?.uid,
          'commentId': commentId,
        },
        fatal: false,
      );
      print('Error creating comment notification: $e');
    }
  }

  /// Create a notification for a reply to a comment
  Future<void> createReplyNotification({
    required String originalCommentUserId,
    required String postId,
    required String postTitle,
    required String replyText,
    required String senderName,
    String? senderPhotoUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Don't create notification if user replies to their own comment
    if (currentUser.uid == originalCommentUserId) return;

    try {
      final notification = NotificationModel(
        recipientId: originalCommentUserId,
        senderId: currentUser.uid,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        type: NotificationType.reply,
        postId: postId,
        postTitle: postTitle,
        commentText: replyText.length > 100
            ? '${replyText.substring(0, 100)}...'
            : replyText,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(originalCommentUserId)
          .collection('notifications')
          .add(notification.toFirestore());

      // Update unread count
      await _incrementUnreadCount(originalCommentUserId);
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Error in createReplyNotification creating reply notification',
        additionalInfo: {
          'postId': postId,
          'recipientId': originalCommentUserId,
          'senderId': currentUser?.uid,
        },
        fatal: false,
      );
      print('Error creating reply notification: $e');
    }
  }

  /// Create a notification for a follow
  Future<void> createFollowNotification({
    required String followedUserId,
    required String senderName,
    String? senderPhotoUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final notification = NotificationModel(
        recipientId: followedUserId,
        senderId: currentUser.uid,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        type: NotificationType.follow,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(followedUserId)
          .collection('notifications')
          .add(notification.toFirestore());

      // Update unread count
      await _incrementUnreadCount(followedUserId);
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Error in createFollowNotification creating follow notification',
        additionalInfo: {
          'followedUserId': followedUserId,
          'senderId': currentUser?.uid,
        },
        fatal: false,
      );
      print('Error creating follow notification: $e');
    }
  }

  // ============ READ NOTIFICATIONS ============

  /// Get notifications stream for a user
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get unread notifications count
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      await _decrementUnreadCount(userId);
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Error in markAsRead marking notification as read',
        additionalInfo: {
          'userId': userId,
          'notificationId': notificationId,
        },
        fatal: false,
      );
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final unreadNotifications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      // Reset unread count
      await _firestore.collection('users').doc(userId).update({
        'unreadNotificationCount': 0,
      });
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Error in markAllAsRead marking all notifications as read',
        additionalInfo: {
          'userId': userId,
        },
        fatal: false,
      );
      print('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Error in deleteNotification deleting notification',
        additionalInfo: {
          'userId': userId,
          'notificationId': notificationId,
        },
        fatal: false,
      );
      print('Error deleting notification: $e');
    }
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final notifications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      final batch = _firestore.batch();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Reset unread count
      await _firestore.collection('users').doc(userId).update({
        'unreadNotificationCount': 0,
      });
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Error in deleteAllNotifications deleting all notifications',
        additionalInfo: {
          'userId': userId,
        },
        fatal: false,
      );
      print('Error deleting all notifications: $e');
    }
  }

  // ============ HELPER METHODS ============

  /// Increment unread notification count
  Future<void> _incrementUnreadCount(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'unreadNotificationCount': FieldValue.increment(1),
      });
    } catch (e, stackTrace) {
      // If field doesn't exist, create it
      try {
        await _firestore.collection('users').doc(userId).set({
          'unreadNotificationCount': 1,
        }, SetOptions(merge: true));
      } catch (e2, stackTrace2) {
        await CrashlyticsHelper.recordError(
          e2,
          stackTrace2,
          reason: 'Error in _incrementUnreadCount creating unread count field',
          additionalInfo: {
            'userId': userId,
            'originalError': e.toString(),
          },
          fatal: false,
        );
      }
    }
  }

  /// Decrement unread notification count
  Future<void> _decrementUnreadCount(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'unreadNotificationCount': FieldValue.increment(-1),
      });
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Error in _decrementUnreadCount decrementing unread count',
        additionalInfo: {
          'userId': userId,
        },
        fatal: false,
      );
      print('Error decrementing unread count: $e');
    }
  }

  /// Remove like notification when user unlikes
  Future<void> removeLikeNotification({
    required String postOwnerId,
    required String postId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final notifications = await _firestore
          .collection('users')
          .doc(postOwnerId)
          .collection('notifications')
          .where('senderId', isEqualTo: currentUser.uid)
          .where('postId', isEqualTo: postId)
          .where('type', isEqualTo: 'like')
          .get();

      final batch = _firestore.batch();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);

        // Decrement unread count if notification was unread
        if (!(doc.data()['isRead'] ?? false)) {
          await _decrementUnreadCount(postOwnerId);
        }
      }

      await batch.commit();
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Error in removeLikeNotification removing like notification',
        additionalInfo: {
          'postOwnerId': postOwnerId,
          'postId': postId,
          'senderId': currentUser?.uid,
        },
        fatal: false,
      );
      print('Error removing like notification: $e');
    }
  }
}
