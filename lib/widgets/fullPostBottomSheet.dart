import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:poem_application/models/post_model.dart';
import 'package:poem_application/providers/auth_provider.dart';
import 'package:poem_application/providers/user_provider.dart';
import 'package:poem_application/screens/profile/user_profile.dart';
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
              Divider(
                color: colorScheme.outline.withValues(alpha: 0.2),
                height: 1,
              ),
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
        color: colorScheme.outline.withValues(alpha: 0.3),
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
          // Avatar with navigation
          GestureDetector(
            onTap: () {
              Navigator.pop(context); // Close the bottom sheet first
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfile(userId: post.createdBy),
                ),
              );
            },
            child: userAsync.when(
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
          ),
          const SizedBox(width: 12),
          // Username and metadata with navigation
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet first
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfile(userId: post.createdBy),
                  ),
                );
              },
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
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
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
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Main content with rich text formatting
          _buildRichTextContent(theme, colorScheme),

          const SizedBox(height: 24),

          // Engagement stats
          _buildEngagementStats(theme, colorScheme),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRichTextContent(ThemeData theme, ColorScheme colorScheme) {
    try {
      if (post.richText != null && post.richText!.isNotEmpty) {
        final delta = Delta.fromJson(jsonDecode(post.richText!) as List);
        final controller = QuillController(
          document: Document.fromDelta(delta),
          selection: const TextSelection.collapsed(offset: 0),
        );

        return QuillEditor(
          controller: controller,
          focusNode: FocusNode(),
          scrollController: ScrollController(),
          config: QuillEditorConfig(
            padding: EdgeInsets.zero,
            enableInteractiveSelection: true,
            expands: false,
            autoFocus: false,
            showCursor: false,
            scrollable: false,
            customStyles: DefaultStyles(
              paragraph: DefaultTextBlockStyle(
                TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface,
                  height: 1.8,
                ),
                const HorizontalSpacing(0, 0),
                const VerticalSpacing(6, 0),
                const VerticalSpacing(0, 0),
                null,
              ),
              h1: DefaultTextBlockStyle(
                TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  height: 1.4,
                ),
                const HorizontalSpacing(0, 0),
                const VerticalSpacing(12, 8),
                const VerticalSpacing(0, 0),
                null,
              ),
              h2: DefaultTextBlockStyle(
                TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  height: 1.4,
                ),
                const HorizontalSpacing(0, 0),
                const VerticalSpacing(10, 6),
                const VerticalSpacing(0, 0),
                null,
              ),
              h3: DefaultTextBlockStyle(
                TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  height: 1.4,
                ),
                const HorizontalSpacing(0, 0),
                const VerticalSpacing(8, 4),
                const VerticalSpacing(0, 0),
                null,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error rendering rich text: $e');
    }

    // Fallback to plain text if rich text fails
    return SelectableText(
      post.plainText,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        height: 1.8,
        fontSize: 16,
      ),
    );
  }

  Widget _buildTagsSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tag,
              size: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              'Tags',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        // const SizedBox(height: 12),
        // Wrap(
        //   spacing: 8,
        //   runSpacing: 8,
        //   children: post.tags!.map((tag) {
        //     return Container(
        //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        //       decoration: BoxDecoration(
        //         color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        //         borderRadius: BorderRadius.circular(16),
        //         border: Border.all(
        //           color: colorScheme.primary.withValues(alpha: 0.3),
        //           width: 1,
        //         ),
        //       ),
        //       child: Text(
        //         tag,
        //         style: theme.textTheme.bodySmall?.copyWith(
        //           color: colorScheme.onPrimaryContainer,
        //           fontWeight: FontWeight.w500,
        //         ),
        //       ),
        //     );
        //   }).toList(),
        // ),
      ],
    );
  }

  Widget _buildEngagementStats(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
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
            color: colorScheme.onSurface.withValues(alpha: 0.6),
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
            color: colorScheme.outline.withValues(alpha: 0.2),
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
      case 'microfiction':
        return const Color(0xFFF59E0B);
      case 'quotes & aphorisms':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6366F1);
    }
  }
}
