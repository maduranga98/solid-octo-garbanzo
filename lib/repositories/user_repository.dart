// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poem_application/models/user_model.dart';

class UserRepository {
  final FirebaseFirestore firestore;
  UserRepository(this.firestore);

  // Create user with UID as document ID
  Future<UserModel?> createNewUser(UserModel userData) async {
    try {
      // Validate required fields
      if (userData.uid.isEmpty) {
        print("Error: UID is required to create user document");
        return null;
      }

      if (userData.email.isEmpty || userData.userName.isEmpty) {
        print("Error: Email and username are required");
        return null;
      }

      // Check if user document already exists
      final existingDoc = await firestore
          .collection('users')
          .doc(userData.uid)
          .get();
      if (existingDoc.exists) {
        print("User document already exists for UID: ${userData.uid}");
        return UserModel.fromFirestore(existingDoc);
      }

      // Check if username is already taken
      final usernameQuery = await firestore
          .collection('users')
          .where('userName', isEqualTo: userData.userName)
          .limit(1)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw Exception('Username "${userData.userName}" is already taken');
      }

      // Create user document with UID as document ID
      // ✅ Ensure data types are correct before saving
      final userDataMap = userData.toFirestore();
      print("Creating user with data: $userDataMap");

      await firestore
          .collection("users")
          .doc(userData.uid) // ✅ Using UID as document ID
          .set(userDataMap);

      // Verify the document was created successfully
      final createdDoc = await firestore
          .collection('users')
          .doc(userData.uid)
          .get();
      if (createdDoc.exists) {
        print("✅ User created successfully with UID: ${userData.uid}");

        // ✅ Use safe parsing when reading back from Firestore
        try {
          return UserModel.fromFirestore(createdDoc);
        } catch (parseError) {
          print("Error parsing created user data: $parseError");
          // Return the original userData since we know it's valid
          return userData;
        }
      } else {
        print("❌ Failed to verify user creation");
        return null;
      }
    } on FirebaseException catch (e) {
      print("Firebase error creating user: ${e.message}");
      throw Exception('Failed to create user: ${e.message}');
    } catch (e) {
      print("Error creating user: $e");
      throw Exception('Failed to create user: $e');
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      if (username.isEmpty || username.length < 3) {
        return false;
      }

      final query = await firestore
          .collection('users')
          .where('userName', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      return query.docs.isEmpty;
    } catch (e) {
      print("Error checking username availability: $e");
      return false;
    }
  }

