import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import 'package:poem_application/models/user_model.dart';
import 'package:poem_application/services/auth_service.dart';
import 'package:poem_application/widgets/inputfields.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();

  // Controllers
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // State variables
  int _currentStep = 0;
  bool _isLoading = false;
  Country? _selectedCountry;
  List<String> _selectedTypes = [];
  bool _acceptTerms = false;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // User content types with enhanced data
  final List<Map<String, dynamic>> _contentTypes = [
    {
      'title': 'Poetry',
      'subtitle': 'Poets, spoken word, haiku, quotes',
      'icon': Icons.auto_stories,
      'value': 'poetry',
      'color': const Color(0xFF6366F1),
    },
    {
      'title': 'Lyrics',
      'subtitle': 'Songwriters, rap, chants',
      'icon': Icons.music_note,
      'value': 'lyrics',
      'color': const Color(0xFF10B981),
    },
    {
      'title': 'Stories',
      'subtitle': 'Short stories, novels, folklore, prose',
      'icon': Icons.book,
      'value': 'stories',
      'color': const Color(0xFF8B5CF6),
    },
    {
      'title': 'Scripts & Plays',
      'subtitle': 'Stage, dialogues, performance pieces',
      'icon': Icons.theater_comedy,
      'value': 'scripts',
      'color': const Color(0xFFF59E0B),
    },
    {
      'title': 'Essays & Reflections',
      'subtitle': 'Philosophy, journals, thought pieces',
      'icon': Icons.article,
      'value': 'essays',
      'color': const Color(0xFFEF4444),
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateFinalStep()) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      // Create user document in Firestore
      final userData = UserModel(
        uid: "",
        firstname: _firstnameController.text.trim(),
        lastname: _lastnameController.text.trim(),
        email: _emailController.text.trim(),
        userName: _usernameController.text.trim(),
        type: _selectedTypes,
        country: _selectedCountry!.name,
        photoURl: null,
        postCount: 0,
        followersCount: 0,
        followingCount: 0,
        createdAt: DateTime.now(),
      );

      // await _authService.saveUserData(userData);
      _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        userData: userData,
      );

      if (mounted) {
        _showSuccessMessage('Welcome to Poetic! Account created successfully.');
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(_getErrorMessage(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('weak-password')) {
      return 'Password is too weak. Please use a stronger password.';
    } else if (error.contains('email-already-in-use')) {
      return 'An account already exists with this email address.';
    } else if (error.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    return 'Failed to create account. Please try again.';
  }

  void _showErrorMessage(String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _nextStep() {
    HapticFeedback.lightImpact();

    if (_currentStep < 2) {
      if (_currentStep == 0 && !_validatePersonalInfo()) {
        _showErrorMessage('Please fill in all required fields');
        return;
      }
      if (_currentStep == 1 && !_validateAccountInfo()) {
        _showErrorMessage('Please check your account details');
        return;
      }

      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleSignup();
    }
  }

  void _previousStep() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validatePersonalInfo() {
    return _firstnameController.text.trim().isNotEmpty &&
        _lastnameController.text.trim().isNotEmpty &&
        _selectedCountry != null;
  }

  bool _validateAccountInfo() {
    final form = _formKey.currentState;
    if (form != null && !form.validate()) return false;

    return _usernameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty &&
        _confirmPasswordController.text.trim().isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;
  }

  bool _validateFinalStep() {
    if (_selectedTypes.isEmpty) {
      _showErrorMessage('Please select at least one content type');
      return false;
    }
    if (!_acceptTerms) {
      _showErrorMessage('Please accept the Terms and Conditions');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(theme),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildPersonalInfoStep(theme),
                        _buildAccountInfoStep(theme),
                        _buildPreferencesStep(theme),
                      ],
                    ),
                  ),
                ),
                _buildNavigationButtons(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentStep > 0)
                IconButton(
                  onPressed: _isLoading ? null : _previousStep,
                  icon: const Icon(Icons.arrow_back),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceVariant
                        .withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () =>
                          Navigator.of(context).pushReplacementNamed('/login'),
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Enhanced Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: List.generate(3, (index) {
                final isActive = index <= _currentStep;
                final isCompleted = index < _currentStep;

                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 4,
                          decoration: BoxDecoration(
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(
                                    alpha: 0.2,
                                  ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (index < 2) const SizedBox(width: 8),
                    ],
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 24),

          // Step indicator with icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStepIcon(),
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${_currentStep + 1} of 3',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _getStepTitle(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            _getStepSubtitle(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),

          InputField(
            label: 'First Name',
            hint: 'Enter your first name',
            controller: _firstnameController,
            required: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.person_outline),
            enabled: !_isLoading,
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

          const SizedBox(height: 20),

          InputField(
            label: 'Last Name',
            hint: 'Enter your last name',
            controller: _lastnameController,
            required: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.person_outline),
            enabled: !_isLoading,
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

          const SizedBox(height: 20),

          _buildCountryPicker(theme),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAccountInfoStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),

          InputField(
            label: 'Username',
            hint: 'Choose a unique username',
            controller: _usernameController,
            required: true,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.alternate_email),
            enabled: !_isLoading,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
              LengthLimitingTextInputFormatter(20),
            ],
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'Username is required';
              }
              if (value!.length < 3) {
                return 'Username must be at least 3 characters';
              }
              if (value.length > 20) {
                return 'Username must be less than 20 characters';
              }
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                return 'Username can only contain letters, numbers, and underscores';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          InputField(
            label: 'Email',
            hint: 'Enter your email address',
            controller: _emailController,
            required: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.email_outlined),
            enabled: !_isLoading,
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'Email is required';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value!)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          InputField(
            label: 'Password',
            hint: 'Create a strong password (min. 6 characters)',
            controller: _passwordController,
            required: true,
            obscureText: true,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.lock_outline),
            enabled: !_isLoading,
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'Password is required';
              }
              if (value!.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          InputField(
            label: 'Confirm Password',
            hint: 'Confirm your password',
            controller: _confirmPasswordController,
            required: true,
            obscureText: true,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.lock_outline),
            enabled: !_isLoading,
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPreferencesStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          Text(
            'What type of content do you create?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Select all that apply to help us personalize your experience',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),

          const SizedBox(height: 24),

          // Content types with enhanced styling
          ...List.generate(_contentTypes.length, (index) {
            final type = _contentTypes[index];
            final isSelected = _selectedTypes.contains(type['value']);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            if (isSelected) {
                              _selectedTypes.remove(type['value']);
                            } else {
                              _selectedTypes.add(type['value']);
                            }
                          });
                        },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? type['color']
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: isSelected
                          ? type['color'].withValues(alpha: 0.05)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? type['color'].withValues(alpha: 0.1)
                                : theme.colorScheme.surfaceVariant.withValues(
                                    alpha: 0.5,
                                  ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            type['icon'],
                            color: isSelected
                                ? type['color']
                                : theme.colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type['title'],
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type['subtitle'],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        AnimatedScale(
                          scale: isSelected ? 1.0 : 0.8,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? type['color']
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? type['color']
                                    : theme.colorScheme.outline.withValues(
                                        alpha: 0.3,
                                      ),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.check,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Terms and conditions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _acceptTerms,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() => _acceptTerms = value ?? false);
                      },
                activeColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                          setState(() => _acceptTerms = !_acceptTerms);
                        },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, right: 8),
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms and Conditions',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCountryPicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Country',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading
                ? null
                : () {
                    showCountryPicker(
                      context: context,
                      showPhoneCode: false,
                      onSelect: (Country country) {
                        setState(() {
                          _selectedCountry = country;
                        });
                      },
                      countryListTheme: CountryListThemeData(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20.0),
                          topRight: Radius.circular(20.0),
                        ),
                        inputDecoration: InputDecoration(
                          labelText: 'Search',
                          hintText: 'Start typing to search',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.public,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  if (_selectedCountry != null) ...[
                    Text(
                      _selectedCountry!.flagEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      _selectedCountry?.name ?? 'Select your country',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: _selectedCountry == null
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Previous',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 16),

          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: FilledButton(
              onPressed: _isLoading ? null : _nextStep,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _isLoading ? 0 : 2,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getButtonText(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_currentStep < 2) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStepIcon() {
    switch (_currentStep) {
      case 0:
        return Icons.person_outline;
      case 1:
        return Icons.account_circle_outlined;
      case 2:
        return Icons.tune;
      default:
        return Icons.person_outline;
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Personal Information';
      case 1:
        return 'Account Details';
      case 2:
        return 'Content Preferences';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Tell us about yourself';
      case 1:
        return 'Create your account credentials';
      case 2:
        return 'Customize your creative journey';
      default:
        return '';
    }
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 0:
      case 1:
        return 'Next';
      case 2:
        return 'Create Account';
      default:
        return 'Next';
    }
  }
}
