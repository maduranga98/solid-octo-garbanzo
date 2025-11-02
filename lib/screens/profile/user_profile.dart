import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poem_application/providers/auth_provider.dart';
import 'package:poem_application/providers/user_provider.dart';
import 'package:poem_application/screens/messages/message.dart';
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
  final String? userId;

  const UserProfile({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(firebaseAuthProvider).currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 64,
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                "Not logged in",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please log in to view your profile",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final profileUserId = userId ?? currentUser.uid;
    final isOwnProfile = profileUserId == currentUser.uid;

    final userAsync = ref.watch(getUserDataProvider(profileUserId));

    return DefaultTabController(
      length: isOwnProfile ? 3 : 1,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: userAsync.when(
          data: (user) {
            if (user == null) {
              return Center(
                child: Text(
                  "User Not Found",
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              );
            }
            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  centerTitle: true,
                  pinned: true,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  foregroundColor: theme.textTheme.bodyLarge?.color,
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
                          indicatorColor: theme.primaryColor,
                          labelColor: isDark
                              ? Colors.white
                              : theme.primaryColor,
                          unselectedLabelColor: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(text: "Posted"),
                            Tab(text: "Draft"),
                            Tab(text: "Ideas"),
                          ],
                        )
                      : TabBar(
                          indicatorColor: theme.primaryColor,
                          labelColor: isDark
                              ? Colors.white
                              : theme.primaryColor,
                          unselectedLabelColor: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          indicatorWeight: 3,
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
          loading: () => Center(
            child: CircularProgressIndicator(color: theme.primaryColor),
          ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

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
                  color: primaryColor.withOpacity(isDark ? 0.7 : 0.5),
                  width: 2.5,
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: CircleAvatar(
                radius: 42,
                backgroundColor: isDark
                    ? primaryColor.withOpacity(0.25)
                    : primaryColor.withOpacity(0.15),
                backgroundImage:
                    user.photoURl != null && user.photoURl!.isNotEmpty
                    ? NetworkImage(user.photoURl!)
                    : null,
                child: user.photoURl == null || user.photoURl!.isEmpty
                    ? Text(
                        user.firstname != null && user.firstname.isNotEmpty
                            ? user.firstname[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? primaryColor.withOpacity(0.9)
                              : primaryColor,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "${user.firstname ?? ''} ${user.lastname ?? ''}",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              "@${user.userName ?? ''}",
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
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
                _buildStatDivider(isDark),
                _buildStat(
                  "Followers",
                  user.followersCount ?? 0,
                  context,
                  profileUserId,
                  user.userName ?? '',
                ),
                _buildStatDivider(isDark),
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
                  child: _buildInfo(
                    Icons.email_outlined,
                    user.email ?? '',
                    context,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfo(
                    Icons.location_on_outlined,
                    user.country ?? '',
                    context,
                  ),
                ),
              ],
            ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
                    ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                    : theme.primaryColor,
                foregroundColor: isFollowing
                    ? (isDark ? Colors.grey.shade300 : Colors.grey.shade700)
                    : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
            loading: () => ElevatedButton.icon(
              onPressed: null,
              icon: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.primaryColor,
                ),
              ),
              label: const Text('Loading'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            error: (_, __) => ElevatedButton.icon(
              onPressed: () => _toggleFollow(context, ref, userId, false),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Follow'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _sendMessage(context, ref, userId),
            icon: const Icon(Icons.message, size: 18),
            label: const Text('Message'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
              foregroundColor: theme.textTheme.bodyLarge?.color,
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
            backgroundColor: Theme.of(context).primaryColor,
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

  void _sendMessage(BuildContext context, WidgetRef ref, String userId) async {
    try {
      final currentUser = ref.read(firebaseAuthProvider).currentUser;
      if (currentUser == null) return;

      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final currentUserData = currentUserDoc.data();

      final otherUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final otherUserData = otherUserDoc.data();

      if (otherUserData == null) return;

      final chatId = await getOrCreateChat(
        currentUserId: currentUser.uid,
        otherUserId: userId,
        otherUserName:
            '${otherUserData['firstname'] ?? ''} ${otherUserData['lastname'] ?? ''}'
                .trim(),
        otherUserPhoto: otherUserData['photoURl'],
        currentUserName:
            '${currentUserData?['firstname'] ?? ''} ${currentUserData?['lastname'] ?? ''}'
                .trim(),
        currentUserPhoto: currentUserData?['photoURl'],
      );

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUserId: userId,
              otherUserName:
                  '${otherUserData['firstname'] ?? ''} ${otherUserData['lastname'] ?? ''}'
                      .trim(),
              otherUserPhoto: otherUserData['photoURl'],
            ),
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

  Widget _buildStat(
    String label,
    int value,
    BuildContext context,
    String userId,
    String userName,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : theme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      height: 30,
      width: 1,
      color: isDark ? Colors.grey.shade800 : Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildInfo(IconData icon, String text, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}