  // Get the user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      if (uid.isEmpty) {
        print("Error: UID cannot be empty");
        return null;
      }

      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        print(doc.exists);
        return UserModel.fromFirestore(doc);
      }
      print("User document not found for UID: $uid");
      return null;
    } on Exception catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  // Update the user data
  Future<UserModel?> updateUserData(String uid, UserModel data) async {
    try {
      if (uid.isEmpty) {
        print("Error: UID cannot be empty");
        return null;
      }

      // Check if document exists before updating
      final docExists = await firestore.collection('users').doc(uid).get();
      if (!docExists.exists) {
        print("Error: User document does not exist for UID: $uid");
        return null;
      }

      // If username is being changed, check availability
      final currentData = UserModel.fromFirestore(docExists);
      if (currentData.userName != data.userName) {
        final isAvailable = await isUsernameAvailable(data.userName);
        if (!isAvailable) {
          throw Exception('Username "${data.userName}" is already taken');
        }
      }

      await firestore.collection('users').doc(uid).update(data.toFirestore());

      final updatedDoc = await firestore.collection('users').doc(uid).get();
      if (updatedDoc.exists) {
        print("✅ User data updated successfully for UID: $uid");
        return UserModel.fromFirestore(updatedDoc);
      }
      return null;
    } on Exception catch (e) {
      print("Error in updating user data: $e");
      throw Exception('Failed to update user: $e');
    }
  }

  // Update specific user fields
  Future<UserModel?> updateUserFields(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    try {
      if (uid.isEmpty) {
        print("Error: UID cannot be empty");
        return null;
      }

      if (updates.isEmpty) {
        print("Error: No fields to update");
        return getUserData(uid);
      }

      // Check if document exists
      final docExists = await firestore.collection('users').doc(uid).get();
      if (!docExists.exists) {
        print("Error: User document does not exist for UID: $uid");
        return null;
      }

      // If username is being updated, check availability
      if (updates.containsKey('userName')) {
        final currentData = UserModel.fromFirestore(docExists);
        if (currentData.userName != updates['userName']) {
          final isAvailable = await isUsernameAvailable(updates['userName']);
          if (!isAvailable) {
            throw Exception(
              'Username "${updates['userName']}" is already taken',
            );
          }
        }
      }

      await firestore.collection('users').doc(uid).update(updates);

      final updatedDoc = await firestore.collection('users').doc(uid).get();
      if (updatedDoc.exists) {
        print("✅ User fields updated successfully for UID: $uid");
        return UserModel.fromFirestore(updatedDoc);
      }
      return null;
    } catch (e) {
      print("Error updating user fields: $e");
      throw Exception('Failed to update user fields: $e');
    }
  }

  // Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      if (username.isEmpty) {
        print("Error: Username cannot be empty");
        return null;
      }

      final query = await firestore
          .collection('users')
          .where('userName', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return UserModel.fromFirestore(query.docs.first);
      }

      print("User not found with username: $username");
      return null;
    } catch (e) {
      print("Error getting user by username: $e");
      return null;
    }
  }

  // Check if user document exists
  Future<bool> userExists(String uid) async {
    try {
      if (uid.isEmpty) return false;

      final doc = await firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print("Error checking if user exists: $e");
      return false;
    }
  }

  // Search users by name or username
  Future<List<UserModel>> searchUsers(String searchTerm) async {
    try {
      if (searchTerm.isEmpty || searchTerm.length < 2) {
        return [];
      }

      final String searchLower = searchTerm.toLowerCase();
      final List<UserModel> users = [];
      final Set<String> addedUIDs = <String>{};

      // Search by username
      final usernameQuery = await firestore
          .collection('users')
          .where('userName', isGreaterThanOrEqualTo: searchLower)
          .where('userName', isLessThanOrEqualTo: '$searchLower\uf8ff')
          .limit(10)
          .get();

      for (final doc in usernameQuery.docs) {
        final user = UserModel.fromFirestore(doc);
        if (!addedUIDs.contains(user.uid)) {
          users.add(user);
          addedUIDs.add(user.uid);
        }
      }

      // Search by first name
      final firstNameQuery = await firestore
          .collection('users')
          .where('firstname', isGreaterThanOrEqualTo: searchTerm)
          .where('firstname', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .limit(10)
          .get();

      for (final doc in firstNameQuery.docs) {
        final user = UserModel.fromFirestore(doc);
        if (!addedUIDs.contains(user.uid)) {
          users.add(user);
          addedUIDs.add(user.uid);
        }
      }

      // Search by last name
      final lastNameQuery = await firestore
          .collection('users')
          .where('lastname', isGreaterThanOrEqualTo: searchTerm)
          .where('lastname', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .limit(10)
          .get();

      for (final doc in lastNameQuery.docs) {
        final user = UserModel.fromFirestore(doc);
        if (!addedUIDs.contains(user.uid)) {
          users.add(user);
          addedUIDs.add(user.uid);
        }
      }

      return users;
    } catch (e) {
      print("Error searching users: $e");
      return [];
    }
  }

  // Get users by content type
  Future<List<UserModel>> getUsersByContentType(
    String contentType, {
    int limit = 20,
  }) async {
    try {
      final query = await firestore
          .collection('users')
          .where('type', arrayContains: contentType)
          .limit(limit)
          .get();

      final List<UserModel> users = [];
      for (final doc in query.docs) {
        users.add(UserModel.fromFirestore(doc));
      }

      return users;
    } catch (e) {
      print("Error getting users by content type: $e");
      return [];
    }
  }

  // Stream user data changes
  Stream<UserModel?> getUserDataStream(String uid) {
    if (uid.isEmpty) {
      return Stream.value(null);
    }

    return firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromFirestore(snapshot);
      }
      return null;
    });
  }

  // Delete the user
  Future<void> deleteUser(String uid) async {
    try {
      if (uid.isEmpty) {
        throw Exception("UID cannot be empty");
      }

      // Check if user document exists
      final docExists = await firestore.collection('users').doc(uid).get();
      if (!docExists.exists) {
        print("Warning: User document does not exist for UID: $uid");
      } else {
        // Remove the user data from Firestore
        await firestore.collection('users').doc(uid).delete();
        print("✅ User document deleted successfully for UID: $uid");
      }

      // Remove the user account from Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == uid) {
        await user.delete();
        print("✅ Firebase Auth user deleted successfully");
      } else {
        print("Warning: Current user UID doesn't match the UID to delete");
      }
    } on FirebaseAuthException catch (e) {
      print("Auth error deleting user: ${e.message}");
      throw Exception('Failed to delete user account: ${e.message}');
    } catch (e) {
      print("Error deleting user: $e");
      throw Exception('Failed to delete user: $e');
    }
  }

  // Batch operations for better performance
  Future<List<UserModel>> getUsersByIds(List<String> uids) async {
    try {
      if (uids.isEmpty) return [];

      final List<UserModel> users = [];
      const int batchSize = 10; // Firestore 'in' query limit

      for (int i = 0; i < uids.length; i += batchSize) {
        final batch = uids.skip(i).take(batchSize).toList();

        final query = await firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in query.docs) {
          if (doc.exists) {
            users.add(UserModel.fromFirestore(doc));
          }
        }
      }

      return users;
    } catch (e) {
      print("Error getting users by IDs: $e");
      return [];
    }
  }
}
