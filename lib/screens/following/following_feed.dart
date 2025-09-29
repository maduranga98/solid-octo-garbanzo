// lib/screens/following/following_feed.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/models/post_model.dart';
import 'package:poem_application/providers/auth_provider.dart';
import 'package:poem_application/providers/postRepositoryProvider.dart';
import 'package:poem_application/providers/post_interaction_provider.dart';
import 'package:poem_application/providers/user_provider.dart';
import 'package:poem_application/widgets/commentsBottomSheet.dart';
import 'package:poem_application/widgets/fullPostBottomSheet.dart';
import 'package:timeago/timeago.dart' as timeago;

class FollowingFeedScreen extends ConsumerWidget {
  const FollowingFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = ref.watch(firebaseAuthProvider).currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Following')),
        body: const Center(
          child: Text('Please sign in to see posts from followed users'),
        ),
      );
    }

    final followingPostsAsync = ref.watch(
      followingPostsProvider(currentUser.uid),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        title: Text(
          'Following',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(followingPostsProvider(currentUser.uid));
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: followingPostsAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
              return _buildEmptyState(theme, colorScheme);
            }

            return ListView.separated(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: posts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final post = posts[index];
                return _FollowingPostCard(post: post);
              },
            );
          },
          loading: () => _buildLoadingState(colorScheme),
          error: (error, stack) =>
              _buildErrorState(error, theme, colorScheme, ref, currentUser.uid),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No posts from followed users',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow creators to see their posts here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.surfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 12,
                          width: 80,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(
    Object error,
    ThemeData theme,
    ColorScheme colorScheme,
    WidgetRef ref,
    String userId,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(followingPostsProvider(userId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowingPostCard extends ConsumerWidget {
  final PostModel post;

  const _FollowingPostCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userAsync = ref.watch(getUserDataProvider(post.createdBy));
    final currentUser = ref.watch(firebaseAuthProvider).currentUser;

    return GestureDetector(
      onTap: () => _showFullPost(context, ref, post),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Author Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  userAsync.when(
                    data: (user) {
                      if (user == null) {
                        return CircleAvatar(
                          radius: 20,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person,
                            color: colorScheme.onPrimaryContainer,
                            size: 20,
                          ),
                        );
                      }
                      return CircleAvatar(
                        radius: 20,
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage:
                            user.photoURl != null && user.photoURl!.isNotEmpty
                            ? NetworkImage(user.photoURl!)
                            : null,
                        child: user.photoURl == null || user.photoURl!.isEmpty
                            ? Text(
                                user.userName.isNotEmpty
                                    ? user.userName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      );
                    },
                    loading: () => CircleAvatar(
                      radius: 20,
                      backgroundColor: colorScheme.surfaceVariant,
                    ),
                    error: (_, __) => CircleAvatar(
                      radius: 20,
                      backgroundColor: colorScheme.errorContainer,
                      child: Icon(
                        Icons.error_outline,
                        color: colorScheme.onErrorContainer,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        userAsync.when(
                          data: (user) => Text(
                            user?.userName ?? 'Unknown User',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          loading: () => Container(
                            height: 14,
                            width: 100,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          error: (_, __) => Text(
                            'Unknown User',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              timeago.format(
                                post.createdAt,
                                locale: 'en_short',
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getWorkTypeColor(
                                  post.workType,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                post.workType.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: _getWorkTypeColor(post.workType),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Following Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Following',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (post.title.isNotEmpty) ...[
                    Text(
                      post.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    post.plainText,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Engagement Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (post.hasLikes)
                    Flexible(
                      child: Text(
                        '${post.likeCount} ${post.likeCount == 1 ? 'like' : 'likes'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (post.hasLikes && post.hasComments)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '•',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  if (post.hasComments)
                    Flexible(
                      child: Text(
                        '${post.commentCount} ${post.commentCount == 1 ? 'comment' : 'comments'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Spacer(),
                  if (post.hasViews)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.viewCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Divider(
              color: colorScheme.outline.withValues(alpha: 0.2),
              height: 1,
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final isLikedAsync = ref.watch(
                          isPostLikedProvider(post.docId),
                        );

                        return isLikedAsync.when(
                          data: (isLiked) => _buildActionButton(
                            context,
                            icon: isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            label: 'Like',
                            onTap: () => _handleLike(context, ref, post),
                            isActive: isLiked,
                            activeColor: Colors.red,
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                          loading: () => _buildActionButton(
                            context,
                            icon: Icons.favorite_border,
                            label: 'Like',
                            onTap: () => _handleLike(context, ref, post),
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                          error: (_, __) => _buildActionButton(
                            context,
                            icon: Icons.favorite_border,
                            label: 'Like',
                            onTap: () => _handleLike(context, ref, post),
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.chat_bubble_outline,
                      label: 'Comment',
                      onTap: () => _handleComment(context, post),
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                  ),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: () => _handleShare(context, ref, post),
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                  ),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final isBookmarkedAsync = ref.watch(
                          isPostBookmarkedProvider(post.docId),
                        );

                        return isBookmarkedAsync.when(
                          data: (isBookmarked) => _buildActionButton(
                            context,
                            icon: isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            label: 'Save',
                            onTap: () => _handleSave(context, ref, post),
                            isActive: isBookmarked,
                            activeColor: Colors.amber,
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                          loading: () => _buildActionButton(
                            context,
                            icon: Icons.bookmark_border,
                            label: 'Save',
                            onTap: () => _handleSave(context, ref, post),
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                          error: (_, __) => _buildActionButton(
                            context,
                            icon: Icons.bookmark_border,
                            label: 'Save',
                            onTap: () => _handleSave(context, ref, post),
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
    bool isActive = false,
    Color? activeColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? (activeColor ?? colorScheme.primary)
                    : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isActive
                      ? (activeColor ?? colorScheme.primary)
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getWorkTypeColor(String workType) {
    switch (workType.toLowerCase()) {
      case 'poetry':
        return const Color(0xFF6366F1);
      case 'lyrics':
        return const Color(0xFF10B981);
      case 'stories':
        return const Color(0xFF8B5CF6);
      case 'scripts':
        return const Color(0xFFF59E0B);
      case 'essays':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6366F1);
    }
  }

  void _handleComment(BuildContext context, PostModel post) {
    CommentsBottomSheet.show(context, post: post);
  }

  void _handleShare(BuildContext context, WidgetRef ref, PostModel post) async {
    final service = ref.read(postInteractionServiceProvider);
    HapticFeedback.mediumImpact();
    await service.sharePost(post, context);
  }

  void _handleLike(BuildContext context, WidgetRef ref, PostModel post) async {
    final service = ref.read(postInteractionServiceProvider);

    try {
      await service.toggleLike(post);
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like post: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _handleSave(BuildContext context, WidgetRef ref, PostModel post) async {
    final service = ref.read(postInteractionServiceProvider);

    try {
      await service.toggleBookmark(post);
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save post: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _showFullPost(BuildContext context, WidgetRef ref, PostModel post) {
    FullPostBottomSheet.show(
      context,
      post: post,
      onLike: () => _handleLike(context, ref, post),
      onComment: () => _handleComment(context, post),
      onShare: () => _handleShare(context, ref, post),
    );
  }
}
