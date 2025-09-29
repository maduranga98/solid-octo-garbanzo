import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
    Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Search Artists',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400]),
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
                fillColor: Colors.grey[100],
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
                ? _buildEmptyState()
                : _searchResults.isEmpty
                ? _buildInitialState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
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

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Search for artists',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search by name or username',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
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
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              backgroundImage: photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl.isEmpty
                  ? Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).primaryColor,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@$userName',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$followersCount ${followersCount == 1 ? 'follower' : 'followers'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            // Follow Button
            if (!isOwnProfile && currentUser != null)
              _buildFollowButton(context, ref, userId, currentUser.uid),
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
  ) {
    final isFollowingAsync = ref.watch(
      isFollowingProvider(
        FollowParams(currentUserId: currentUserId, targetUserId: targetUserId),
      ),
    );

    return isFollowingAsync.when(
      data: (isFollowing) => SizedBox(
        height: 36,
        child: ElevatedButton(
          onPressed: () => _handleFollow(context, ref, targetUserId),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            backgroundColor: isFollowing
                ? Colors.grey[200]
                : Theme.of(context).primaryColor,
            foregroundColor: isFollowing ? Colors.grey[700] : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => SizedBox(
        height: 36,
        child: ElevatedButton(
          onPressed: () => _handleFollow(context, ref, targetUserId),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
