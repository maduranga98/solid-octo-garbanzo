// lib/services/post_interaction_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poem_application/models/post_model.dart';
import 'package:poem_application/services/notification_service.dart';
import 'package:poem_application/services/fcm_service.dart';
import 'package:share_plus/share_plus.dart';

class PostInteractionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final FCMService _fcmService = FCMService();

  // ============ LIKE FUNCTIONALITY ============

  /// Toggle like on a post
  Future<bool> toggleLike(PostModel post) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to like posts');
    }

    try {
      final likeRef = _firestore
          .collection('posts')
          .doc(post.docId)
          .collection('likes')
          .doc(currentUser.uid);

      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // Unlike: Remove like and decrement count
        await likeRef.delete();
        await _firestore.collection('posts').doc(post.docId).update({
          'likeCount': FieldValue.increment(-1),
        });

        // Remove like notification (async, don't wait)
        _notificationService.removeLikeNotification(
          postOwnerId: post.createdBy,
          postId: post.docId,
        ).catchError((e) => print('Error removing notification: $e'));

        return false; // Post is now unliked
      } else {
        // Like: Add like and increment count
        await likeRef.set({
          'userId': currentUser.uid,
          'likedAt': FieldValue.serverTimestamp(),
        });
        await _firestore.collection('posts').doc(post.docId).update({
          'likeCount': FieldValue.increment(1),
        });

        // Create notifications asynchronously (fire and forget)
        _createLikeNotificationsAsync(currentUser, post);

        return true; // Post is now liked
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// Check if current user has liked a post
  Future<bool> hasUserLikedPost(String postId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final likeDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(currentUser.uid)
          .get();

      return likeDoc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Stream to listen to like status changes
  Stream<bool> likeStatusStream(String postId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(currentUser.uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Get list of users who liked a post
  Future<List<String>> getPostLikers(String postId, {int limit = 50}) async {
    try {
      final likesSnapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .orderBy('likedAt', descending: true)
          .limit(limit)
          .get();

      return likesSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  // ============ SHARE FUNCTIONALITY ============

  /// Share a post using the native share dialog
  Future<void> sharePost(PostModel post, BuildContext context) async {
    try {
      // Increment share count in Firestore
      await _firestore.collection('posts').doc(post.docId).update({
        'shareCount': FieldValue.increment(1),
      });

      // Create share text
      final String shareText = _buildShareText(post);

      // Share using share_plus package
      final result = await Share.share(
        shareText,
        subject: post.title.isNotEmpty
            ? post.title
            : 'Check out this post on Poetic',
      );

      if (result.status == ShareResultStatus.success) {
        _showSuccessMessage(context, 'Post shared successfully!');
      }
    } catch (e) {
      _showErrorMessage(context, 'Failed to share post: $e');
    }
  }

  /// Share a post with custom text
  Future<void> sharePostWithCustomText(
    PostModel post,
    String customText,
    BuildContext context,
  ) async {
    try {
      await _firestore.collection('posts').doc(post.docId).update({
        'shareCount': FieldValue.increment(1),
      });

      await Share.share(customText);
    } catch (e) {
      _showErrorMessage(context, 'Failed to share post: $e');
    }
  }

  /// Copy post link to clipboard
  Future<void> copyPostLink(PostModel post, BuildContext context) async {
    try {
      // Create a shareable link (replace with your actual deep link)
      final postLink = 'https://poetic.app/post/${post.docId}';

      await Clipboard.setData(ClipboardData(text: postLink));

      _showSuccessMessage(context, 'Link copied to clipboard!');
    } catch (e) {
      _showErrorMessage(context, 'Failed to copy link: $e');
    }
  }

  /// Share via specific platform (optional - requires platform-specific implementation)
  Future<void> shareToSpecificPlatform(
    PostModel post,
    String platform,
    BuildContext context,
  ) async {
    // This would require additional packages like flutter_sharing_intent
    // or platform-specific code
    final shareText = _buildShareText(post);

    try {
      await Share.share(shareText);
    } catch (e) {
      _showErrorMessage(context, 'Failed to share: $e');
    }
  }

  // ============ HELPER METHODS ============

  /// Build formatted share text
  String _buildShareText(PostModel post) {
    final buffer = StringBuffer();

    if (post.title.isNotEmpty) {
      buffer.writeln('📖 ${post.title}');
      buffer.writeln();
    }

    if (post.description.isNotEmpty) {
      buffer.writeln(post.description);
      buffer.writeln();
    }

    // Add preview of content (first 200 characters)
    final preview = post.plainText.length > 200
        ? '${post.plainText.substring(0, 200)}...'
        : post.plainText;

    buffer.writeln(preview);
    buffer.writeln();

    buffer.writeln('By ${post.authorName}');
    buffer.writeln();

    // Add app link (replace with your actual link)
    buffer.writeln(
      'Read more on Poetic: https://poetic.app/post/${post.docId}',
    );

    return buffer.toString();
  }

  /// Show success message
  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error message
  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============ SAVE/BOOKMARK FUNCTIONALITY ============

  /// Toggle bookmark on a post
  Future<bool> toggleBookmark(PostModel post) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to bookmark posts');
    }

    try {
      final bookmarkRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('bookmarks')
          .doc(post.docId);

      final bookmarkDoc = await bookmarkRef.get();

      if (bookmarkDoc.exists) {
        // Remove bookmark
        await bookmarkRef.delete();
        return false; // Post is now unbookmarked
      } else {
        // Add bookmark
        await bookmarkRef.set({
          'postId': post.docId,
          'bookmarkedAt': FieldValue.serverTimestamp(),
          'postTitle': post.title,
          'postAuthor': post.authorName,
        });
        return true; // Post is now bookmarked
      }
    } catch (e) {
      throw Exception('Failed to toggle bookmark: $e');
    }
  }

  /// Check if user has bookmarked a post
  Future<bool> hasUserBookmarkedPost(String postId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final bookmarkDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('bookmarks')
          .doc(postId)
          .get();

      return bookmarkDoc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Stream to listen to bookmark status changes
  Stream<bool> bookmarkStatusStream(String postId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('bookmarks')
        .doc(postId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Get user's bookmarked posts
  Future<List<String>> getUserBookmarks({int limit = 50}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    try {
      final bookmarksSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('bookmarks')
          .orderBy('bookmarkedAt', descending: true)
          .limit(limit)
          .get();

      return bookmarksSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  // Helper method to create notifications asynchronously
  void _createLikeNotificationsAsync(User currentUser, PostModel post) {
    () async {
      try {
        // Get current user data for notification
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        final userData = userDoc.data();
        final userName =
            userData?['name'] ?? currentUser.displayName ?? 'Someone';
        final userPhotoUrl = userData?['photoURl'] ?? currentUser.photoURL;

        // Create like notification
        await _notificationService.createLikeNotification(
          post: post,
          senderName: userName,
          senderPhotoUrl: userPhotoUrl,
        );

        // Send push notification to post owner
        if (post.createdBy != currentUser.uid) {
          await _fcmService.sendLikeNotification(
            postOwnerId: post.createdBy,
            likerName: userName,
            postTitle: post.title.isNotEmpty ? post.title : 'your post',
          );
        }
      } catch (e) {
        print('Error creating like notifications: $e');
      }
    }();
  }
}
