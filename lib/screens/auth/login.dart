import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poem_application/screens/auth/signup.dart';
import 'package:poem_application/screens/auth/google_user_info_screen.dart';
import 'package:poem_application/screens/home/home_screen.dart';
import 'package:poem_application/services/auth_service.dart';
import 'package:poem_application/widgets/emailInputField.dart';
import 'package:poem_application/widgets/passwordInputField.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        _showSuccessMessage('Welcome back!');
        // Navigator.of(context).pushReplacementNamed('/home');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final credential = await _authService.signInWithGoogle();

      if (credential == null) {
        // User cancelled the sign-in
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      if (credential.user == null) {
        throw Exception('Failed to sign in with Google');
      }

      // Check if user document exists in Firestore
      final userExists = await _authService.doesUserDocumentExist(credential.user!.uid);

      if (mounted) {
        if (userExists) {
          // User already has a profile, go to home
          _showSuccessMessage('Welcome back!');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // New Google user, collect additional info
          _showSuccessMessage('Please complete your profile');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GoogleUserInfoScreen(
                firebaseUser: credential.user!,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);

    try {
      // Note: Apple Sign-In requires additional setup and the sign_in_with_apple package
      // This is a placeholder - you'll need to implement Apple Sign-In separately
      await Future.delayed(const Duration(seconds: 1)); // Placeholder

      if (mounted) {
        _showErrorMessage('Apple Sign-In coming soon!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(e.toString());
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 40),

                          // App Logo and Title
                          _buildHeader(theme),

                          const SizedBox(height: 48),

                          // Login Form
                          _buildLoginForm(theme),

                          const SizedBox(height: 32),

                          // Social Login Buttons
                          _buildSocialLoginSection(theme),

                          const Spacer(),

                          // Sign Up Link
                          _buildSignUpLink(theme),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        // App Icon
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_stories,
            color: theme.colorScheme.onPrimary,
            size: 40,
          ),
        ),

        const SizedBox(height: 24),

        // App Title
        Text(
          'Poetic',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Welcome back to your poetry journey',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Input
          EmailInputField(
            controller: _emailController,
            required: true,
            // enabled: !_isLoading,
          ),

          const SizedBox(height: 16),

          // Password Input
          PasswordInputField(
            controller: _passwordController,
            required: true,
            // enabled: !_isLoading,
          ),

          const SizedBox(height: 12),

          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.of(context).pushNamed('/forgot-password');
                    },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Login Button
          FilledButton(
            onPressed: _isLoading ? null : _signInWithEmail,
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
                : const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLoginSection(ThemeData theme) {
    return Column(
      children: [
        // Divider with text
        Row(
          children: [
            Expanded(
              child: Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Social Login Buttons
        Row(
          children: [
            // Google Sign In
            Expanded(
              child: _buildSocialButton(
                icon: Icons.g_mobiledata,
                label: 'Google',
                onPressed: _isLoading ? null : _signInWithGoogle,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                borderColor: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),

            const SizedBox(width: 12),

            // Apple Sign In
            Expanded(
              child: _buildSocialButton(
                icon: Icons.apple,
                label: 'Apple',
                onPressed: _isLoading ? null : _signInWithApple,
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                borderColor: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
    required Color borderColor,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        side: BorderSide(color: borderColor, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    );
  }

  Widget _buildSignUpLink(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Signup()),
                    );
                  },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Sign Up',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
