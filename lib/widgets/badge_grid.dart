import 'package:flutter/material.dart' hide Badge;
import '../models/badge_model.dart';
import '../services/badge_service.dart';
import 'badge_detail_modal.dart';

/// Grid view of all earned badges
class BadgeGrid extends StatefulWidget {
  final String userId;
  final bool showUnearned;
  final int crossAxisCount;

  const BadgeGrid({
    Key? key,
    required this.userId,
    this.showUnearned = false,
    this.crossAxisCount = 3,
  }) : super(key: key);

  @override
  State<BadgeGrid> createState() => _BadgeGridState();
}

class _BadgeGridState extends State<BadgeGrid> {
  final BadgeService _badgeService = BadgeService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Badge>>(
      stream: _badgeService.getUserBadges(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error loading badges',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }

        final badges = snapshot.data ?? [];

        if (badges.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No badges yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start creating content to earn badges!',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            return _buildBadgeCard(badges[index]);
          },
        );
      },
    );
  }

  /// Build badge card
  Widget _buildBadgeCard(Badge badge) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(badge),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: badge.isPrimary
                ? _getBadgeColor(badge.category)
                : Colors.grey.shade300,
            width: badge.isPrimary ? 3 : 1,
          ),
          boxShadow: [
            if (badge.isPrimary)
              BoxShadow(
                color: _getBadgeColor(badge.category).withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 2,
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getBadgeColor(badge.category).withOpacity(0.1),
              ),
              child: Center(
                child: Text(badge.icon, style: const TextStyle(fontSize: 24)),
              ),
            ),

            const SizedBox(height: 8),

            // Badge name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                badge.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Primary indicator
            if (badge.isPrimary)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getBadgeColor(badge.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PRIMARY',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: _getBadgeColor(badge.category),
                    ),
                  ),
                ),
              ),
          ],
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
