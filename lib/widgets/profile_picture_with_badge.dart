import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/badge_model.dart';
import '../services/badge_service.dart';
import 'badge_detail_modal.dart';

/// Profile picture with badge border and icon overlay
class ProfilePictureWithBadge extends StatefulWidget {
  final String userId;
  final String? profileImageUrl;
  final double size;
  final bool showBadgeIcon;
  final VoidCallback? onTap;

  const ProfilePictureWithBadge({
    Key? key,
    required this.userId,
    this.profileImageUrl,
    this.size = 80,
    this.showBadgeIcon = true,
    this.onTap,
  }) : super(key: key);

  @override
  State<ProfilePictureWithBadge> createState() =>
      _ProfilePictureWithBadgeState();
}

class _ProfilePictureWithBadgeState extends State<ProfilePictureWithBadge> {
  final BadgeService _badgeService = BadgeService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Badge?>(
      future: _badgeService.getPrimaryBadge(widget.userId),
      builder: (context, snapshot) {
        final badge = snapshot.data;

        return GestureDetector(
          onTap: widget.onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Profile picture with gradient border
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: badge != null
                      ? _getBadgeGradient(badge.category)
                      : null,
                  border: badge == null
                      ? Border.all(color: Colors.grey.shade300, width: 2)
                      : null,
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  child: ClipOval(
                    child: widget.profileImageUrl != null &&
                            widget.profileImageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.profileImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                _buildDefaultAvatar(),
                          )
                        : _buildDefaultAvatar(),
                  ),
                ),
              ),

              // Badge icon overlay (top-right corner)
              if (badge != null && widget.showBadgeIcon)
                Positioned(
                  top: -2,
                  right: -2,
                  child: GestureDetector(
                    onTap: () => _showBadgeDetails(context, badge),
                    child: Container(
                      width: widget.size * 0.35,
                      height: widget.size * 0.35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: _getBadgeColor(badge.category),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          badge.icon,
                          style: TextStyle(
                            fontSize: widget.size * 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Build default avatar (fallback when no profile image)
  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF00D4E8).withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: widget.size * 0.5,
        color: const Color(0xFF00D4E8),
      ),
    );
  }

  /// Get gradient for badge border
  LinearGradient _getBadgeGradient(String category) {
    final color = _getBadgeColor(category);
    return LinearGradient(
      colors: [
        color.withOpacity(0.6),
        color,
        color.withOpacity(0.6),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
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
  void _showBadgeDetails(BuildContext context, Badge badge) {
    showDialog(
      context: context,
      builder: (context) => BadgeDetailModal(
        badge: badge,
        userId: widget.userId,
      ),
    );
  }
}
