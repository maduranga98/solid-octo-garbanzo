import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/models/user_model.dart';
import 'package:poem_application/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

final getUserDataProvider = FutureProvider.family<UserModel?, String>((
  ref,
  uid,
) {
  print("Provider: $uid");
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUserData(uid);
});

// Stream provider for real-time user data updates (for profile stats)
final userDataStreamProvider = StreamProvider.family<UserModel?, String>((
  ref,
  uid,
) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists) {
      return UserModel.fromFirestore(snapshot);
    }
    return null;
  });
});
