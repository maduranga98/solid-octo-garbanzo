import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/models/user_model.dart';
import 'package:poem_application/repositories/user_repository.dart';
import 'package:poem_application/services/auth_service.dart';
import 'package:poem_application/screens/auth/user_preferences_intro_screen.dart';
import 'package:poem_application/providers/fcm_provider.dart';
import 'package:poem_application/providers/firestore_provider.dart';
import 'package:poem_application/widgets/inputfields.dart';

/// Screen to collect additional user information after Google Sign-In
class GoogleUserInfoScreen extends ConsumerStatefulWidget {
  final User firebaseUser;

  const GoogleUserInfoScreen({
    super.key,
    required this.firebaseUser,
  });

  @override
  ConsumerState<GoogleUserInfoScreen> createState() => _GoogleUserInfoScreenState();
}

class _GoogleUserInfoScreenState extends ConsumerState<GoogleUserInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();

  // Controllers
  final TextEditingController _usernameController = TextEditingController();

  // State variables
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  Country? _selectedCountry;
  List<String> _selectedTypes = [];
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUsernameAvailable = false;
  bool _isCheckingUsername = false;

  // User content types
  final List<Map<String, dynamic>> _contentTypes = [
    {
      'title': 'Poetry',
      'subtitle': 'Poets, spoken word, haiku, verses',
      'icon': Icons.auto_stories,
      'value': 'poetry',
      'color': const Color(0xFF6366F1),
    },
    {
      'title': 'Lyrics',
      'subtitle': 'Songwriters, rap, chants, melodies',
      'icon': Icons.music_note,
      'value': 'lyrics',
      'color': const Color(0xFF10B981),
    },
    {
      'title': 'Stories',
      'subtitle': 'Short stories, novels, folklore, prose',
      'icon': Icons.menu_book,
      'value': 'stories',
      'color': const Color(0xFF8B5CF6),
    },
    {
      'title': 'Quotes & Aphorisms',
      'subtitle': 'Inspirations, reflections, timeless lines',
      'icon': Icons.format_quote,
      'value': 'quotes',
      'color': const Color(0xFFF59E0B),
    },
    {
      'title': 'Microfiction',
      'subtitle': 'Tiny tales, flash fiction, one-liners',
      'icon': Icons.bolt,
      'value': 'microfiction',
      'color': const Color(0xFFEF4444),
    },
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Check username availability with debounce
  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty || username.length < 3) {
      setState(() {
        _isUsernameAvailable = false;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() => _isCheckingUsername = true);

    // Debounce
    await Future.delayed(const Duration(milliseconds: 500));

    final isAvailable = await _authService.isUsernameAvailable(username);

    if (mounted) {
      setState(() {
        _isUsernameAvailable = isAvailable;
        _isCheckingUsername = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to pick image: $e');
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    setState(() => _isUploadingImage = true);

    try {
      final fileName = 'profile_${widget.firebaseUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('profile_images').child(fileName);

      final uploadTask = ref.putFile(_selectedImage!);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() => _isUploadingImage = false);

      return downloadUrl;
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        _showErrorMessage('Failed to upload image: $e');
      }
      return null;
    }
  }

  Future<void> _completeRegistration() async {
    // Validation is already handled in _nextPage for each step
    // Final validation check before creating the user
    if (_usernameController.text.trim().isEmpty) {
      _showErrorMessage('Username is required');
      return;
    }

    if (_selectedCountry == null) {
      _showErrorMessage('Please select your country');
      return;
    }

    if (_selectedTypes.isEmpty) {
      _showErrorMessage('Please select at least one content type');
      return;
    }

    if (!_isUsernameAvailable) {
      _showErrorMessage('Username is not available');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload profile image if selected
      if (_selectedImage != null) {
        _uploadedImageUrl = await _uploadImage();
      }

      // Get FCM token
      final fcmService = ref.read(fcmServiceProvider);
      final fcmToken = await fcmService.getToken();

      // Parse user's display name
      final displayName = widget.firebaseUser.displayName ?? '';
      final nameParts = displayName.split(' ');
      final firstname = nameParts.isNotEmpty ? nameParts[0] : '';
      final lastname = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Create user model
      final userModel = UserModel(
        uid: widget.firebaseUser.uid,
        firstname: firstname,
        lastname: lastname,
        email: widget.firebaseUser.email ?? '',
        userName: _usernameController.text.trim(),
        type: _selectedTypes,
        country: _selectedCountry!.name,
        photoURl: _uploadedImageUrl ?? widget.firebaseUser.photoURL,
        postCount: 0,
        followersCount: 0,
        followingCount: 0,
        createdAt: DateTime.now(),
        preferredReadingLanguages: const ['English'],
        preferredWritingLanguage: 'English',
        exploreInternational: true,
        fcmToken: fcmToken,
      );

      // Save to Firestore
      final userRepository = UserRepository(
        ref.read(firestoreProvider),
      );
      final createdUser = await userRepository.createNewUser(userModel);

      if (createdUser == null) {
        throw Exception('Failed to create user profile');
      }

      // Initialize FCM
      await fcmService.initialize();
      if (fcmToken != null) {
        fcmService.listenToTokenRefresh(widget.firebaseUser.uid);
      }

      if (mounted) {
        _showSuccessMessage('Account created successfully!');

        // Navigate to preferences intro screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => UserPreferencesIntroScreen(
              userId: widget.firebaseUser.uid,
              initialUserData: createdUser,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to complete registration: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorMessage(String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _nextPage() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
      if (!_isUsernameAvailable) {
        _showErrorMessage('Username is not available');
        return;
      }
    } else if (_currentStep == 1) {
      if (_selectedCountry == null) {
        _showErrorMessage('Please select your country');
        return;
      }
      if (_selectedTypes.isEmpty) {
        _showErrorMessage('Please select at least one content type');
        return;
      }
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),

          // Page view
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [
                _buildUsernameStep(theme),
                _buildCountryAndTypeStep(theme),
                _buildProfilePhotoStep(theme),
              ],
            ),
          ),

          // Navigation buttons
          _buildNavigationButtons(theme),
        ],
      ),
    );
  }

  Widget _buildUsernameStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Choose a Username',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will be your unique identifier on the platform',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Display name (from Google)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.firebaseUser.displayName ?? 'Not provided',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Email (from Google)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.firebaseUser.email ?? 'Not provided',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Username input
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Choose a unique username',
                prefixIcon: const Icon(Icons.alternate_email),
                suffixIcon: _isCheckingUsername
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _usernameController.text.isNotEmpty && _usernameController.text.length >= 3
                        ? Icon(
                            _isUsernameAvailable ? Icons.check_circle : Icons.cancel,
                            color: _isUsernameAvailable ? Colors.green : Colors.red,
                          )
                        : null,
              ),
              onChanged: (value) {
                _checkUsernameAvailability(value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username';
                }
                final validation = _authService.validateUsername(value);
                return validation;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryAndTypeStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            'Select Your Country',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Country selector
          OutlinedButton(
            onPressed: () {
              showCountryPicker(
                context: context,
                showPhoneCode: false,
                onSelect: (Country country) {
                  setState(() => _selectedCountry = country);
                },
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCountry?.name ?? 'Select Country',
                  style: theme.textTheme.bodyLarge,
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'What Content Do You Create?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),

          // Content type cards
          ...(_contentTypes.map((type) {
            final isSelected = _selectedTypes.contains(type['value']);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTypes.remove(type['value']);
                    } else {
                      _selectedTypes.add(type['value']);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (type['color'] as Color).withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? type['color'] as Color
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (type['color'] as Color).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          type['icon'] as IconData,
                          color: type['color'] as Color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type['title'] as String,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              type['subtitle'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: type['color'] as Color,
                        ),
                    ],
                  ),
                ),
              ),
            );
          })),
        ],
      ),
    );
  }

  Widget _buildProfilePhotoStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            'Add a Profile Photo',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Optional - You can add this later',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),

          // Profile photo picker
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 3,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipOval(
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : widget.firebaseUser.photoURL != null
                        ? ClipOval(
                            child: Image.network(
                              widget.firebaseUser.photoURL!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.add_a_photo,
                            size: 50,
                            color: theme.colorScheme.primary,
                          ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          if (_selectedImage == null)
            Center(
              child: TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from Gallery'),
              ),
            ),

          if (_selectedImage != null)
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Change Photo'),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _selectedImage = null);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _isLoading || _isUploadingImage
                  ? null
                  : _currentStep < 2
                      ? _nextPage
                      : _completeRegistration,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading || _isUploadingImage
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_currentStep < 2 ? 'Next' : 'Complete'),
            ),
          ),
        ],
      ),
    );
  }
}
