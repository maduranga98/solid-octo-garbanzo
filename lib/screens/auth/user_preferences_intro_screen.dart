import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poem_application/models/user_model.dart';
import 'package:poem_application/repositories/user_repository.dart';
import 'package:poem_application/screens/home/home_screen.dart';
import 'package:introduction_screen/introduction_screen.dart';

class UserPreferencesIntroScreen extends ConsumerStatefulWidget {
  final String userId;
  final UserModel initialUserData;

  const UserPreferencesIntroScreen({
    super.key,
    required this.userId,
    required this.initialUserData,
  });

  @override
  ConsumerState<UserPreferencesIntroScreen> createState() =>
      _UserPreferencesIntroScreenState();
}

class _UserPreferencesIntroScreenState
    extends ConsumerState<UserPreferencesIntroScreen> {
  final GlobalKey<IntroductionScreenState> _introKey =
      GlobalKey<IntroductionScreenState>();

  // Language preferences
  final List<String> _selectedReadingLanguages = ['English'];
  String _selectedWritingLanguage = 'English';
  bool _exploreInternational = true;
  bool _isSaving = false;

  // Available languages with flags
  final Map<String, String> _availableLanguages = {
    'English': '🇬🇧',
    'Sinhala': '🇱🇰',
    'Japanese': '🇯🇵',
    'Hindi': '🇮🇳',
    'Spanish': '🇪🇸',
    'French': '🇫🇷',
    'German': '🇩🇪',
    'Chinese': '🇨🇳',
    'Korean': '🇰🇷',
    'Arabic': '🇸🇦',
    'Portuguese': '🇵🇹',
    'Russian': '🇷🇺',
    'Italian': '🇮🇹',
    'Tamil': '🇮🇳',
  };

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    try {
      // Update user data with preferences
      final updatedUserData = widget.initialUserData.copyWith(
        preferredReadingLanguages: _selectedReadingLanguages,
        preferredWritingLanguage: _selectedWritingLanguage,
        exploreInternational: _exploreInternational,
      );

      // Save to Firestore
      final userRepository = UserRepository(FirebaseFirestore.instance);
      await userRepository.updateUserData(widget.userId, updatedUserData);

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: IntroductionScreen(
        key: _introKey,
        pages: [
          _buildWelcomePage(theme, colorScheme),
          _buildReadingLanguagesPage(theme, colorScheme),
          _buildWritingLanguagePage(theme, colorScheme),
          _buildExploreInternationalPage(theme, colorScheme),
        ],
        onDone: _savePreferences,
        onSkip: _savePreferences,
        showSkipButton: true,
        skip: Text('Skip', style: TextStyle(color: colorScheme.primary)),
        next: Icon(Icons.arrow_forward, color: colorScheme.primary),
        done: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                'Done',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
        dotsDecorator: DotsDecorator(
          size: const Size.square(10.0),
          activeSize: const Size(22.0, 10.0),
          activeColor: colorScheme.primary,
          color: colorScheme.outline,
          spacing: const EdgeInsets.symmetric(horizontal: 3.0),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        globalBackgroundColor: colorScheme.surface,
        skipStyle: TextButton.styleFrom(foregroundColor: colorScheme.primary),
        doneStyle: TextButton.styleFrom(foregroundColor: colorScheme.primary),
        nextStyle: IconButton.styleFrom(foregroundColor: colorScheme.primary),
      ),
    );
  }

  PageViewModel _buildWelcomePage(ThemeData theme, ColorScheme colorScheme) {
    return PageViewModel(
      title: "Welcome to Poetic! ✨",
      bodyWidget: Column(
        children: [
          Text(
            "Let's personalize your experience",
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              size: 80,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
      decoration: PageDecoration(
        titleTextStyle: theme.textTheme.headlineMedium!.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        bodyPadding: const EdgeInsets.all(24),
        imagePadding: const EdgeInsets.only(top: 40),
      ),
    );
  }

  PageViewModel _buildReadingLanguagesPage(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return PageViewModel(
      title: "Preferred Reading Languages",
      bodyWidget: Column(
        children: [
          Text(
            "Select all languages you'd like to read content in",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _availableLanguages.entries.map((entry) {
              final isSelected = _selectedReadingLanguages.contains(entry.key);
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.value, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(entry.key),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedReadingLanguages.add(entry.key);
                    } else {
                      if (_selectedReadingLanguages.length > 1) {
                        _selectedReadingLanguages.remove(entry.key);
                      }
                    }
                  });
                  HapticFeedback.selectionClick();
                },
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerHighest,
              );
            }).toList(),
          ),
        ],
      ),
      decoration: PageDecoration(
        titleTextStyle: theme.textTheme.headlineMedium!.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        bodyPadding: const EdgeInsets.all(24),
      ),
    );
  }

  PageViewModel _buildWritingLanguagePage(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return PageViewModel(
      title: "Preferred Writing Language",
      bodyWidget: Column(
        children: [
          Text(
            "Select the primary language you'll create content in",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _availableLanguages.entries.map((entry) {
              final isSelected = _selectedWritingLanguage == entry.key;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.value, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(entry.key),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedWritingLanguage = entry.key;
                    });
                    HapticFeedback.selectionClick();
                  }
                },
                selectedColor: colorScheme.primaryContainer,
                backgroundColor: colorScheme.surfaceContainerHighest,
                labelStyle: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      decoration: PageDecoration(
        titleTextStyle: theme.textTheme.headlineMedium!.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        bodyPadding: const EdgeInsets.all(24),
      ),
    );
  }

  PageViewModel _buildExploreInternationalPage(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return PageViewModel(
      title: "Explore International Content",
      bodyWidget: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.public_rounded,
              size: 80,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Would you like to explore international creations?",
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Discover poetry, stories, and more from creators worldwide",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildExploreOption(
                icon: Icons.check_circle_rounded,
                label: 'Yes',
                value: true,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 24),
              _buildExploreOption(
                icon: Icons.cancel_rounded,
                label: 'No',
                value: false,
                theme: theme,
                colorScheme: colorScheme,
              ),
            ],
          ),
        ],
      ),
      decoration: PageDecoration(
        titleTextStyle: theme.textTheme.headlineMedium!.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        bodyPadding: const EdgeInsets.all(24),
      ),
    );
  }

  Widget _buildExploreOption({
    required IconData icon,
    required String label,
    required bool value,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _exploreInternational == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _exploreInternational = value;
        });
        HapticFeedback.selectionClick();
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
