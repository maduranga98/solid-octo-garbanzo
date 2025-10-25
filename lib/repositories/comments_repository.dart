// lib/repositories/comments_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poem_application/models/comment_model.dart';
import 'package:poem_application/models/post_model.dart';
import 'package:poem_application/services/notification_service.dart';

class CommentsRepository {
  final FirebaseFirestore firestore;
  final NotificationService _notificationService = NotificationService();

  CommentsRepository(this.firestore);

  // Get comments for a post
  Stream<List<CommentModel>> getComments(String postId) {
    return firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Add a comment with notification
  Future<CommentModel> addComment(
    String postId,
    CommentModel data,
    PostModel post,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to comment');
      }

      // Add comment to Firestore
      final docRef = await firestore
          .collection('posts')
          .doc(postId)
          .collection("comments")
          .add(data.toFirestore());

      // Increment comment count on the post
      await firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      // Get current user data for notification
      final userDoc = await firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data();
      final userName =
          userData?['name'] ?? currentUser.displayName ?? 'Someone';
      final userPhotoUrl = userData?['photoURl'] ?? currentUser.photoURL;

      // Create comment notification
      await _notificationService.createCommentNotification(
        post: post,
        commentText: data.text,
        senderName: userName,
        senderPhotoUrl: userPhotoUrl,
        commentId: docRef.id,
      );

      final snapshot = await docRef.get();
      return CommentModel.fromFirestore(snapshot);
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Add a reply with notification
  Future<CommentModel> addReply(
    String postId,
    String parentCommentId,
    CommentModel replyData,
    String postTitle,
    String originalCommentUserId,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to reply');
      }

      // Add reply to Firestore
      final docRef = await firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .add(replyData.toFirestore());

      // Increment comment count on the post
      await firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      // Get current user data for notification
      final userDoc = await firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data();
      final userName =
          userData?['name'] ?? currentUser.displayName ?? 'Someone';
      final userPhotoUrl = userData?['photoURl'] ?? currentUser.photoURL;

      // Create reply notification
      await _notificationService.createReplyNotification(
        originalCommentUserId: originalCommentUserId,
        postId: postId,
        postTitle: postTitle,
        replyText: replyData.text,
        senderName: userName,
        senderPhotoUrl: userPhotoUrl,
      );

      final snapshot = await docRef.get();
      return CommentModel.fromFirestore(snapshot);
    } catch (e) {
      throw Exception('Failed to add reply: $e');
    }
  }

  // Toggle like on a comment
  Future<bool> toggleCommentLike(String postId, String commentId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to like comments');
    }

    try {
      final likeId = '${commentId}_${currentUser.uid}';
      final likeRef = firestore.collection('commentLikes').doc(likeId);
      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // Unlike
        await likeRef.delete();
        return false;
      } else {
        // Like
        await likeRef.set({
          'commentId': commentId,
          'userId': currentUser.uid,
          'postId': postId,
          'likedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
    } catch (e) {
      throw Exception('Failed to toggle comment like: $e');
    }
  }

  // Get replies for a comment
  Stream<List<CommentModel>> getReplies(String postId, String commentId) {
    return firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Delete a comment
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // Decrement comment count
      await firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // Update a comment
  Future<void> updateComment(
    String postId,
    String commentId,
    String newComment,
  ) async {
    try {
      await firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({
            'comment': newComment,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to update comment: $e');
    }
  }
}
