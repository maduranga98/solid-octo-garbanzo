import 'package:flutter/material.dart' hide Badge;
import 'package:intl/intl.dart';
import '../models/badge_model.dart';
import '../services/badge_service.dart';

/// Modal dialog showing badge details
class BadgeDetailModal extends StatefulWidget {
  final Badge badge;
  final String userId;
  final bool showSetPrimaryButton;

  const BadgeDetailModal({
    Key? key,
    required this.badge,
    required this.userId,
    this.showSetPrimaryButton = true,
  }) : super(key: key);

  @override
  State<BadgeDetailModal> createState() => _BadgeDetailModalState();
}

class _BadgeDetailModalState extends State<BadgeDetailModal> {
  final BadgeService _badgeService = BadgeService();
  bool _isSettingPrimary = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                iconSize: 20,
              ),
            ),

            const SizedBox(height: 8),

            // Badge icon (large)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: _getBadgeColor(widget.badge.category),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getBadgeColor(
                      widget.badge.category,
                    ).withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.badge.icon,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Badge name
            Text(
              widget.badge.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Badge category chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getBadgeColor(widget.badge.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getCategoryLabel(widget.badge.category),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getBadgeColor(widget.badge.category),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              widget.badge.description,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Earned date
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  'Earned ${DateFormat.yMMMd().format(widget.badge.earnedAt)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Set as primary button
            if (widget.showSetPrimaryButton && !widget.badge.isPrimary)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSettingPrimary ? null : _setPrimaryBadge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4E8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSettingPrimary
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Set as Primary Badge',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

            // Already primary indicator
            if (widget.badge.isPrimary)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4E8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00D4E8), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF00D4E8),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Primary Badge',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00D4E8),
                      ),
                    ),
                  ],
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

  /// Get category label
  String _getCategoryLabel(String category) {
    switch (category) {
      case 'achievement':
        return 'Achievement';
      case 'recognition':
        return 'Recognition';
      case 'special':
        return 'Special';
      default:
        return category.toUpperCase();
    }
  }

  /// Set badge as primary
  Future<void> _setPrimaryBadge() async {
    setState(() => _isSettingPrimary = true);

    try {
      await _badgeService.setPrimaryBadge(widget.userId, widget.badge.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.badge.name} set as primary badge'),
            backgroundColor: const Color(0xFF00D4E8),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to set primary badge'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSettingPrimary = false);
      }
    }
  }
}
