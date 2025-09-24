import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poem_application/models/user_model.dart';
import 'package:poem_application/repositories/user_repository.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final UserRepository _userRepository;

  AuthService() {
    _userRepository = UserRepository(_firestore);
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required UserModel userData,
  }) async {
    try {
      // ✅ STEP 1: Check username availability FIRST
      print("Checking username availability: ${userData.userName}");
      final isUsernameAvailable = await _userRepository.isUsernameAvailable(
        userData.userName,
      );

      if (!isUsernameAvailable) {
        throw Exception('Username "${userData.userName}" is already taken');
      }
      print("✅ Username is available: ${userData.userName}");

      // ✅ STEP 2: Check if email is already registered
      // try {
      //   final signInMethods = await _auth.fetchSignInMethodsForEmail(email);
      //   if (signInMethods.isNotEmpty) {
      //     throw Exception('An account already exists with this email address');
      //   }
      // } catch (e) {
      //   // If fetchSignInMethodsForEmail fails, continue (email might be available)
      //   print("Could not check email availability: $e");
      // }

      // ✅ STEP 3: Create Firebase user account
      print("Creating Firebase user account...");
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Failed to create user account');
      }

      print("✅ Firebase user created with UID: ${credential.user!.uid}");

      // ✅ STEP 4: Update display name
      await credential.user?.updateDisplayName(
        '${userData.firstname} ${userData.lastname}',
      );

      // ✅ STEP 5: Create user document in Firestore using UserRepository
      try {
        final userModelWithUid = UserModel(
          uid: credential.user!.uid,
          firstname: userData.firstname,
          lastname: userData.lastname,
          email: userData.email,
          userName: userData.userName,
          type: userData.type,
          country: userData.country,
          photoURl: userData.photoURl,
          postCount: userData.postCount,
          followersCount: userData.followersCount,
          followingCount: userData.followingCount,
          createdAt: userData.createdAt,
        );

        final createdUser = await _userRepository.createNewUser(
          userModelWithUid,
        );

        if (createdUser == null) {
          // If Firestore document creation fails, delete the Firebase user
          print(
            "❌ Failed to create user document, cleaning up Firebase user...",
          );
          await credential.user?.delete();
          throw Exception('Failed to create user profile');
        }

        print("✅ User registration completed successfully");
        return credential;
      } catch (firestoreError) {
        // If Firestore creation fails, clean up the Firebase user
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

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      // final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      // if (googleUser == null) return null;

      // Obtain the auth details from the request
      // final GoogleSignInAuthentication googleAuth =
      //     await googleUser.authentication;

      // Create a new credential
      // final credential = GoogleAuthProvider.credential(
      //   accessToken: googleAuth.accessToken,
      //   idToken: googleAuth.idToken,
      // );

      // Sign in to Firebase with the Google credential
      // final userCredential = await _auth.signInWithCredential(credential);

      // Create user document if doesn't exist
      // if (userCredential.user != null) {
      //   await _ensureUserDocument(userCredential.user!);
      // }

      // return userCredential;
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
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
      // await _googleSignIn.signOut();
    } catch (e) {
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
      // case 'too-many-requests':
      //   return Exception('Too many attempts. Please try again later.');
      default:
        return Exception('Authentication failed: ${e.message}');
    }
  }
}
