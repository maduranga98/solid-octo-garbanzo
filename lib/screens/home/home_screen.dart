import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/models/post_model.dart';
import 'package:poem_application/providers/auth_provider.dart';
import 'package:poem_application/providers/follow_provider.dart';
import 'package:poem_application/providers/postRepositoryProvider.dart';
import 'package:poem_application/providers/post_interaction_provider.dart';
import 'package:poem_application/providers/user_provider.dart';
import 'package:poem_application/screens/auth/login.dart';
import 'package:poem_application/screens/following/following_feed.dart';
import 'package:poem_application/screens/messages/message.dart';
import 'package:poem_application/screens/notifications/notifications_screen.dart';
import 'package:poem_application/screens/profile/user_profile.dart'
    hide isFollowingProvider;
import 'package:poem_application/screens/saved/saved_post.dart';
import 'package:poem_application/screens/search/user_search_screen.dart';
import 'package:poem_application/widgets/commentsBottomSheet.dart';
import 'package:poem_application/widgets/fullPostBottomSheet.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarShadow = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    _scrollController.addListener(() {
      if (_scrollController.offset > 10 && !_showAppBarShadow) {
        setState(() => _showAppBarShadow = true);
      } else if (_scrollController.offset <= 10 && _showAppBarShadow) {
        setState(() => _showAppBarShadow = false);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = ref.watch(firebaseAuthProvider).currentUser;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colorScheme.onPrimary,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      currentUser?.email ?? "Guest User",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Followers Feed'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FollowingFeedScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Saved'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedPostScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_2_sharp),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserProfile()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Chat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessageSection(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_outlined),
              title: const Text('LogOut'),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                );
              },
            ),
          ],
        ),
      ),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              pinned: true,
              elevation: _showAppBarShadow ? 2 : 0,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_stories,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Poetic',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.search, color: colorScheme.onSurface),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserSearchScreen(),
                      ),
                    );
                  },
                  tooltip: 'Search',
                ),
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: colorScheme.onSurface,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationsScreen(),
                      ),
                    );
                  },
                  tooltip: 'Notifications',
                ),
                const SizedBox(width: 4),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Container(
                  color: colorScheme.surface,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: EdgeInsets.zero,
                    indicatorColor: colorScheme.primary,
                    indicatorWeight: 2,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurface.withValues(
                      alpha: 0.6,
                    ),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                    tabs: const [
                      Tab(text: 'For You'),
                      Tab(text: 'Poetry'),
                      Tab(text: 'Lyrics'),
                      Tab(text: 'Stories'),
                      Tab(text: 'Quotes & Aphorisms'),
                      Tab(text: 'Microfiction'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostFeed(),
            _buildPostFeed(workType: 'Poetry'),
            _buildPostFeed(workType: 'Lyrics'),
            _buildPostFeed(workType: 'Stories'),
            _buildPostFeed(workType: 'Quotes & Aphorisms'),
            _buildPostFeed(workType: 'Microfiction'),
          ],
        ),
      ),
    );

    // floatingActionButton: FloatingActionButton.extended(
    //   onPressed: () {
    //     // Navigate to create post
    //   },
    //   icon: const Icon(Icons.edit_outlined),
    //   label: const Text('Create'),
    //   elevation: 2,
    // ),
  }

  Widget _buildPostFeed({String? workType}) {
    final postsAsync = ref.watch(postsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(postsProvider);
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: postsAsync.when(
        data: (posts) {
          final filteredPosts = workType != null
              ? posts.where((post) => post.workType == workType).toList()
              : posts;

          print(filteredPosts);
          if (filteredPosts.isEmpty) {
            return _buildEmptyState(workType);
          }

          return ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: filteredPosts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final post = filteredPosts[index];
              return _buildPostCard(post);
            },
          );
        },
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userAsync = ref.watch(getUserDataProvider(post.createdBy));

    return GestureDetector(
      onTap: () => _showFullPost(post),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Author Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Navigate to user profile
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
                              timeago.format(
                                post.createdAt,
                                locale: 'en_short',
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
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
                  // Follow Button - Only show if not own post
                  _buildFollowButton(post, colorScheme, theme),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    onPressed: () => _showPostOptions(post),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (post.title.isNotEmpty) ...[
                    Text(
                      post.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    post.plainText,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Engagement Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (post.hasLikes)
                    Flexible(
                      child: Text(
                        '${post.likeCount} ${post.likeCount == 1 ? 'like' : 'likes'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (post.hasLikes && post.hasComments)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '•',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  if (post.hasComments)
                    Flexible(
                      child: Text(
                        '${post.commentCount} ${post.commentCount == 1 ? 'comment' : 'comments'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Spacer(),
                  if (post.hasViews)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.viewCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Divider(
              color: colorScheme.outline.withValues(alpha: 0.2),
              height: 1,
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final isLikedAsync = ref.watch(
                          isPostLikedProvider(post.docId),
                        );

                        return isLikedAsync.when(
                          data: (isLiked) => _buildActionButton(
                            icon: isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            label: 'Like',
                            onTap: () => _handleLike(post),
                            isActive: isLiked,
                            activeColor: Colors.red,
                          ),
                          loading: () => _buildActionButton(
                            icon: Icons.favorite_border,
                            label: 'Like',
                            onTap: () => _handleLike(post),
                          ),
                          error: (_, __) => _buildActionButton(
                            icon: Icons.favorite_border,
                            label: 'Like',
                            onTap: () => _handleLike(post),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: 'Comment',
                      onTap: () => _handleComment(post),
                    ),
                  ),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: () => _handleShare(post),
                    ),
                  ),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final isBookmarkedAsync = ref.watch(
                          isPostBookmarkedProvider(post.docId),
                        );

                        return isBookmarkedAsync.when(
                          data: (isBookmarked) => _buildActionButton(
                            icon: isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            label: 'Save',
                            onTap: () => _handleSave(post),
                            isActive: isBookmarked,
                            activeColor: Colors.amber,
                          ),
                          loading: () => _buildActionButton(
                            icon: Icons.bookmark_border,
                            label: 'Save',
                            onTap: () => _handleSave(post),
                          ),
                          error: (_, __) => _buildActionButton(
                            icon: Icons.bookmark_border,
                            label: 'Save',
                            onTap: () => _handleSave(post),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? activeColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? (activeColor ?? colorScheme.primary)
                    : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isActive
                      ? (activeColor ?? colorScheme.primary)
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowButton(
    PostModel post,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final currentUser = ref.watch(firebaseAuthProvider).currentUser;
    final isOwnPost = currentUser?.uid == post.createdBy;

    if (isOwnPost || currentUser == null) {
      return const SizedBox.shrink();
    }

    return Consumer(
      builder: (context, ref, child) {
        final isFollowingAsync = ref.watch(
          isFollowingProvider(
            FollowParams(
              currentUserId: currentUser.uid,
              targetUserId: post.createdBy,
            ),
          ),
        );

        return isFollowingAsync.when(
          data: (isFollowing) => TextButton(
            onPressed: () => _handleFollow(post.createdBy),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: isFollowing
                  ? colorScheme.surfaceVariant
                  : colorScheme.primary,
              foregroundColor: isFollowing
                  ? colorScheme.onSurface
                  : colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          loading: () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          error: (error, stack) {
            // Log the error for debugging
            print('Follow button error: $error');
            // Show a default "Follow" button on error
            return TextButton(
              onPressed: () => _handleFollow(post.createdBy),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Follow',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String? workType) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No posts yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              workType != null
                  ? 'Be the first to share your ${workType}!'
                  : 'Start following creators to see their posts',
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

  Widget _buildLoadingState() {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.surfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 12,
                          width: 80,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 16,
                width: 200,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(Object error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
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
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(postsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
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

  void _showPostOptions(PostModel post) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.bookmark_outline,
                  color: colorScheme.onSurface,
                ),
                title: const Text('Save post'),
                onTap: () {
                  Navigator.pop(context);
                  _handleSave(post);
                },
              ),
              ListTile(
                leading: Icon(Icons.link, color: colorScheme.onSurface),
                title: const Text('Copy link'),
                onTap: () {
                  Navigator.pop(context);
                  // Copy link logic
                },
              ),
              ListTile(
                leading: Icon(Icons.report_outlined, color: colorScheme.error),
                title: Text(
                  'Report post',
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Report logic
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _handleComment(PostModel post) {
    CommentsBottomSheet.show(context, post: post);
  }

  void _handleShare(PostModel post) async {
    final service = ref.read(postInteractionServiceProvider);

    HapticFeedback.mediumImpact();

    await service.sharePost(post, context);
  }

  void _handleLike(PostModel post) async {
    final service = ref.read(postInteractionServiceProvider);

    try {
      await service.toggleLike(post);

      if (mounted) {
        HapticFeedback.mediumImpact();
        // UI updates automatically via stream
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like post: $e'),
            backgroundColor: Colors.red,
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

  void _handleSave(PostModel post) async {
    final service = ref.read(postInteractionServiceProvider);

    try {
      await service.toggleBookmark(post);

      if (mounted) {
        HapticFeedback.mediumImpact();
        // UI updates automatically via stream
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save post: $e'),
            backgroundColor: Colors.red,
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

  void _showFullPost(PostModel post) {
    FullPostBottomSheet.show(
      context,
      post: post,
      onLike: () => _handleLike(post),
      onComment: () => _handleComment(post),
      onShare: () => _handleShare(post),
    );
  }

  Future<void> _handleFollow(String targetUserId) async {
    final currentUser = ref.read(firebaseAuthProvider).currentUser;
    if (currentUser == null) return;

    final service = ref.read(followServiceProvider);

    try {
      await service.toggleFollow(currentUser.uid, targetUserId);
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to follow user: $e'),
            backgroundColor: Colors.red,
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
}
