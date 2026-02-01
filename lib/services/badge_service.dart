import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/badge_model.dart';
import '../utils/crashlytics_helper.dart';

/// Service for managing user badges
class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Award a badge to a user
  /// Returns true if badge was awarded, false if user already has it
  Future<bool> awardBadge(String userId, String badgeId) async {
    try {
      // Check if user already has this badge (prevent duplicates)
      final existingBadge = await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .doc(badgeId)
          .get();

      if (existingBadge.exists) {
        print('User $userId already has badge $badgeId');
        return false;
      }

      // Get badge configuration
      final badgeConfigDoc =
          await _firestore.collection('badges_config').doc(badgeId).get();

      if (!badgeConfigDoc.exists) {
        print('Badge config not found for $badgeId');
        return false;
      }

      final badgeConfig = BadgeConfig.fromFirestore(badgeConfigDoc);

      // Create badge document in user's badges subcollection
      final batch = _firestore.batch();

      final badgeRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .doc(badgeId);

      final badge = Badge(
        id: badgeId,
        name: badgeConfig.name,
        description: badgeConfig.description,
        icon: badgeConfig.icon,
        category: badgeConfig.category,
        earnedAt: DateTime.now(),
        isPrimary: false, // User can set this later
      );

      batch.set(badgeRef, badge.toFirestore());

      // Increment user's badge count
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'badgeCount': FieldValue.increment(1),
      });

      await batch.commit();

      print('✅ Awarded badge $badgeId to user $userId');
      return true;
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Failed to award badge $badgeId to user $userId',
      );
      print('Error awarding badge: $e');
      return false;
    }
  }

  /// Get all badges for a user (as a stream)
  Stream<List<Badge>> getUserBadges(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('badges')
        .orderBy('earnedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Badge.fromFirestore(doc)).toList();
    });
  }

  /// Get all badges for a user (one-time fetch)
  Future<List<Badge>> getUserBadgesOnce(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .orderBy('earnedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Badge.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Failed to get badges for user $userId',
      );
      return [];
    }
  }

  /// Get primary badge for display on profile picture
  Future<Badge?> getPrimaryBadge(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .where('isPrimary', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // If no primary badge set, return the most recent badge
        final recentBadges = await _firestore
            .collection('users')
            .doc(userId)
            .collection('badges')
            .orderBy('earnedAt', descending: true)
            .limit(1)
            .get();

        if (recentBadges.docs.isNotEmpty) {
          return Badge.fromFirestore(recentBadges.docs.first);
        }
        return null;
      }

      return Badge.fromFirestore(snapshot.docs.first);
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Failed to get primary badge for user $userId',
      );
      return null;
    }
  }

  /// Set a badge as primary (unset others)
  Future<void> setPrimaryBadge(String userId, String badgeId) async {
    try {
      final batch = _firestore.batch();

      // Get all user badges
      final allBadges = await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .get();

      // Unset all badges as primary
      for (var doc in allBadges.docs) {
        batch.update(doc.reference, {'isPrimary': false});
      }

      // Set the selected badge as primary
      final badgeRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .doc(badgeId);

      batch.update(badgeRef, {'isPrimary': true});

      await batch.commit();
      print('✅ Set badge $badgeId as primary for user $userId');
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Failed to set primary badge $badgeId for user $userId',
      );
      print('Error setting primary badge: $e');
    }
  }

  /// Check if user has a specific badge
  Future<bool> hasBadge(String userId, String badgeId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .doc(badgeId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking badge: $e');
      return false;
    }
  }

  /// Get top N badges for a user (for display below profile picture)
  Future<List<Badge>> getTopBadges(String userId, {int limit = 3}) async {
    try {
      // Prioritize: 1. Primary badge, 2. Special badges, 3. Most recent
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .orderBy('isPrimary', descending: true)
          .orderBy('earnedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Badge.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Failed to get top badges for user $userId',
      );
      return [];
    }
  }

  /// Get all badge configurations
  Future<List<BadgeConfig>> getAllBadgeConfigs() async {
    try {
      final snapshot = await _firestore.collection('badges_config').get();
      return snapshot.docs
          .map((doc) => BadgeConfig.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Failed to get badge configs',
      );
      return [];
    }
  }

  /// Get badge count for a user
  Future<int> getBadgeCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting badge count: $e');
      return 0;
    }
  }

  /// Get current user's badges
  Stream<List<Badge>> getCurrentUserBadges() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }
    return getUserBadges(userId);
  }

  /// Award badge to current user
  Future<bool> awardBadgeToCurrentUser(String badgeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('No user logged in');
      return false;
    }
    return awardBadge(userId, badgeId);
  }
}
