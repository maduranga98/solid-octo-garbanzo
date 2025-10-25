// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/models/comment_model.dart';
import 'package:poem_application/models/post_model.dart';
import 'package:poem_application/providers/auth_provider.dart';
import 'package:poem_application/providers/commentsRepositoryProvider.dart';
import 'package:poem_application/providers/user_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final PostModel post;

  const CommentsBottomSheet({super.key, required this.post});

  static void show(BuildContext context, {required PostModel post}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(post: post),
    );
  }

  @override
  ConsumerState<CommentsBottomSheet> createState() =>
      _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _isSubmitting = false;
  String? _replyingToCommentId;
  String? _replyingToUsername;
  String? _replyingToUserId; // Added to track original comment user ID

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final commentsAsync = ref.watch(commentsProvider(widget.post.docId));
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      duration: const Duration(milliseconds: 100),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                _buildHeader(theme, colorScheme),
                Divider(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  height: 1,
                ),
                Expanded(
                  child: commentsAsync.when(
                    data: (comments) => _buildCommentsList(
                      comments,
                      scrollController,
                      theme,
                      colorScheme,
                    ),
                    loading: () => _buildLoadingState(theme, colorScheme),
                    error: (error, _) =>
                        _buildErrorState(error, theme, colorScheme),
                  ),
                ),
                _buildCommentInput(theme, colorScheme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline, color: colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Comments',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
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

  Widget _buildCommentsList(
    List<CommentModel> comments,
    ScrollController scrollController,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (comments.isEmpty) {
      return _buildEmptyState(theme, colorScheme);
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: comments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final comment = comments[index];
        return _buildCommentItem(comment, theme, colorScheme);
      },
    );
  }

  Widget _buildCommentItem(
    CommentModel comment,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final userAsync = ref.watch(getUserDataProvider(comment.authorId));

    // Fixed: Use comment.docId for likes and replies, not comment.postId
    final likeCountAsync = ref.watch(commentLikeCountProvider(comment.docId));
    final isLikedAsync = ref.watch(isCommentLikedProvider(comment.docId));

    final repliesAsync = ref.watch(
      repliesProvider(
        RepliesParams(postId: widget.post.docId, commentId: comment.docId),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            userAsync.when(
              data: (user) {
                if (user == null) {
                  return CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      color: colorScheme.onPrimaryContainer,
                      size: 16,
                    ),
                  );
                }

                return CircleAvatar(
                  radius: 16,
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
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                );
              },
              loading: () => CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
              error: (_, __) => CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  color: colorScheme.onPrimaryContainer,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment.authorName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        timeago.format(comment.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _handleLikeComment(comment.docId),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              isLikedAsync.when(
                                data: (isLiked) => Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 16,
                                  color: isLiked
                                      ? Colors.red
                                      : colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                ),
                                loading: () => Icon(
                                  Icons.favorite_border,
                                  size: 16,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                error: (_, __) => Icon(
                                  Icons.favorite_border,
                                  size: 16,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              likeCountAsync.when(
                                data: (count) => Text(
                                  count > 0 ? count.toString() : '',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _startReply(
                          comment.docId,
                          comment.authorName,
                          comment.authorId, // Pass the author ID
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.reply,
                                size: 16,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reply',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Replies section
                  repliesAsync.when(
                    data: (replies) {
                      if (replies.isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(left: 16, top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: replies.map((reply) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildReplyItem(reply, theme, colorScheme),
                            );
                          }).toList(),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentInput(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingToUsername != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to $_replyingToUsername',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    onPressed: _cancelReply,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: _replyingToUsername != null
                        ? 'Write a reply...'
                        : 'Write a comment...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _isSubmitting ? null : _handleSubmitComment,
                icon: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Icon(Icons.send),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
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
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No comments yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your thoughts',
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

  Widget _buildLoadingState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
      ),
    );
  }

  Widget _buildErrorState(
    Object error,
    ThemeData theme,
    ColorScheme colorScheme,
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
              'Failed to load comments',
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
          ],
        ),
      ),
    );
  }

  void _startReply(String commentId, String username, String userId) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUsername = username;
      _replyingToUserId = userId; // Store the user ID
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUsername = null;
      _replyingToUserId = null;
    });
  }

  Future<void> _handleLikeComment(String commentId) async {
    try {
      await ref
          .read(commentsRepositoryProvider)
          .toggleCommentLike(widget.post.docId, commentId);
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like comment: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
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

  Future<void> _handleSubmitComment() async {
    final currentUser = ref.read(firebaseAuthProvider).currentUser;
    final text = _commentController.text.trim();

    if (currentUser == null || text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final userDataAsync = await ref.read(
        getUserDataProvider(currentUser.uid).future,
      );

      if (userDataAsync == null) throw Exception('User data not found');

      // Create comment with empty docId - it will be set when saved to Firestore
      final comment = CommentModel(
        docId: '',
        postId: widget.post.docId,
        authorId: currentUser.uid,
        authorName: userDataAsync.userName,
        text: text,
        createdAt: DateTime.now(),
      );

      if (_replyingToCommentId != null && _replyingToUserId != null) {
        // Add reply with all required parameters
        await ref
            .read(commentsRepositoryProvider)
            .addReply(
              widget.post.docId, // postId
              _replyingToCommentId!, // parentCommentId
              comment, // replyData
              widget.post.title.isNotEmpty
                  ? widget.post.title
                  : widget.post.plainText.substring(
                      0,
                      widget.post.plainText.length > 50
                          ? 50
                          : widget.post.plainText.length,
                    ), // postTitle
              _replyingToUserId!, // originalCommentUserId
            );
      } else {
        // Add comment with all required parameters
        await ref
            .read(commentsRepositoryProvider)
            .addComment(
              widget.post.docId, // postId
              comment, // data
              widget.post, // post (the full PostModel)
            );
      }

      _commentController.clear();
      _commentFocusNode.unfocus();
      _cancelReply();
      HapticFeedback.lightImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _replyingToCommentId != null
                  ? 'Reply posted!'
                  : 'Comment posted!',
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildReplyItem(
    CommentModel reply,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final userAsync = ref.watch(getUserDataProvider(reply.authorId));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        userAsync.when(
          data: (user) {
            if (user == null) {
              return CircleAvatar(
                radius: 12,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  color: colorScheme.onPrimaryContainer,
                  size: 12,
                ),
              );
            }
            return CircleAvatar(
              radius: 12,
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
                        fontSize: 10,
                      ),
                    )
                  : null,
            );
          },
          loading: () =>
              CircleAvatar(radius: 12, backgroundColor: colorScheme.surface),
          error: (_, __) => CircleAvatar(
            radius: 12,
            backgroundColor: colorScheme.errorContainer,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reply.authorName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      timeago.format(reply.createdAt, locale: 'en_short'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reply.text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
