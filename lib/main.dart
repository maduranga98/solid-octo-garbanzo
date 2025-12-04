import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:versewing/config/theme.dart';
import 'package:versewing/providers/theme_provider.dart';
import 'package:versewing/screens/auth/google_user_info_screen.dart';
import 'package:versewing/screens/auth/login.dart';
import 'package:versewing/screens/home/home_screen.dart';
import 'package:versewing/screens/splash_screen.dart';
import 'package:versewing/services/fcm_service.dart';
import 'package:versewing/utils/crashlytics_helper.dart';
import 'firebase_options.dart';

// Background message handler for Firebase Cloud Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await firebaseMessagingBackgroundHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase Cloud Messaging background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Poem Application',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // Add these required localization delegates
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US')],
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    // Show splash screen for minimum 2.5 seconds
    _splashTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  Future<bool> _checkUserDocumentExists(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return doc.exists;
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Error checking user document exists in AuthWrapper',
        additionalInfo: {'uid': uid},
      );
      print("❌ Error checking user document: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always show splash screen for minimum duration on app startup
    if (_showSplash) {
      return const SplashScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Show splash screen while checking auth state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // If no user is authenticated, show login screen
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const Login();
        }

        final user = authSnapshot.data!;

        // Check if user document exists in Firestore
        return FutureBuilder<bool>(
          future: _checkUserDocumentExists(user.uid),
          builder: (context, firestoreSnapshot) {
            // Show splash screen while checking Firestore
            if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            // If user document exists, go to home screen
            if (firestoreSnapshot.data == true) {
              return const HomeScreen();
            }

            // If user document doesn't exist (e.g., new Google user), collect info
            return GoogleUserInfoScreen(firebaseUser: user);
          },
        );
      },
    );
  }
}
