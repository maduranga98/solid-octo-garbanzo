import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:poem_application/models/user_model.dart';
import 'package:poem_application/repositories/user_repository.dart';
import 'package:poem_application/screens/auth/user_preferences_intro_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  late final UserRepository _userRepository;

  AuthService() {
    _userRepository = UserRepository(_firestore);
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get FCM Token
  Future<String?> getFCMToken() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await _messaging.getToken();
        print("✅ FCM Token obtained: $token");
        return token;
      } else {
        print("⚠️ Notification permission denied");
        return null;
      }
    } catch (e) {
      print("❌ Error getting FCM token: $e");
      return null;
    }
  }

  // Update FCM Token in Firestore
  Future<void> updateFCMToken(String uid) async {
    try {
      String? fcmToken = await getFCMToken();
      if (fcmToken != null) {
        await _firestore.collection('users').doc(uid).update({
          'fcmToken': fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print("✅ FCM Token updated in Firestore");
      }
    } catch (e) {
      print("❌ Error updating FCM token: $e");
    }
  }

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required UserModel userData,
    required BuildContext context,
  }) async {
    try {
      // Validate input
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Failed to create user account');
      }

      print("✅ Firebase user created with UID: ${credential.user!.uid}");

      // Update display name
      await credential.user?.updateDisplayName(
        '${userData.firstname} ${userData.lastname}',
      );

      // Get FCM Token
      String? fcmToken = await getFCMToken();

      // Create user document in Firestore
      try {
        final userModelWithUid = UserModel(
          uid: credential.user!.uid,
          firstname: userData.firstname,
          lastname: userData.lastname,
          email: userData.email,
          userName: userData.userName,
          type: userData.type,
          country: userData.country,
          photoURl: userData.photoURl ?? '', // Ensure it's not null
          postCount: userData.postCount,
          followersCount: userData.followersCount,
          followingCount: userData.followingCount,
          createdAt: userData.createdAt,
          fcmToken: fcmToken, // Add FCM token
          // Initialize with default values - will be updated in intro screen
          preferredReadingLanguages: const ['English'],
          preferredWritingLanguage: 'English',
          exploreInternational: true,
        );

        final createdUser = await _userRepository.createNewUser(
          userModelWithUid,
        );

        if (createdUser == null) {
          print(
            "❌ Failed to create user document, cleaning up Firebase user...",
          );
          await credential.user?.delete();
          throw Exception('Failed to create user profile');
        }

        print("✅ User registration completed successfully");

        // Navigate to intro screen instead of home
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserPreferencesIntroScreen(
                userId: credential.user!.uid,
                initialUserData: createdUser,
              ),
            ),
          );
        }

        return credential;
      } catch (firestoreError) {
        print("❌ Firestore error, cleaning up Firebase user: $firestoreError");
        try {
          await credential.user?.delete();
        } catch (deleteError) {
          print("❌ Failed to cleanup Firebase user: $deleteError");
        }
        throw Exception('Failed to create user profile: $firestoreError');
      }
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase Auth error: ${e.code} - ${e.message}");
      throw _handleAuthError(e);
    } catch (e) {
      print("❌ General signup error: $e");
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Enhanced username availability check with better validation
  Future<bool> isUsernameAvailable(String username) async {
    try {
      // Basic validation
      if (username.isEmpty || username.length < 3) {
        return false;
      }

      // Check for invalid characters
      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
        return false;
      }

      // Check availability in Firestore
      return await _userRepository.isUsernameAvailable(username);
    } catch (e) {
      print("Error checking username availability: $e");
      return false;
    }
  }

  // Validate username format
  String? validateUsername(String username) {
    if (username.isEmpty) {
      return 'Username is required';
    }
    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (username.length > 20) {
      return 'Username must be less than 20 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null; // Valid
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update FCM token on sign in
      if (credential.user != null) {
        await updateFCMToken(credential.user!.uid);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Sign out first to ensure account picker shows
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User cancelled the sign-in
      if (googleUser == null) {
        print("⚠️ User cancelled Google Sign-In");
        return null;
      }

      print("✅ Google user signed in: ${googleUser.email}");

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Verify we have the required tokens
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw Exception('Failed to obtain Google authentication tokens');
      }

      print("✅ Google Auth tokens obtained");
      print(
        "Access Token: ${googleAuth.accessToken != null ? 'Present' : 'Missing'}",
      );
      print("ID Token: ${googleAuth.idToken != null ? 'Present' : 'Missing'}");

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      print("✅ Firebase authentication successful");

      // Check if this is a new user
      if (userCredential.user != null) {
        final userExists = await doesUserDocumentExist(
          userCredential.user!.uid,
        );

        if (!userExists) {
          print("📝 Creating new user document for Google Sign-In user");

          // Get FCM Token
          String? fcmToken = await getFCMToken();

          // Extract name parts
          String displayName = userCredential.user!.displayName ?? '';
          List<String> nameParts = displayName.split(' ');
          String firstName = nameParts.isNotEmpty ? nameParts[0] : '';
          String lastName = nameParts.length > 1
              ? nameParts.sublist(1).join(' ')
              : '';

          // Generate username from email
          String baseUsername = userCredential.user!.email!
              .split('@')[0]
              .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
          String username = baseUsername;
          int counter = 1;

          // Ensure username is unique
          while (!await isUsernameAvailable(username)) {
            username = '${baseUsername}_$counter';
            counter++;
          }

          // Create user model with correct types
          final newUser = UserModel(
            uid: userCredential.user!.uid,
            firstname: firstName,
            lastname: lastName,
            email: userCredential.user!.email ?? '',
            userName: username,
            type: [], // Default type
            country: '', // Will be updated later
            photoURl:
                userCredential.user!.photoURL ?? '', // Get Google profile photo
            postCount: 0,
            followersCount: 0,
            followingCount: 0,
            createdAt:
                DateTime.now(), // Changed from Timestamp.now() to DateTime.now()
            fcmToken: fcmToken,
            preferredReadingLanguages: [
              'English',
            ], // Changed from const ['English'] to ['English']
            preferredWritingLanguage: 'English',
            exploreInternational: true,
          );

          await _userRepository.createNewUser(newUser);
          print("✅ New user document created successfully");
        } else {
          // Update FCM token for existing user
          await updateFCMToken(userCredential.user!.uid);

          // Update photo URL if it's empty in Firestore but exists in Google profile
          final userData = await getUserData(userCredential.user!.uid);
          if (userData != null &&
              (userData.photoURl == null || userData.photoURl!.isEmpty) &&
              userCredential.user!.photoURL != null) {
            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .update({'photoURl': userCredential.user!.photoURL});
            print("✅ Updated photo URL from Google profile");
          }
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print(
        "❌ Firebase Auth error during Google Sign-In: ${e.code} - ${e.message}",
      );
      throw _handleAuthError(e);
    } on Exception catch (e) {
      print("❌ Platform error during Google Sign-In: $e");
      throw Exception(
        'Failed to sign in with Google. Please check your internet connection and try again.',
      );
    } catch (e) {
      print("❌ General error during Google Sign-In: $e");
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // Check if user document exists in Firestore
  Future<bool> doesUserDocumentExist(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print("❌ Error checking user document: $e");
      return false;
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    return await _userRepository.getUserData(uid);
  }

  // Update user data
  Future<UserModel?> updateUserData(String uid, UserModel data) async {
    return await _userRepository.updateUserData(uid, data);
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      print("✅ User signed out successfully");
    } catch (e) {
      print("❌ Error signing out: $e");
      throw Exception('Failed to sign out: $e');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _userRepository.deleteUser(user.uid);
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Re-authenticate user
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(credential);

        // Update password
        await user.updatePassword(newPassword);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Update email
  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Re-authenticate user
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(credential);

        // Update email in Firebase Auth
        // await user.updateEmail(newEmail);

        // Get current user data and update email in Firestore
        final userData = await getUserData(user.uid);
        if (userData != null) {
          final updatedUserData = userData.copyWith(email: newEmail);
          await updateUserData(user.uid, updatedUserData);
        }
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Stream of user data changes
  Stream<UserModel?> getUserDataStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromFirestore(snapshot);
      }
      return null;
    });
  }

  // Search users by username or name
  Future<List<UserModel>> searchUsers(String query) async {
    return await _userRepository.searchUsers(query);
  }

  // Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    return await _userRepository.getUserByUsername(username);
  }

  // Handle Firebase Auth errors
  Exception _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception('The password provided is too weak.');
      case 'email-already-in-use':
        return Exception('An account already exists for that email.');
      case 'user-not-found':
        return Exception('No user found for that email.');
      case 'wrong-password':
        return Exception('Wrong password provided.');
      case 'invalid-email':
        return Exception('The email address is not valid.');
      case 'user-disabled':
        return Exception('This user account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many requests. Try again later.');
      case 'operation-not-allowed':
        return Exception('Signing in with Email and Password is not enabled.');
      case 'requires-recent-login':
        return Exception('This operation requires recent authentication.');
      case 'invalid-credential':
        return Exception('The provided credentials are invalid.');
      case 'network-request-failed':
        return Exception('Network error. Please check your connection.');
      default:
        return Exception('Authentication failed: ${e.message}');
    }
  }
}
