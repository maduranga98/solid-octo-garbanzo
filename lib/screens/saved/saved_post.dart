import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/providers/auth_provider.dart';
import 'package:poem_application/providers/postRepositoryProvider.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Removed from saved posts'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleLike(String postId) async {
    try {
      final currentUser = ref.read(firebaseAuthProvider).currentUser;
      if (currentUser == null) return;

      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(postId);
      final likeRef = postRef.collection('likes').doc(currentUser.uid);

      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        await likeRef.delete();
        await postRef.update({'likeCount': FieldValue.increment(-1)});
      } else {
        await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
        await postRef.update({'likeCount': FieldValue.increment(1)});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPostDetails(SavedPost savedPost) {
    FullPostBottomSheet.show(
      context,
      post: savedPost.postData,
      onLike: () => _toggleLike(savedPost.postData.docId),
      onComment: () => _showComments(savedPost),
      onShare: () {
        // Implement share functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Share functionality coming soon'),
            behavior: SnackBarBehavior.floating,
          ),
        );
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Saved Posts',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: savedPostsAsync.when(
        data: (savedPosts) {
          if (savedPosts.isEmpty) {
            return _buildEmptyState();
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
                return _buildPostCard(savedPost, currentuser.uid);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
          ),
        ),
        error: (error, stack) => _buildErrorState(error, currentuser.uid),
      ),
    );
  }

  Widget _buildPostCard(SavedPost savedPost, String userId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPostDetails(savedPost),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        savedPost.postData.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildBookmarkButton(savedPost, userId),
                  ],
                ),
                if (savedPost.postData.plainText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    savedPost.postData.plainText,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            savedPost.postData.authorName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.bookmark, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      timeago.format(savedPost.savedData.bookmarkedAt.toDate()),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const Spacer(),
                    _buildQuickActions(savedPost),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(SavedPost savedPost) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _showComments(savedPost),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${savedPost.postData.commentCount ?? 0}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookmarkButton(SavedPost savedPost, String userId) {
    return IconButton(
      onPressed: () => _removeSavedPost(userId, savedPost.savedData.postId),
      icon: const Icon(Icons.bookmark, color: Colors.black87),
      iconSize: 22,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: 'Remove from saved',
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_border,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No saved posts yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Posts you bookmark will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, String userId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(savedPostByUIDProvider(userId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
