import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:country_picker/country_picker.dart';
import 'package:versewing/providers/auth_provider.dart';
import 'package:versewing/providers/follow_provider.dart';
import 'package:versewing/screens/profile/user_profile.dart'
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

  // Advanced search filters
  List<String> _selectedContentTypes = [];
  List<String> _selectedLanguages = [];
  String? _selectedCountry;
  bool _showFilters = false;

  // Available options
  final List<Map<String, dynamic>> _contentTypes = [
    {'title': 'Poetry', 'value': 'poetry', 'icon': Icons.auto_stories},
    {'title': 'Lyrics', 'value': 'lyrics', 'icon': Icons.music_note},
    {'title': 'Stories', 'value': 'stories', 'icon': Icons.menu_book},
    {'title': 'Quotes', 'value': 'quotes', 'icon': Icons.format_quote},
    {'title': 'Microfiction', 'value': 'microfiction', 'icon': Icons.bolt},
  ];

  final List<String> _languages = [
    'English', 'Spanish', 'French', 'German', 'Italian',
    'Portuguese', 'Chinese', 'Japanese', 'Korean', 'Arabic', 'Hindi'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty && _selectedContentTypes.isEmpty &&
        _selectedLanguages.isEmpty && _selectedCountry == null) {
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
      final searchQuery = query.trim();
      final searchQueryLower = searchQuery.toLowerCase();
      final Map<String, DocumentSnapshot> uniqueUsers = {};

      // If text query exists, search by username, firstname, or lastname
      if (searchQuery.isNotEmpty) {
        // Search username (stored in lowercase)
        try {
          final usernameQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('userName', isGreaterThanOrEqualTo: searchQueryLower)
              .where('userName', isLessThanOrEqualTo: '$searchQueryLower\uf8ff')
              .limit(20)
              .get();
          for (var doc in usernameQuery.docs) {
            if (doc.data()['userName'] != null) {
              uniqueUsers[doc.id] = doc;
            }
          }
        } catch (e) {
          // Handle case where userName field doesn't exist
          print('Error searching username: $e');
        }

        // Search firstname (case-insensitive by searching both cases)
        try {
          final firstnameQueryLower = await FirebaseFirestore.instance
              .collection('users')
              .where('firstname', isGreaterThanOrEqualTo: searchQueryLower)
              .where('firstname', isLessThanOrEqualTo: '$searchQueryLower\uf8ff')
              .limit(10)
              .get();
          for (var doc in firstnameQueryLower.docs) {
            if (doc.data()['firstname'] != null) {
              uniqueUsers[doc.id] = doc;
            }
          }
        } catch (e) {
          print('Error searching firstname (lower): $e');
        }

        try {
          final firstnameQueryOriginal = await FirebaseFirestore.instance
              .collection('users')
              .where('firstname', isGreaterThanOrEqualTo: searchQuery)
              .where('firstname', isLessThanOrEqualTo: '$searchQuery\uf8ff')
              .limit(10)
              .get();
          for (var doc in firstnameQueryOriginal.docs) {
            if (doc.data()['firstname'] != null) {
              uniqueUsers[doc.id] = doc;
            }
          }
        } catch (e) {
          print('Error searching firstname (original): $e');
        }

        // Search lastname (case-insensitive by searching both cases)
        try {
          final lastnameQueryLower = await FirebaseFirestore.instance
              .collection('users')
              .where('lastname', isGreaterThanOrEqualTo: searchQueryLower)
              .where('lastname', isLessThanOrEqualTo: '$searchQueryLower\uf8ff')
              .limit(10)
              .get();
          for (var doc in lastnameQueryLower.docs) {
            if (doc.data()['lastname'] != null) {
              uniqueUsers[doc.id] = doc;
            }
          }
        } catch (e) {
          print('Error searching lastname (lower): $e');
        }

        try {
          final lastnameQueryOriginal = await FirebaseFirestore.instance
              .collection('users')
              .where('lastname', isGreaterThanOrEqualTo: searchQuery)
              .where('lastname', isLessThanOrEqualTo: '$searchQuery\uf8ff')
              .limit(10)
              .get();
          for (var doc in lastnameQueryOriginal.docs) {
            if (doc.data()['lastname'] != null) {
              uniqueUsers[doc.id] = doc;
            }
          }
        } catch (e) {
          print('Error searching lastname (original): $e');
        }
      } else if (_selectedContentTypes.isNotEmpty || _selectedLanguages.isNotEmpty || _selectedCountry != null) {
        // Only filters applied without search text - fetch limited set of users
        final allUsers = await FirebaseFirestore.instance
            .collection('users')
            .limit(100)
            .get();
        for (var doc in allUsers.docs) {
          uniqueUsers[doc.id] = doc;
        }
      }

      // Apply client-side filters
      List<DocumentSnapshot> filteredResults = uniqueUsers.values.toList();

      // Filter by content type
      if (_selectedContentTypes.isNotEmpty) {
        filteredResults = filteredResults.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) return false;

          final userTypes = List<String>.from(data['type'] ?? []);
          return _selectedContentTypes.any((type) => userTypes.contains(type));
        }).toList();
      }

      // Filter by language
      if (_selectedLanguages.isNotEmpty) {
        filteredResults = filteredResults.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) return false;

          final readingLangs = List<String>.from(data['preferredReadingLanguages'] ?? []);
          final writingLang = data['preferredWritingLanguage'] ?? '';

          return _selectedLanguages.any((lang) =>
            readingLangs.contains(lang) || writingLang == lang
          );
        }).toList();
      }

      // Filter by country
      if (_selectedCountry != null) {
        filteredResults = filteredResults.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) return false;

          return data['country'] == _selectedCountry;
        }).toList();
      }

      setState(() {
        _searchResults = filteredResults;
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

  int get _activeFilterCount {
    int count = 0;
    if (_selectedContentTypes.isNotEmpty) count++;
    if (_selectedLanguages.isNotEmpty) count++;
    if (_selectedCountry != null) count++;
    return count;
  }

  void _clearFilters() {
    setState(() {
      _selectedContentTypes.clear();
      _selectedLanguages.clear();
      _selectedCountry = null;
    });
    _performSearch(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final statusBarHeight = mediaQuery.padding.top;

    // Calculate max filter height based on available space
    // Account for: StatusBar + AppBar + SearchBar + padding + minimum space for results
    final maxFilterHeight = keyboardHeight > 0
        ? (screenHeight - statusBarHeight - appBarHeight - keyboardHeight - 200).clamp(120.0, 250.0)
        : 300.0;

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
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
                    const SizedBox(width: 8),
                    // Filter button
                    Stack(
                      children: [
                        IconButton.filled(
                          onPressed: () {
                            setState(() => _showFilters = !_showFilters);
                          },
                          icon: Icon(
                            _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: _showFilters
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            foregroundColor: _showFilters
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (_activeFilterCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$_activeFilterCount',
                                style: TextStyle(
                                  color: theme.colorScheme.onError,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                // Filter Panel
                if (_showFilters) _buildFilterPanel(theme, maxFilterHeight),
              ],
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

  Widget _buildFilterPanel(ThemeData theme, double maxHeight) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_activeFilterCount > 0)
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Content Type Filter
            Text(
              'Content Type',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _contentTypes.map((type) {
                final isSelected = _selectedContentTypes.contains(type['value']);
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(type['icon'] as IconData, size: 16),
                      const SizedBox(width: 4),
                      Text(type['title'] as String),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedContentTypes.add(type['value'] as String);
                      } else {
                        _selectedContentTypes.remove(type['value']);
                      }
                    });
                    _performSearch(_searchController.text);
                  },
                  selectedColor: theme.colorScheme.primary.withOpacity(0.3),
                  checkmarkColor: theme.colorScheme.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Language Filter
            Text(
              'Language',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _languages.map((language) {
                final isSelected = _selectedLanguages.contains(language);
                return FilterChip(
                  label: Text(language),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedLanguages.add(language);
                      } else {
                        _selectedLanguages.remove(language);
                      }
                    });
                    _performSearch(_searchController.text);
                  },
                  selectedColor: theme.colorScheme.primary.withOpacity(0.3),
                  checkmarkColor: theme.colorScheme.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Country Filter
            Text(
              'Country',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                showCountryPicker(
                  context: context,
                  showPhoneCode: false,
                  onSelect: (Country country) {
                    setState(() {
                      _selectedCountry = country.name;
                    });
                    _performSearch(_searchController.text);
                  },
                );
              },
              icon: const Icon(Icons.public),
              label: Text(_selectedCountry ?? 'Select Country'),
              style: OutlinedButton.styleFrom(
                backgroundColor: _selectedCountry != null
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : null,
              ),
            ),
            if (_selectedCountry != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Chip(
                  label: Text(_selectedCountry!),
                  onDeleted: () {
                    setState(() {
                      _selectedCountry = null;
                    });
                    _performSearch(_searchController.text);
                  },
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
          ],
        ),
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
