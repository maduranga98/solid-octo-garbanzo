import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poem_application/providers/auth_provider.dart';
import 'package:poem_application/providers/user_provider.dart';
import 'package:poem_application/screens/profile/followers_following_screen.dart';
import 'package:poem_application/widgets/draft.dart';
import 'package:poem_application/widgets/ideas.dart';
import 'package:poem_application/widgets/posted.dart';

final isFollowingProvider = StreamProvider.family<bool, String>((ref, userId) {
  final currentUser = ref.watch(firebaseAuthProvider).currentUser;
  if (currentUser == null) return Stream.value(false);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .collection('following')
      .doc(userId)
      .snapshots()
      .map((doc) => doc.exists);
});

class UserProfile extends ConsumerWidget {
  final String? userId; // If null, show current user's profile

  const UserProfile({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(firebaseAuthProvider).currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                "Not logged in",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please log in to view your profile",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    // Determine which user's profile to show
    final profileUserId = userId ?? currentUser.uid;
    final isOwnProfile = profileUserId == currentUser.uid;

    final userAsync = ref.watch(getUserDataProvider(profileUserId));

    return DefaultTabController(
      length: isOwnProfile ? 3 : 1, // Only show Posted tab for other users
      child: Scaffold(
        backgroundColor: Colors.white,
        body: userAsync.when(
          data: (user) {
            if (user == null) {
              return const Center(child: Text("User Not Found"));
            }
            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  centerTitle: true,
                  pinned: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  expandedHeight: isOwnProfile ? 320 : 380,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildProfileHeader(
                      user,
                      context,
                      ref,
                      isOwnProfile,
                      profileUserId,
                    ),
                  ),
                  bottom: isOwnProfile
                      ? TabBar(
                          indicatorColor: Theme.of(context).primaryColor,
                          labelColor: Theme.of(context).primaryColor,
                          unselectedLabelColor: Colors.grey.shade400,
                          indicator: UnderlineTabIndicator(
                            borderSide: BorderSide(
                              width: 3,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          tabs: const [
                            Tab(text: "Posted"),
                            Tab(text: "Draft"),
                            Tab(text: "Ideas"),
                          ],
                        )
                      : TabBar(
                          indicatorColor: Theme.of(context).primaryColor,
                          labelColor: Theme.of(context).primaryColor,
                          unselectedLabelColor: Colors.grey.shade400,
                          indicator: UnderlineTabIndicator(
                            borderSide: BorderSide(
                              width: 3,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          tabs: const [Tab(text: "Posted")],
                        ),
                ),
              ],
              body: TabBarView(
                children: isOwnProfile
                    ? [
                        Posted(currentUser.uid, user.userName),
                        Draft(userName: user.userName),
                        const Ideas(),
                      ]
                    : [Posted(profileUserId, user.userName)],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
            child: Icon(Icons.error, color: Colors.redAccent, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    user,
    BuildContext context,
    WidgetRef ref,
    bool isOwnProfile,
    String profileUserId,
  ) {
    final primaryColor = Theme.of(context).primaryColor;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 42,
                backgroundColor: primaryColor.withOpacity(0.2),
                backgroundImage:
                    user.photoURl != null && user.photoURl!.isNotEmpty
                    ? NetworkImage(user.photoURl!)
                    : null,
                child: user.photoURl == null || user.photoURl!.isEmpty
                    ? Text(
                        // FIX: Check if firstname is not empty before accessing index
                        user.firstname != null && user.firstname.isNotEmpty
                            ? user.firstname[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "${user.firstname ?? ''} ${user.lastname ?? ''}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            Text(
              "@${user.userName ?? ''}",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStat(
                  "Posts",
                  user.postCount ?? 0,
                  context,
                  profileUserId,
                  user.userName ?? '',
                ),
                _buildStatDivider(),
                _buildStat(
                  "Followers",
                  user.followersCount ?? 0,
                  context,
                  profileUserId,
                  user.userName ?? '',
                ),
                _buildStatDivider(),
                _buildStat(
                  "Following",
                  user.followingCount ?? 0,
                  context,
                  profileUserId,
                  user.userName ?? '',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildInfo(Icons.email_outlined, user.email ?? ''),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfo(
                    Icons.location_on_outlined,
                    user.country ?? '',
                  ),
                ),
              ],
            ),
            // Action buttons for other users' profiles
            if (!isOwnProfile) ...[
              const SizedBox(height: 20),
              _buildActionButtons(context, ref, profileUserId),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    final isFollowingAsync = ref.watch(isFollowingProvider(userId));

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: isFollowingAsync.when(
            data: (isFollowing) => ElevatedButton.icon(
              onPressed: () => _toggleFollow(context, ref, userId, isFollowing),
              icon: Icon(
                isFollowing ? Icons.person_remove : Icons.person_add,
                size: 18,
              ),
              label: Text(isFollowing ? 'Following' : 'Follow'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing
                    ? Colors.grey.shade200
                    : Theme.of(context).primaryColor,
                foregroundColor: isFollowing
                    ? Colors.grey.shade700
                    : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            loading: () => ElevatedButton.icon(
              onPressed: null,
              icon: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              label: const Text('Loading'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            error: (_, __) => ElevatedButton.icon(
              onPressed: () => _toggleFollow(context, ref, userId, false),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Follow'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _sendMessage(context, userId),
            icon: const Icon(Icons.message, size: 18),
            label: const Text('Message'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFollow(
    BuildContext context,
    WidgetRef ref,
    String targetUserId,
    bool isCurrentlyFollowing,
  ) async {
    try {
      final currentUser = ref.read(firebaseAuthProvider).currentUser;
      if (currentUser == null) return;

      final batch = FirebaseFirestore.instance.batch();

      if (isCurrentlyFollowing) {
        // Unfollow
        batch.delete(
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('following')
              .doc(targetUserId),
        );
        batch.delete(
          FirebaseFirestore.instance
              .collection('users')
              .doc(targetUserId)
              .collection('followers')
              .doc(currentUser.uid),
        );
        batch.update(
          FirebaseFirestore.instance.collection('users').doc(currentUser.uid),
          {'followingCount': FieldValue.increment(-1)},
        );
        batch.update(
          FirebaseFirestore.instance.collection('users').doc(targetUserId),
          {'followersCount': FieldValue.increment(-1)},
        );
      } else {
        // Follow
        batch.set(
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('following')
              .doc(targetUserId),
          {'followedAt': FieldValue.serverTimestamp()},
        );
        batch.set(
          FirebaseFirestore.instance
              .collection('users')
              .doc(targetUserId)
              .collection('followers')
              .doc(currentUser.uid),
          {'followedAt': FieldValue.serverTimestamp()},
        );
        batch.update(
          FirebaseFirestore.instance.collection('users').doc(currentUser.uid),
          {'followingCount': FieldValue.increment(1)},
        );
        batch.update(
          FirebaseFirestore.instance.collection('users').doc(targetUserId),
          {'followersCount': FieldValue.increment(1)},
        );
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyFollowing ? 'Unfollowed' : 'Following'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

  void _sendMessage(BuildContext context, String userId) {
    // TODO: Implement messaging functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Messaging feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildStat(
    String label,
    int value,
    BuildContext context,
    String userId,
    String userName,
  ) {
    return Expanded(
      child: InkWell(
        onTap: label == "Posts"
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FollowersFollowingScreen(
                      userId: userId,
                      listType: label == "Followers"
                          ? ListType.followers
                          : ListType.following,
                      userName: userName,
                    ),
                  ),
                );
              },
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.withOpacity(0.2));
  }

  Widget _buildInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
