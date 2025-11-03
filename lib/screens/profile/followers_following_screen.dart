import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/providers/auth_provider.dart';
import 'package:poem_application/providers/follow_provider.dart';
import 'package:poem_application/screens/profile/user_profile.dart'
    hide isFollowingProvider;

enum ListType { followers, following }

class FollowersFollowingScreen extends ConsumerStatefulWidget {
  final String userId;
  final ListType listType;
  final String userName;

  const FollowersFollowingScreen({
    super.key,
    required this.userId,
    required this.listType,
    required this.userName,
  });

  @override
  ConsumerState<FollowersFollowingScreen> createState() =>
      _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState
    extends ConsumerState<FollowersFollowingScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          widget.listType == ListType.followers
              ? '${widget.userName}\'s  Followers'
              : '${widget.userName}  Following',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection(
              widget.listType == ListType.followers ? 'followers' : 'following',
            )
            .orderBy('followedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading users',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.listType == ListType.followers
                        ? Icons.people_outline
                        : Icons.person_add_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.listType == ListType.followers
                        ? 'No followers yet'
                        : 'Not following anyone yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final userIds = snapshot.data!.docs.map((doc) => doc.id).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: userIds.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return UserListItem(
                userId: userIds[index],
                listType: widget.listType,
              );
            },
          );
        },
      ),
    );
  }
}

// Reusable User List Item Widget
class UserListItem extends ConsumerWidget {
  final String userId;
  final ListType listType;

  const UserListItem({super.key, required this.userId, required this.listType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(firebaseAuthProvider).currentUser;
    final isOwnProfile = currentUser?.uid == userId;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            leading: CircleAvatar(backgroundColor: Colors.grey),
            title: SizedBox(
              height: 14,
              width: 100,
              child: ColoredBox(color: Colors.grey),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox.shrink();

        final firstName = userData['firstname'] ?? userData['name'];
        final lastName = userData['lastname'] ?? '';
        final userName = userData['username'] ?? '';
        final photoUrl = userData['photoURl'] ?? '';

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfile(userId: userId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.2),
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.isEmpty
                      ? Text(
                          firstName.isNotEmpty
                              ? firstName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Name and username
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@$userName',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Follow button (only show if not own profile)
                if (!isOwnProfile && currentUser != null)
                  _buildFollowButton(context, ref, userId, currentUser.uid),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowButton(
    BuildContext context,
    WidgetRef ref,
    String targetUserId,
    String currentUserId,
  ) {
    final isFollowingAsync = ref.watch(
      isFollowingProvider(
        FollowParams(currentUserId: currentUserId, targetUserId: targetUserId),
      ),
    );

    return isFollowingAsync.when(
      data: (isFollowing) => SizedBox(
        height: 32,
        child: OutlinedButton(
          onPressed: () => _handleFollow(context, ref, targetUserId),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            backgroundColor: isFollowing
                ? Colors.grey[100]
                : Theme.of(context).primaryColor,
            foregroundColor: isFollowing ? Colors.grey[700] : Colors.white,
            side: BorderSide(
              color: isFollowing
                  ? Colors.grey[300]!
                  : Theme.of(context).primaryColor,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      loading: () => SizedBox(
        height: 32,
        width: 80,
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => SizedBox(
        height: 32,
        child: OutlinedButton(
          onPressed: () => _handleFollow(context, ref, targetUserId),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('Follow'),
        ),
      ),
    );
  }

  Future<void> _handleFollow(
    BuildContext context,
    WidgetRef ref,
    String targetUserId,
  ) async {
    final currentUser = ref.read(firebaseAuthProvider).currentUser;
    if (currentUser == null) return;

    final service = ref.read(followServiceProvider);

    try {
      await service.toggleFollow(currentUser.uid, targetUserId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
