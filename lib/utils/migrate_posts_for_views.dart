import 'package:cloud_firestore/cloud_firestore.dart';

/// Migration script to add view tracking fields to existing posts
/// Run this once from admin panel or debug screen
class PostViewMigration {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add view fields to all existing posts
  static Future<void> addViewFieldsToExistingPosts() async {
    try {
      print('🚀 Starting post view migration...');

      // Get all posts
      final postsSnapshot = await _firestore.collection('posts').get();
      final totalPosts = postsSnapshot.docs.length;

      print('Found $totalPosts posts to migrate');

      int updatedCount = 0;
      int skippedCount = 0;
      int batchCount = 0;

      WriteBatch batch = _firestore.batch();

      for (var doc in postsSnapshot.docs) {
        final data = doc.data();

        // Only update if fields don't exist
        if (!data.containsKey('viewCount') ||
            !data.containsKey('uniqueReaders')) {
          batch.update(doc.reference, {
            'viewCount': 0,
            'uniqueReaders': 0,
            'lastViewedAt': null,
          });

          updatedCount++;
          batchCount++;

          // Firestore batch limit is 500 operations
          if (batchCount >= 500) {
            await batch.commit();
            print('✅ Committed batch: $updatedCount posts updated so far');
            batch = _firestore.batch();
            batchCount = 0;
          }
        } else {
          skippedCount++;
        }
      }

      // Commit remaining batch
      if (batchCount > 0) {
        await batch.commit();
      }

      print('✅ Migration completed!');
      print('   - Total posts: $totalPosts');
      print('   - Updated: $updatedCount');
      print('   - Skipped: $skippedCount');
    } catch (e) {
      print('❌ Error during migration: $e');
      rethrow;
    }
  }

  /// Add view fields to specific post (useful for testing)
  static Future<void> addViewFieldsToPost(String postId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final postDoc = await postRef.get();

      if (!postDoc.exists) {
        print('Post $postId not found');
        return;
      }

      await postRef.update({
        'viewCount': 0,
        'uniqueReaders': 0,
        'lastViewedAt': null,
      });

      print('✅ View fields added to post $postId');
    } catch (e) {
      print('❌ Error adding view fields to post: $e');
      rethrow;
    }
  }

  /// Check migration status
  static Future<MigrationStatus> checkMigrationStatus() async {
    try {
      final postsSnapshot = await _firestore.collection('posts').get();
      final totalPosts = postsSnapshot.docs.length;

      int migratedCount = 0;
      int pendingCount = 0;

      for (var doc in postsSnapshot.docs) {
        final data = doc.data();

        if (data.containsKey('viewCount') &&
            data.containsKey('uniqueReaders')) {
          migratedCount++;
        } else {
          pendingCount++;
        }
      }

      return MigrationStatus(
        totalPosts: totalPosts,
        migratedPosts: migratedCount,
        pendingPosts: pendingCount,
        isComplete: pendingCount == 0,
      );
    } catch (e) {
      print('Error checking migration status: $e');
      return MigrationStatus(
        totalPosts: 0,
        migratedPosts: 0,
        pendingPosts: 0,
        isComplete: false,
      );
    }
  }

  /// Rollback migration (remove view fields)
  static Future<void> rollbackMigration() async {
    try {
      print('⚠️ Rolling back view migration...');

      final postsSnapshot = await _firestore.collection('posts').get();
      int count = 0;
      int batchCount = 0;

      WriteBatch batch = _firestore.batch();

      for (var doc in postsSnapshot.docs) {
        final data = doc.data();

        if (data.containsKey('viewCount') ||
            data.containsKey('uniqueReaders')) {
          batch.update(doc.reference, {
            'viewCount': FieldValue.delete(),
            'uniqueReaders': FieldValue.delete(),
            'lastViewedAt': FieldValue.delete(),
          });

          count++;
          batchCount++;

          if (batchCount >= 500) {
            await batch.commit();
            print('Rolled back $count posts so far');
            batch = _firestore.batch();
            batchCount = 0;
          }
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      print('✅ Rollback completed: $count posts');
    } catch (e) {
      print('❌ Error during rollback: $e');
      rethrow;
    }
  }
}

/// Migration status
class MigrationStatus {
  final int totalPosts;
  final int migratedPosts;
  final int pendingPosts;
  final bool isComplete;

  MigrationStatus({
    required this.totalPosts,
    required this.migratedPosts,
    required this.pendingPosts,
    required this.isComplete,
  });

  double get progress {
    if (totalPosts == 0) return 0;
    return migratedPosts / totalPosts;
  }

  @override
  String toString() {
    return 'MigrationStatus(total: $totalPosts, migrated: $migratedPosts, pending: $pendingPosts, complete: $isComplete)';
  }
}
