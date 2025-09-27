import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/models/comment_model.dart';
import 'package:poem_application/repositories/comments_repository.dart';

// Provider for CommentsRepository
final commentsRepositoryProvider = Provider<CommentsRepository>((ref) {
  return CommentsRepository(FirebaseFirestore.instance);
});

// Provider to get comments for a specific post (real-time stream)
final commentsProvider = StreamProvider.family<List<CommentModel>, String>((
  ref,
  postId,
) {
  final repository = ref.watch(commentsRepositoryProvider);
  return repository.getComments(postId);
});

// Provider to get comment count for a post
final commentCountProvider = StreamProvider.family<int, String>((ref, postId) {
  return FirebaseFirestore.instance
      .collection('posts')
      .doc(postId)
      .collection('comments')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

// Provider to check if current user has liked a comment
final isCommentLikedProvider = StreamProvider.family<bool, String>((
  ref,
  commentId,
) {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    return Stream.value(false);
  }

  return FirebaseFirestore.instance
      .collection('commentLikes')
      .doc('${commentId}_${currentUser.uid}')
      .snapshots()
      .map((doc) => doc.exists);
});

// Provider to get like count for a comment
final commentLikeCountProvider = StreamProvider.family<int, String>((
  ref,
  commentId,
) {
  return FirebaseFirestore.instance
      .collection('commentLikes')
      .where('commentId', isEqualTo: commentId)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

// Parameters class for replies provider
class RepliesParams {
  final String postId;
  final String commentId;

  RepliesParams({required this.postId, required this.commentId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepliesParams &&
          runtimeType == other.runtimeType &&
          postId == other.postId &&
          commentId == other.commentId;

  @override
  int get hashCode => postId.hashCode ^ commentId.hashCode;
}

// Provider to get replies for a specific comment
final repliesProvider =
    StreamProvider.family<List<CommentModel>, RepliesParams>((ref, params) {
      final repository = ref.watch(commentsRepositoryProvider);
      return repository.getReplies(params.postId, params.commentId);
    });
