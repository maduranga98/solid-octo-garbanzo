import 'package:cloud_firestore/cloud_firestore.dart';

/// Badge model for gamified achievements
class Badge {
  final String id;
  final String name;
  final String description;
  final String icon; // emoji
  final String category; // 'achievement', 'recognition', 'special'
  final DateTime earnedAt;
  final bool isPrimary; // displayed on profile picture

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.earnedAt,
    this.isPrimary = false,
  });

  /// Create Badge from Firestore document
  factory Badge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Badge(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '🏆',
      category: data['category'] ?? 'achievement',
      earnedAt: data['earnedAt'] != null
          ? (data['earnedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isPrimary: data['isPrimary'] ?? false,
    );
  }

  /// Create Badge from Map
  factory Badge.fromMap(Map<String, dynamic> data, String id) {
    return Badge(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '🏆',
      category: data['category'] ?? 'achievement',
      earnedAt: data['earnedAt'] != null
          ? (data['earnedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isPrimary: data['isPrimary'] ?? false,
    );
  }

  /// Convert Badge to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category,
      'earnedAt': Timestamp.fromDate(earnedAt),
      'isPrimary': isPrimary,
    };
  }

  /// Get badge color based on category
  String get colorHex {
    switch (category) {
      case 'achievement':
        return '#00D4E8'; // Turquoise
      case 'recognition':
        return '#FFB800'; // Gold
      case 'special':
        return '#9B59B6'; // Purple
      default:
        return '#00D4E8'; // Default to turquoise
    }
  }

  /// Check if badge should have animation (special badges only)
  bool get shouldAnimate => category == 'special';

  /// Create a copy with updated fields
  Badge copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? category,
    DateTime? earnedAt,
    bool? isPrimary,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      earnedAt: earnedAt ?? this.earnedAt,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  String toString() {
    return 'Badge(id: $id, name: $name, category: $category, isPrimary: $isPrimary)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Badge &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.icon == icon &&
        other.category == category &&
        other.earnedAt == earnedAt &&
        other.isPrimary == isPrimary;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        icon.hashCode ^
        category.hashCode ^
        earnedAt.hashCode ^
        isPrimary.hashCode;
  }
}

/// Badge configuration (stored in badges_config collection)
class BadgeConfig {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final Map<String, dynamic> criteria;

  BadgeConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.criteria,
  });

  factory BadgeConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BadgeConfig(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '🏆',
      category: data['category'] ?? 'achievement',
      criteria: data['criteria'] ?? {},
    );
  }

  factory BadgeConfig.fromMap(Map<String, dynamic> data, String id) {
    return BadgeConfig(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '🏆',
      category: data['category'] ?? 'achievement',
      criteria: data['criteria'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category,
      'criteria': criteria,
    };
  }
}
