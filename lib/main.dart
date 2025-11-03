import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:poem_application/config/theme.dart';
import 'package:poem_application/providers/theme_provider.dart';
import 'package:poem_application/screens/auth/login.dart';
import 'package:poem_application/screens/auth/google_user_info_screen.dart';
import 'package:poem_application/screens/home/home_screen.dart';
import 'package:poem_application/screens/splash_screen.dart';
import 'package:poem_application/services/fcm_service.dart';
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _checkUserDocumentExists(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print("❌ Error checking user document: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
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
