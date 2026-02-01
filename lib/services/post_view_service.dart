import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/crashlytics_helper.dart';

/// Service for tracking post views with spam prevention
class PostViewService {
  static const int COOLDOWN_HOURS = 6; // Configurable: 6-24 hours

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Track a post view (main method)
  Future<void> trackPostView(String postId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('User not authenticated, skipping view tracking');
        return;
      }

      // Check if view should be counted (based on cooldown)
      if (await _shouldCountView(postId, userId)) {
        await _recordView(postId, userId);
        print('✅ View counted for post $postId by user $userId');
      } else {
        print('⏱️ View not counted (cooldown active) for post $postId');
      }
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Failed to track view for post $postId',
      );
      print('Error tracking view: $e');
    }
  }

  /// Check if view should be counted (local cache check)
  Future<bool> _shouldCountView(String postId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'last_view_${postId}_$userId';
      final lastViewTimestamp = prefs.getInt(cacheKey);

      if (lastViewTimestamp == null) {
        // First view or cache cleared
        return true;
      }

      final lastViewTime =
          DateTime.fromMillisecondsSinceEpoch(lastViewTimestamp);
      final hoursSinceLastView =
          DateTime.now().difference(lastViewTime).inHours;

      return hoursSinceLastView >= COOLDOWN_HOURS;
    } catch (e) {
      print('Error checking cooldown: $e');
      // If there's an error, default to allowing the view
      return true;
    }
  }

  /// Record view in Firestore (atomic batch operation)
  Future<void> _recordView(String postId, String userId) async {
    try {
      final now = DateTime.now();
      final batch = _firestore.batch();

      // Reference to user's view document
      final viewDocRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('post_views')
          .doc(userId);

      // Reference to post document
      final postRef = _firestore.collection('posts').doc(postId);

      // Check if this is user's first view
      final viewDoc = await viewDocRef.get();

      if (!viewDoc.exists) {
        // First view by this user
        batch.set(viewDocRef, {
          'userId': userId,
          'firstViewedAt': FieldValue.serverTimestamp(),
          'lastViewedAt': FieldValue.serverTimestamp(),
          'viewCount': 1,
        });

        // Increment both viewCount and uniqueReaders
        batch.update(postRef, {
          'viewCount': FieldValue.increment(1),
          'uniqueReaders': FieldValue.increment(1),
          'lastViewedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Subsequent view (cooldown passed)
        batch.update(viewDocRef, {
          'lastViewedAt': FieldValue.serverTimestamp(),
          'viewCount': FieldValue.increment(1),
        });

        // Increment only viewCount (not uniqueReaders)
        batch.update(postRef, {
          'viewCount': FieldValue.increment(1),
          'lastViewedAt': FieldValue.serverTimestamp(),
        });
      }

      // Commit batch
      await batch.commit();

      // Cache locally to avoid unnecessary Firestore reads
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'last_view_${postId}_$userId';
      await prefs.setInt(cacheKey, now.millisecondsSinceEpoch);

      print('✅ View recorded for post $postId');
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Failed to record view for post $postId',
      );
      print('Error recording view: $e');
      rethrow;
    }
  }

  /// Get view statistics for a post
  Future<ViewStats> getViewStats(String postId) async {
    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();

      if (!postDoc.exists) {
        return ViewStats(
          totalViews: 0,
          uniqueReaders: 0,
          lastViewedAt: null,
        );
      }

      final data = postDoc.data()!;

      return ViewStats(
        totalViews: data['viewCount'] ?? 0,
        uniqueReaders: data['uniqueReaders'] ?? 0,
        lastViewedAt: data['lastViewedAt'] != null
            ? (data['lastViewedAt'] as Timestamp).toDate()
            : null,
      );
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Failed to get view stats for post $postId',
      );
      return ViewStats(
        totalViews: 0,
        uniqueReaders: 0,
        lastViewedAt: null,
      );
    }
  }

  /// Get user's view statistics for a post
  Future<UserViewStats?> getUserViewStats(String postId, String userId) async {
    try {
      final viewDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('post_views')
          .doc(userId)
          .get();

      if (!viewDoc.exists) {
        return null;
      }

      final data = viewDoc.data()!;

      return UserViewStats(
        viewCount: data['viewCount'] ?? 0,
        firstViewedAt: data['firstViewedAt'] != null
            ? (data['firstViewedAt'] as Timestamp).toDate()
            : DateTime.now(),
        lastViewedAt: data['lastViewedAt'] != null
            ? (data['lastViewedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Failed to get user view stats for post $postId',
      );
      return null;
    }
  }

  /// Get all viewers for a post (admin/analytics)
  Future<List<String>> getPostViewers(String postId, {int? limit}) async {
    try {
      var query = _firestore
          .collection('posts')
          .doc(postId)
          .collection('post_views')
          .orderBy('lastViewedAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting post viewers: $e');
      return [];
    }
  }

  /// Clear local view cache (for testing or logout)
  Future<void> clearViewCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (var key in keys) {
        if (key.startsWith('last_view_')) {
          await prefs.remove(key);
        }
      }

      print('✅ View cache cleared');
    } catch (e) {
      print('Error clearing view cache: $e');
    }
  }

  /// Get trending posts (recent + high engagement)
  Future<List<Map<String, dynamic>>> getTrendingPosts({
    int days = 7,
    int limit = 20,
  }) async {
    try {
      final weekAgo = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('posts')
          .where('lastViewedAt', isGreaterThan: weekAgo)
          .orderBy('lastViewedAt', descending: true)
          .orderBy('viewCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Failed to get trending posts',
      );
      return [];
    }
  }

  /// Get top viewed posts
  Future<List<Map<String, dynamic>>> getTopViewedPosts({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('viewCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();
    } catch (e, stackTrace) {
      await CrashlyticsHelper.recordError(
        e,
        stackTrace,
        reason: 'Failed to get top viewed posts',
      );
      return [];
    }
  }
}

/// View statistics for a post
class ViewStats {
  final int totalViews;
  final int uniqueReaders;
  final DateTime? lastViewedAt;

  ViewStats({
    required this.totalViews,
    required this.uniqueReaders,
    this.lastViewedAt,
  });

  @override
  String toString() {
    return 'ViewStats(totalViews: $totalViews, uniqueReaders: $uniqueReaders)';
  }
}

/// User's view statistics for a post
class UserViewStats {
  final int viewCount;
  final DateTime firstViewedAt;
  final DateTime lastViewedAt;

  UserViewStats({
    required this.viewCount,
    required this.firstViewedAt,
    required this.lastViewedAt,
  });

  @override
  String toString() {
    return 'UserViewStats(viewCount: $viewCount, first: $firstViewedAt, last: $lastViewedAt)';
  }
}
