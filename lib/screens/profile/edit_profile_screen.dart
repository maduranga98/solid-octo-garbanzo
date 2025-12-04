import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:versewing/models/user_model.dart';
import 'package:versewing/providers/auth_provider.dart';
import 'package:versewing/providers/user_provider.dart';
import 'package:versewing/repositories/user_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _usernameController;

  File? _selectedImage;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  UserModel? _currentUser;

  // New fields
  Country? _selectedCountry;
  List<String> _selectedTypes = [];
  List<String> _selectedReadingLanguages = [];
  String _selectedWritingLanguage = 'English';
  bool _exploreInternational = true;

  // Content types (same as google_user_info_screen)
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

  // Available languages
  final List<String> _availableLanguages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Chinese',
    'Japanese',
    'Korean',
    'Arabic',
    'Hindi',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _firstnameController = TextEditingController();
    _lastnameController = TextEditingController();
    _usernameController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final currentUser = ref.read(firebaseAuthProvider).currentUser;
    if (currentUser == null) return;

    final userAsync = ref.read(getUserDataProvider(currentUser.uid));
    userAsync.when(
      data: (user) {
        if (user != null) {
          setState(() {
            _currentUser = user;
            _firstnameController.text = user.firstname;
            _lastnameController.text = user.lastname;
            _usernameController.text = user.userName;
            _currentImageUrl = user.photoURl;

            // Load new fields
            _selectedTypes = List<String>.from(user.type);
            _selectedReadingLanguages = List<String>.from(
              user.preferredReadingLanguages,
            );
            _selectedWritingLanguage = user.preferredWritingLanguage;
            _exploreInternational = user.exploreInternational;

            // Load country
            if (user.country.isNotEmpty) {
              try {
                final countryList = CountryService().getAll();
                _selectedCountry = countryList.firstWhere(
                  (c) => c.name == user.country,
                  orElse: () => countryList.first,
                );
              } catch (e) {
                // If country not found, leave it null
              }
            }
          });
        }
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  Future<void> _pickImage() async {
    final theme = Theme.of(context);

    try {
      final ImagePicker picker = ImagePicker();

      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose Profile Photo',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Take a Photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                if (_currentImageUrl != null || _selectedImage != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Remove Photo',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImage = null;
                        _currentImageUrl = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      );

      if (source != null) {
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
          });
          HapticFeedback.mediumImpact();
        }
      }
    } catch (e) {
      _showErrorMessage('Failed to pick image: $e');
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_selectedImage == null) return _currentImageUrl;

    setState(() => _isUploadingImage = true);

    try {
      // Use the correct path that matches storage.rules: users/{userId}/profile/{filename}
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(userId)
          .child('profile')
          .child(fileName);

      final uploadTask = await storageRef.putFile(_selectedImage!);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      _showErrorMessage('Failed to upload image: $e');
      return _currentImageUrl;
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(firebaseAuthProvider).currentUser;
    if (currentUser == null || _currentUser == null) return;

    // Validate new fields
    if (_selectedCountry == null) {
      _showErrorMessage('Please select your country');
      return;
    }

    if (_selectedTypes.isEmpty) {
      _showErrorMessage('Please select at least one content type');
      return;
    }

    if (_selectedReadingLanguages.isEmpty) {
      _showErrorMessage('Please select at least one reading language');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      // Upload image if changed
      String? photoUrl = _currentImageUrl;
      if (_selectedImage != null) {
        photoUrl = await _uploadImage(currentUser.uid);
      }

      // Update user data in Firestore
      final userRepository = ref.read(userRepositoryProvider);

      final updatedUser = _currentUser!.copyWith(
        firstname: _firstnameController.text.trim(),
        lastname: _lastnameController.text.trim(),
        userName: _usernameController.text.trim(),
        photoURl: photoUrl,
        country: _selectedCountry!.name,
        type: _selectedTypes,
        preferredReadingLanguages: _selectedReadingLanguages,
        preferredWritingLanguage: _selectedWritingLanguage,
        exploreInternational: _exploreInternational,
      );

      await userRepository.updateUserFields(currentUser.uid, {
        'firstname': updatedUser.firstname,
        'lastname': updatedUser.lastname,
        'userName': updatedUser.userName,
        'photoURl': updatedUser.photoURl,
        'country': updatedUser.country,
        'type': updatedUser.type,
        'preferredReadingLanguages': updatedUser.preferredReadingLanguages,
        'preferredWritingLanguage': updatedUser.preferredWritingLanguage,
        'exploreInternational': updatedUser.exploreInternational,
      });

      // Refresh user data
      ref.invalidate(getUserDataProvider(currentUser.uid));

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorMessage('Failed to update profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Profile Image
            Center(
              child: GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color:
                            _selectedImage != null || _currentImageUrl != null
                            ? Colors.transparent
                            : colorScheme.primaryContainer.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 3,
                        ),
                      ),
                      child: _isUploadingImage
                          ? Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                                strokeWidth: 3,
                              ),
                            )
                          : _selectedImage != null
                          ? ClipOval(
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              ),
                            )
                          : _currentImageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                _currentImageUrl!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person_outline_rounded,
                                  size: 50,
                                  color: colorScheme.primary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person_outline_rounded,
                              size: 50,
                              color: colorScheme.primary,
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          (_selectedImage != null || _currentImageUrl != null)
                              ? Icons.edit
                              : Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                (_selectedImage != null || _currentImageUrl != null)
                    ? 'Tap to change photo'
                    : 'Tap to add photo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // First Name
            TextFormField(
              controller: _firstnameController,
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'First Name',
                hintText: 'Enter your first name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'First name is required';
                }
                if (value!.trim().length < 2) {
                  return 'First name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Last Name
            TextFormField(
              controller: _lastnameController,
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Last Name',
                hintText: 'Enter your last name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Last name is required';
                }
                if (value!.trim().length < 2) {
                  return 'Last name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Username
            TextFormField(
              controller: _usernameController,
              enabled: !_isLoading,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                LengthLimitingTextInputFormatter(20),
              ],
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Choose a username',
                prefixIcon: const Icon(Icons.alternate_email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Username is required';
                }
                if (value!.trim().length < 3) {
                  return 'Username must be at least 3 characters';
                }
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                  return 'Username can only contain letters, numbers, and underscores';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email (Read-only)
            TextFormField(
              initialValue: _currentUser?.email ?? '',
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                suffixIcon: const Icon(Icons.lock_outline, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
                helperText: 'Email cannot be changed',
                helperStyle: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Country Selector
            Text(
              'Country',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading
                  ? null
                  : () {
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
            const SizedBox(height: 24),

            // Content Types
            Text(
              'What Content Do You Create?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select all that apply',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            ...(_contentTypes.map((type) {
              final isSelected = _selectedTypes.contains(type['value']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: _isLoading
                      ? null
                      : () {
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
                          ? (type['color'] as Color).withOpacity(0.1)
                          : colorScheme.surfaceContainerHighest,
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
                            color: (type['color'] as Color).withOpacity(0.2),
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
                                  color: colorScheme.onSurface.withOpacity(0.6),
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
            const SizedBox(height: 24),

            // Preferred Reading Languages
            Text(
              'Preferred Reading Languages',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select languages you want to read content in',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableLanguages.map((language) {
                final isSelected = _selectedReadingLanguages.contains(language);
                return FilterChip(
                  label: Text(language),
                  selected: isSelected,
                  onSelected: _isLoading
                      ? null
                      : (selected) {
                          setState(() {
                            if (selected) {
                              _selectedReadingLanguages.add(language);
                            } else {
                              _selectedReadingLanguages.remove(language);
                            }
                          });
                        },
                  selectedColor: colorScheme.primary.withOpacity(0.3),
                  checkmarkColor: colorScheme.primary,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Preferred Writing Language
            Text(
              'Preferred Writing Language',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select your primary writing language',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableLanguages.map((language) {
                final isSelected = _selectedWritingLanguage == language;
                return ChoiceChip(
                  label: Text(language),
                  selected: isSelected,
                  onSelected: _isLoading
                      ? null
                      : (selected) {
                          if (selected) {
                            setState(() => _selectedWritingLanguage = language);
                          }
                        },
                  selectedColor: colorScheme.primary.withOpacity(0.3),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Explore International Content
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explore International Content',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Discover content from around the world',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _exploreInternational,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() => _exploreInternational = value);
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
