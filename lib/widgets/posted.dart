import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poem_application/models/post_model.dart';
import 'package:poem_application/providers/postRepositoryProvider.dart';
import 'package:poem_application/widgets/createApost.dart';
import 'package:poem_application/widgets/fullPostBottomSheet.dart';
import 'package:poem_application/widgets/commentsBottomSheet.dart';

class Posted extends ConsumerWidget {
  final String uid, name;
  const Posted(this.uid, this.name, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPost = ref.watch(getPostByUidProvider(uid));

    return Scaffold(
      body: userPost.when(
        data: (data) {
          if (data.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 80),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final PostModel post = data[index];
              return _buildPostCard(context, post);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "Something went wrong",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewPost(context),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 3,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _createNewPost(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "What would you like to create?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPostTypeOption(
                  context,
                  'Poetry',
                  Icons.auto_stories,
                  Colors.indigo,
                ),
                _buildPostTypeOption(
                  context,
                  'Lyrics',
                  Icons.music_note,
                  Colors.purple,
                ),
                _buildPostTypeOption(
                  context,
                  'Stories',
                  Icons.book,
                  Colors.teal,
                ),
                _buildPostTypeOption(
                  context,
                  'Quotes & Aphorisms',
                  Icons.format_quote,
                  Colors.amber.shade700,
                ),
                _buildPostTypeOption(
                  context,
                  'Microfiction',
                  Icons.short_text,
                  Colors.deepOrange,
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 24,
          ),
        );
      },
    );
  }

  Widget _buildPostTypeOption(
    BuildContext context,
    String type,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          _navigateToCreatePost(context, type);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                type,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCreatePost(BuildContext context, String type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Createapost(userID: uid, type: type, name: name),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.post_add, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No posts yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your published posts will appear here",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createNewPost(context),
            icon: const Icon(Icons.add),
            label: const Text("Create First Post"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, PostModel post) {
    final theme = Theme.of(context);
    final formattedDate = _formatDate(post.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        onTap: () => _viewFullPost(context, post),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editPost(context, post);
                        } else if (value == 'delete') {
                          _deletePost(context, post.docId);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    post.workType ?? 'Poetry',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Divider(height: 24),
                Text(
                  post.plainText ?? post.richText,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        _buildStatButton(
                          icon: Icons.remove_red_eye_outlined,
                          count: post.viewCount ?? 0,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        _buildStatButton(
                          icon: Icons.favorite_border,
                          count: post.likeCount ?? 0,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(width: 12),
                        _buildStatButton(
                          icon: Icons.chat_bubble_outline,
                          count: post.commentCount ?? 0,
                          color: Colors.blue.shade400,
                          onTap: () => _viewComments(context, post),
                        ),
                      ],
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

  Widget _buildStatButton({
    required IconData icon,
    required int count,
    required Color color,
    VoidCallback? onTap,
  }) {
    final widget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          _formatCount(count),
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: widget,
        ),
      );
    }

    return widget;
  }

  void _viewFullPost(BuildContext context, PostModel post) {
    FullPostBottomSheet.show(
      context,
      post: post,
      onComment: () => _viewComments(context, post),
    );
  }

  void _viewComments(BuildContext context, PostModel post) {
    CommentsBottomSheet.show(context, post: post);
  }

  void _editPost(BuildContext context, PostModel post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Createapost(
          userID: uid,
          name: name,
          postId: post.docId,
          postData: {
            'title': post.title,
            'description': post.description,
            'plainText': post.plainText,
            'richText': post.richText,
            'workType': post.workType,
            'createdBy': post.createdBy,
            'authorName': post.authorName,
            'createdAt': post.createdAt,
            'likeCount': post.likeCount,
            'commentCount': post.commentCount,
            'shareCount': post.shareCount,
            'viewCount': post.viewCount,
            // 'wordCount': post.wordCount,
            // 'characterCount': post.characterCount,
          },
        ),
      ),
    );
  }

  Future<void> _deletePost(BuildContext context, String? postId) async {
    if (postId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting post: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Unknown date";

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return "Today, ${DateFormat('h:mm a').format(date)}";
    } else if (difference.inDays < 2) {
      return "Yesterday, ${DateFormat('h:mm a').format(date)}";
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  String _formatCount(int? count) {
    if (count == null) return "0";
    if (count < 1000) return count.toString();
    if (count < 10000) return "${(count / 1000).toStringAsFixed(1)}K";
    return "${(count / 1000).round()}K";
  }
}
