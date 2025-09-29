import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/services/post_interaction_service.dart';

// Provider for PostInteractionService
final postInteractionServiceProvider = Provider<PostInteractionService>((ref) {
  return PostInteractionService();
});

// Provider to check if a post is liked by current user (real-time stream)
final isPostLikedProvider = StreamProvider.family<bool, String>((ref, postId) {
  final service = ref.watch(postInteractionServiceProvider);

  return service.likeStatusStream(postId);
});

// Provider to check if a post is bookmarked by current user (real-time stream)
final isPostBookmarkedProvider = StreamProvider.family<bool, String>((
  ref,
  postId,
) {
  final service = ref.watch(postInteractionServiceProvider);
  return service.bookmarkStatusStream(postId);
});
