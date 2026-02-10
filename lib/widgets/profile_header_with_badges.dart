import 'package:flutter/material.dart' hide Badge;
import '../models/badge_model.dart';
import '../services/badge_service.dart';
import 'profile_picture_with_badge.dart';
import 'badge_detail_modal.dart';

/// Complete profile header with profile picture, badges, and username
class ProfileHeaderWithBadges extends StatefulWidget {
  final String userId;
  final String username;
  final String? profileImageUrl;
  final int maxBadgesToShow;
  final VoidCallback? onProfilePictureTap;

  const ProfileHeaderWithBadges({
    Key? key,
    required this.userId,
    required this.username,
    this.profileImageUrl,
    this.maxBadgesToShow = 3,
    this.onProfilePictureTap,
  }) : super(key: key);

  @override
  State<ProfileHeaderWithBadges> createState() =>
      _ProfileHeaderWithBadgesState();
}

class _ProfileHeaderWithBadgesState extends State<ProfileHeaderWithBadges> {
  final BadgeService _badgeService = BadgeService();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Profile picture with primary badge
        ProfilePictureWithBadge(
          userId: widget.userId,
          profileImageUrl: widget.profileImageUrl,
          size: 100,
          showBadgeIcon: true,
          onTap: widget.onProfilePictureTap,
        ),

        const SizedBox(height: 12),

        // Top badges row
        FutureBuilder<List<Badge>>(
          future: _badgeService.getTopBadges(
            widget.userId,
            limit: widget.maxBadgesToShow,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final badges = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: badges.map((badge) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildBadgeCircle(badge),
                  );
                }).toList(),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // Username
        Text(
          widget.username,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build circular badge icon
  Widget _buildBadgeCircle(Badge badge) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(badge),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: _getBadgeColor(badge.category), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(badge.icon, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  /// Get badge color based on category
  Color _getBadgeColor(String category) {
    switch (category) {
      case 'achievement':
        return const Color(0xFF00D4E8); // Turquoise
      case 'recognition':
        return const Color(0xFFFFB800); // Gold
      case 'special':
        return const Color(0xFF9B59B6); // Purple
      default:
        return const Color(0xFF00D4E8);
    }
  }

  /// Show badge details modal
  void _showBadgeDetails(Badge badge) {
    showDialog(
      context: context,
      builder: (context) =>
          BadgeDetailModal(badge: badge, userId: widget.userId),
    );
  }
}
