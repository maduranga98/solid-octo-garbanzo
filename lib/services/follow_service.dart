// lib/services/follow_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FollowService {
  final FirebaseFirestore _firestore;

  FollowService(this._firestore);

  // Toggle follow/unfollow
  Future<void> toggleFollow(String currentUserId, String targetUserId) async {
    final followRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId);

    final followerRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId);

    final currentUserRef = _firestore.collection('users').doc(currentUserId);
    final targetUserRef = _firestore.collection('users').doc(targetUserId);

    final followDoc = await followRef.get();

    // Use batch write for atomic operations
    final batch = _firestore.batch();

    if (followDoc.exists) {
      // Unfollow - decrement counts
      batch.delete(followRef);
      batch.delete(followerRef);

      // Decrement following count for current user
      batch.update(currentUserRef, {
        'followingCount': FieldValue.increment(-1),
      });

      // Decrement followers count for target user
      batch.update(targetUserRef, {'followersCount': FieldValue.increment(-1)});
    } else {
      // Follow - increment counts
      batch.set(followRef, {'followedAt': FieldValue.serverTimestamp()});
      batch.set(followerRef, {'followedAt': FieldValue.serverTimestamp()});

      // Increment following count for current user
      batch.update(currentUserRef, {'followingCount': FieldValue.increment(1)});

      // Increment followers count for target user
      batch.update(targetUserRef, {'followersCount': FieldValue.increment(1)});
    }

    // Commit all changes atomically
    await batch.commit();
  }

  // Check if user is following another user
  Stream<bool> isFollowing(String currentUserId, String targetUserId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .snapshots()
        .map((snapshot) => snapshot.exists)
        .handleError((error) {
          print('Error checking follow status: $error');
          return false;
        });
  }

  // Get follower count
  Stream<int> getFollowerCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get following count
  Stream<int> getFollowingCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get posts from followed users
  Stream<List<String>> getFollowingUserIds(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }
}
