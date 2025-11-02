import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/providers/auth_provider.dart';
import 'package:poem_application/providers/follow_provider.dart';
import 'package:poem_application/screens/profile/user_profile.dart'
    hide isFollowingProvider;

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final searchQuery = query.trim().toLowerCase();

      // Search by username, firstname, or lastname
      final usernameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('userName', isGreaterThanOrEqualTo: searchQuery)
          .where('userName', isLessThanOrEqualTo: '$searchQuery\uf8ff')
          .limit(20)
          .get();

      final firstnameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('firstname', isGreaterThanOrEqualTo: searchQuery)
          .where('firstname', isLessThanOrEqualTo: '$searchQuery\uf8ff')
          .limit(20)
          .get();

      final lastnameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('lastname', isGreaterThanOrEqualTo: searchQuery)
          .where('lastname', isLessThanOrEqualTo: '$searchQuery\uf8ff')
          .limit(20)
          .get();

      // Combine results and remove duplicates
      final Map<String, DocumentSnapshot> uniqueUsers = {};

      for (var doc in usernameQuery.docs) {
        uniqueUsers[doc.id] = doc;
      }
      for (var doc in firstnameQuery.docs) {
        uniqueUsers[doc.id] = doc;
      }
      for (var doc in lastnameQuery.docs) {
        uniqueUsers[doc.id] = doc;
      }

      setState(() {
        _searchResults = uniqueUsers.values.toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Search Artists',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _performSearch(value);
                  }
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name or username...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _hasSearched = false;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Search Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _hasSearched && _searchResults.isEmpty
                ? _buildEmptyState(theme)
                : _searchResults.isEmpty
                ? _buildInitialState(theme)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    itemBuilder: (context, index) {
                      return _UserSearchResultItem(
                        userDoc: _searchResults[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for artists',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search by name or username',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserSearchResultItem extends ConsumerWidget {
  final DocumentSnapshot userDoc;

  const _UserSearchResultItem({required this.userDoc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = userDoc.data() as Map<String, dynamic>?;
    if (userData == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = ref.watch(firebaseAuthProvider).currentUser;
    final userId = userDoc.id;
    final isOwnProfile = currentUser?.uid == userId;

    final firstName = userData['firstname'] ?? '';
    final lastName = userData['lastname'] ?? '';
    final userName = userData['userName'] ?? '';
    final photoUrl = userData['photoURl'] ?? '';
    final followersCount = userData['followersCount'] ?? 0;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UserProfile(userId: userId)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl.isEmpty
                  ? Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 20,
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$firstName $lastName',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@$userName',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$followersCount ${followersCount == 1 ? 'follower' : 'followers'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Follow Button
            if (!isOwnProfile && currentUser != null)
              _buildFollowButton(
                context,
                ref,
                userId,
                currentUser.uid,
                theme,
                colorScheme,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(
    BuildContext context,
    WidgetRef ref,
    String targetUserId,
    String currentUserId,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Watch the follow status with proper parameters
    final isFollowingAsync = ref.watch(
      isFollowingProvider(
        FollowParams(currentUserId: currentUserId, targetUserId: targetUserId),
      ),
    );

    return isFollowingAsync.when(
      data: (isFollowing) => SizedBox(
        height: 36,
        child: FilledButton(
          onPressed: () =>
              _handleFollow(context, ref, targetUserId, currentUserId),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            backgroundColor: isFollowing
                ? colorScheme.surfaceContainerHighest
                : colorScheme.primary,
            foregroundColor: isFollowing
                ? colorScheme.onSurface
                : colorScheme.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: isFollowing
                  ? BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.5),
                    )
                  : BorderSide.none,
            ),
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      loading: () => SizedBox(
        height: 36,
        width: 90,
        child: FilledButton(
          onPressed: null,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
      error: (_, __) => SizedBox(
        height: 36,
        child: FilledButton(
          onPressed: () =>
              _handleFollow(context, ref, targetUserId, currentUserId),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
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
    String currentUserId,
  ) async {
    try {
      HapticFeedback.lightImpact();

      final followService = ref.read(followServiceProvider);
      await followService.toggleFollow(currentUserId, targetUserId);

      // Invalidate the follow status to refresh
      ref.invalidate(
        isFollowingProvider(
          FollowParams(
            currentUserId: currentUserId,
            targetUserId: targetUserId,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
