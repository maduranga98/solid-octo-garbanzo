import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/providers/auth_provider.dart';
import 'package:poem_application/providers/postRepositoryProvider.dart';
import 'package:poem_application/providers/post_interaction_provider.dart';
import 'package:poem_application/repositories/post_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poem_application/widgets/commentsBottomSheet.dart';
import 'package:poem_application/widgets/fullPostBottomSheet.dart';
import 'package:timeago/timeago.dart' as timeago;

class SavedPostScreen extends ConsumerStatefulWidget {
  const SavedPostScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SavedPostScreenState();
}

class _SavedPostScreenState extends ConsumerState<SavedPostScreen> {
  Future<void> _removeSavedPost(String userId, String postId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(postId)
          .delete();

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Removed from saved posts'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleLike(SavedPost savedPost) async {
    final service = ref.read(postInteractionServiceProvider);

    try {
      await service.toggleLike(savedPost.postData);
      if (mounted) {
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like post: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showPostDetails(SavedPost savedPost) {
    FullPostBottomSheet.show(
      context,
      post: savedPost.postData,
      onLike: () => _handleLike(savedPost),
      onComment: () => _showComments(savedPost),
      onShare: () {
        final service = ref.read(postInteractionServiceProvider);
        service.sharePost(savedPost.postData, context);
      },
    );
  }

  void _showComments(SavedPost savedPost) {
    CommentsBottomSheet.show(context, post: savedPost.postData);
  }

  @override
  Widget build(BuildContext context) {
    final currentuser = ref.watch(firebaseAuthProvider).currentUser;
    final savedPostsAsync = ref.watch(savedPostByUIDProvider(currentuser!.uid));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        title: Text(
          'Saved Posts',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: savedPostsAsync.when(
        data: (savedPosts) {
          if (savedPosts.isEmpty) {
            return _buildEmptyState(colorScheme, theme);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(savedPostByUIDProvider(currentuser.uid));
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: savedPosts.length,
              itemBuilder: (context, index) {
                final savedPost = savedPosts[index];
                return _buildPostCard(
                  savedPost,
                  currentuser.uid,
                  theme,
                  colorScheme,
                );
              },
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: colorScheme.primary,
          ),
        ),
        error: (error, stack) =>
            _buildErrorState(error, currentuser.uid, theme, colorScheme),
      ),
    );
  }

  Widget _buildPostCard(
    SavedPost savedPost,
    String userId,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Watch like status
    final isLikedAsync = ref.watch(
      isPostLikedProvider(savedPost.postData.docId),
    );
    final isLiked = isLikedAsync.value ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showPostDetails(savedPost),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Author and Timestamp
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            savedPost.postData.authorName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.bookmark_rounded,
                      size: 16,
                      color: colorScheme.primary.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeago.format(savedPost.savedData.bookmarkedAt.toDate()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Post Content
                Text(
                  savedPost.postData.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  savedPost.postData.richText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.8),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Divider
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                ),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    // Like Button
                    _buildActionButton(
                      icon: isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: '${savedPost.postData.likeCount ?? 0}',
                      color: isLiked ? Colors.red : colorScheme.onSurface,
                      onTap: () => _handleLike(savedPost),
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 8),

                    // Comment Button
                    _buildActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: '${savedPost.postData.commentCount ?? 0}',
                      color: colorScheme.onSurface,
                      onTap: () => _showComments(savedPost),
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                    const Spacer(),

                    // Remove Bookmark Button
                    _buildIconButton(
                      icon: Icons.bookmark_remove_rounded,
                      color: colorScheme.primary,
                      onTap: () =>
                          _removeSavedPost(userId, savedPost.savedData.postId),
                      tooltip: 'Remove from saved',
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color.withOpacity(0.9)),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
    required ColorScheme colorScheme,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_outline_rounded,
              size: 56,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No saved posts yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Posts you bookmark will appear here for easy access later',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    Object error,
    String userId,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(savedPostByUIDProvider(userId));
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
