import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poem_application/models/comment_model.dart';

class CommentsRepository {
  final FirebaseFirestore firestore;
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

  // Add a comment
  Future<CommentModel> addComment(String postId, CommentModel data) async {
    final docRef = await firestore
        .collection('posts')
        .doc(postId)
        .collection("comments")
        .add(data.toFirestore());

    // Increment comment count on the post
    await firestore.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });

    final snapshot = await docRef.get();
    return CommentModel.fromFirestore(snapshot);
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
        // Unlike: Remove like
        await likeRef.delete();
        return false;
      } else {
        // Like: Add like
        await likeRef.set({
          'commentId': commentId,
          'postId': postId,
          'userId': currentUser.uid,
          'likedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
    } catch (e) {
      throw Exception('Failed to toggle comment like: $e');
    }
  }

  // Check if user has liked a comment
  Future<bool> hasUserLikedComment(String commentId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    try {
      final likeId = '${commentId}_${currentUser.uid}';
      final likeDoc = await firestore
          .collection('commentLikes')
          .doc(likeId)
          .get();
      return likeDoc.exists;
    } catch (e) {
      return false;
    }
  }

  // Get comment like count
  Future<int> getCommentLikeCount(String commentId) async {
    try {
      final likesSnapshot = await firestore
          .collection('commentLikes')
          .where('commentId', isEqualTo: commentId)
          .get();
      return likesSnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Add a reply to a comment
  Future<CommentModel> addReply(
    String postId,
    String parentCommentId,
    CommentModel replyData,
  ) async {
    final docRef = await firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(parentCommentId)
        .collection('replies')
        .add(replyData.toFirestore());

    final snapshot = await docRef.get();
    return CommentModel.fromFirestore(snapshot);
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

      // Decrement comment count on the post
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
    String newText,
  ) async {
    try {
      await firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({'text': newText, 'editedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      throw Exception('Failed to update comment: $e');
    }
  }
}
