import 'package:cloud_firestore/cloud_firestore.dart';

/// One-time script to initialize badge configurations in Firestore
/// Run this from an admin panel or debug screen
class BadgeInitializer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize all badge configurations
  static Future<void> initializeBadges() async {
    try {
      print('🚀 Starting badge initialization...');

      final badges = _getBadgeConfigurations();
      final batch = _firestore.batch();

      for (var badge in badges) {
        final docRef = _firestore.collection('badges_config').doc(badge['id']);
        batch.set(docRef, badge);
      }

      await batch.commit();

      print('✅ Badge initialization completed: ${badges.length} badges created');
    } catch (e) {
      print('❌ Error initializing badges: $e');
      rethrow;
    }
  }

  /// Get all badge configurations
  static List<Map<String, dynamic>> _getBadgeConfigurations() {
    return [
      // ========== ACHIEVEMENT BADGES ==========
      {
        'id': 'pioneer',
        'name': 'Pioneer',
        'description': 'First 100 members to join VerseWing',
        'icon': '🌟',
        'category': 'achievement',
        'criteria': {
          'type': 'earlyMember',
          'limit': 100,
        },
      },
      {
        'id': 'first_words',
        'name': 'First Words',
        'description': 'Published your first post',
        'icon': '✍️',
        'category': 'achievement',
        'criteria': {
          'type': 'firstPost',
        },
      },
      {
        'id': 'fresh_ink',
        'name': 'Fresh Ink',
        'description': 'Welcome to VerseWing, fresher!',
        'icon': '🆕',
        'category': 'achievement',
        'criteria': {
          'type': 'fresher',
        },
      },
      {
        'id': 'prolific_writer',
        'name': 'Prolific Writer',
        'description': 'Published 50+ posts',
        'icon': '📚',
        'category': 'achievement',
        'criteria': {
          'type': 'postCount',
          'threshold': 50,
        },
      },
      {
        'id': 'engaged_reader',
        'name': 'Engaged Reader',
        'description': 'Left 100+ comments',
        'icon': '💬',
        'category': 'achievement',
        'criteria': {
          'type': 'commentCount',
          'threshold': 100,
        },
      },

      // ========== RECOGNITION BADGES ==========
      {
        'id': 'rising_star',
        'name': 'Rising Star',
        'description': 'Gained 1000+ likes within first month',
        'icon': '⭐',
        'category': 'recognition',
        'criteria': {
          'type': 'likesInFirstMonth',
          'threshold': 1000,
          'days': 30,
        },
      },
      {
        'id': 'community_favorite',
        'name': 'Community Favorite',
        'description': 'Your post reached top 10 trending',
        'icon': '❤️',
        'category': 'recognition',
        'criteria': {
          'type': 'trendingPost',
          'rank': 10,
        },
      },
      {
        'id': 'consistent_creator',
        'name': 'Consistent Creator',
        'description': 'Posted for 30 consecutive days',
        'icon': '🔥',
        'category': 'recognition',
        'criteria': {
          'type': 'consecutiveDays',
          'days': 30,
        },
      },

      // ========== SPECIAL BADGES ==========
      {
        'id': 'versewing_team',
        'name': 'VerseWing Team',
        'description': 'Official VerseWing team member',
        'icon': '👑',
        'category': 'special',
        'criteria': {
          'type': 'manual',
          'adminOnly': true,
        },
      },
    ];
  }

  /// Check if badges are already initialized
  static Future<bool> areBadgesInitialized() async {
    try {
      final snapshot = await _firestore.collection('badges_config').limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking badge initialization: $e');
      return false;
    }
  }

  /// Delete all badge configurations (use with caution!)
  static Future<void> clearBadgeConfigurations() async {
    try {
      print('⚠️ Clearing all badge configurations...');

      final snapshot = await _firestore.collection('badges_config').get();
      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      print('✅ Badge configurations cleared');
    } catch (e) {
      print('❌ Error clearing badges: $e');
      rethrow;
    }
  }

  /// Re-initialize badges (clear and initialize)
  static Future<void> reinitializeBadges() async {
    await clearBadgeConfigurations();
    await initializeBadges();
  }
}
