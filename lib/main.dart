import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/screens/auth/login.dart';
import 'package:poem_application/screens/auth/signup.dart';
import 'package:poem_application/screens/home/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter bindings are initialized before any async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables first (Firebase config depends on these)
  await dotenv.load(fileName: ".env");

  // Initialize Firebase after dotenv is loaded
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Flutter Demo', home: const HomeScreen());
  }
}
