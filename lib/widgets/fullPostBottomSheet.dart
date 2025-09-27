import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/models/post_model.dart';
import 'package:poem_application/providers/auth_provider.dart';
import 'package:poem_application/providers/user_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class FullPostBottomSheet extends ConsumerWidget {
  final PostModel post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const FullPostBottomSheet({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  static void show(
    BuildContext context, {
    required PostModel post,
    VoidCallback? onLike,
    VoidCallback? onComment,
    VoidCallback? onShare,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FullPostBottomSheet(
          post: post,
          onLike: onLike,
          onComment: onComment,
          onShare: onShare,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Increment view count when bottom sheet opens
    _incrementViewCount(ref);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHandleBar(colorScheme),
              _buildHeader(context, ref, theme, colorScheme),
              Divider(color: colorScheme.outline.withOpacity(0.2), height: 1),
              Expanded(
                child: _buildContent(scrollController, theme, colorScheme),
              ),
              _buildActionButtons(context, theme, colorScheme),
            ],
          ),
        );
      },
    );
  }

  /// Increment view count only if viewer is not the post author
  Future<void> _incrementViewCount(WidgetRef ref) async {
    try {
      final currentUser = ref.read(firebaseAuthProvider).currentUser;

      // Only increment if user is logged in and is not the post author
      if (currentUser != null && currentUser.uid != post.createdBy) {
        await FirebaseFirestore.instance
            .collection("posts")
            .doc(post.docId)
            .update({"viewCount": FieldValue.increment(1)});
      }
    } catch (e) {
      // Silently fail - view count is not critical
      print('Error incrementing view count: $e');
    }
  }

  Widget _buildHandleBar(ColorScheme colorScheme) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.outline.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final userAsync = ref.watch(getUserDataProvider(post.createdBy));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      timeago.format(post.createdAt, locale: 'en_short'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
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
                        ).withOpacity(0.1),
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
          IconButton(
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    ScrollController scrollController,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (post.title.isNotEmpty) ...[
            Text(
              post.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Description
          if (post.description.isNotEmpty) ...[
            Text(
              post.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Main content
          SelectableText(
            post.plainText,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
              height: 1.8,
              fontSize: post.fontSize?.toDouble() ?? 16,
              fontFamily: post.fontFamily,
            ),
          ),

          const SizedBox(height: 32),

          // Engagement stats
          _buildEngagementStats(theme, colorScheme),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEngagementStats(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            icon: Icons.favorite_border,
            count: post.likeCount ?? 0,
            label: 'Likes',
            color: Colors.red,
            theme: theme,
            colorScheme: colorScheme,
          ),
          _buildStatColumn(
            icon: Icons.chat_bubble_outline,
            count: post.commentCount ?? 0,
            label: 'Comments',
            color: Colors.blue,
            theme: theme,
            colorScheme: colorScheme,
          ),
          _buildStatColumn(
            icon: Icons.share_outlined,
            count: post.shareCount ?? 0,
            label: 'Shares',
            color: Colors.green,
            theme: theme,
            colorScheme: colorScheme,
          ),
          _buildStatColumn(
            icon: Icons.visibility_outlined,
            count: post.viewCount ?? 0,
            label: 'Views',
            color: Colors.orange,
            theme: theme,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onLike?.call();
              },
              icon: const Icon(Icons.favorite_border, size: 18),
              label: const Text('Like'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onComment?.call();
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Comment'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed: () {
              Navigator.pop(context);
              onShare?.call();
            },
            icon: const Icon(Icons.share_outlined, size: 20),
          ),
        ],
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
}
