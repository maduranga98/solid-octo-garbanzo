// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/models/notification_model.dart';
import 'package:poem_application/providers/auth_provider.dart';
import 'package:poem_application/providers/notification_provider.dart';
import 'package:poem_application/screens/profile/user_profile.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = ref.watch(firebaseAuthProvider).currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please sign in to view notifications')),
      );
    }

    final notificationsAsync = ref.watch(
      notificationsProvider(currentUser.uid),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: colorScheme.onSurface),
            onPressed: () => _markAllAsRead(currentUser.uid),
            tooltip: 'Mark all as read',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            onSelected: (value) {
              if (value == 'clear_all') {
                _clearAllNotifications(currentUser.uid);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 12),
                    Text('Clear all'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider(currentUser.uid));
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(
                  notification,
                  currentUser.uid,
                  colorScheme,
                  theme,
                );
              },
            ),
          );
        },
        loading: () => _buildLoadingState(colorScheme),
        error: (error, stack) => _buildErrorState(error, colorScheme, theme),
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    String currentUserId,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Dismissible(
      key: Key(notification.id ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(currentUserId, notification.id!);
      },
      child: InkWell(
        onTap: () => _handleNotificationTap(notification, currentUserId),
        child: Container(
          color: notification.isRead
              ? Colors.transparent
              : colorScheme.primaryContainer.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage:
                    notification.senderPhotoUrl != null &&
                        notification.senderPhotoUrl!.isNotEmpty
                    ? NetworkImage(notification.senderPhotoUrl!)
                    : null,
                child:
                    notification.senderPhotoUrl == null ||
                        notification.senderPhotoUrl!.isEmpty
                    ? Icon(
                        Icons.person,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              children: [
                                TextSpan(
                                  text: notification.senderName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: _getActionText(notification.type),
                                ),
                                if (notification.postTitle != null)
                                  TextSpan(
                                    text: ' "${notification.postTitle}"',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // Unread indicator
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Comment preview if available
                    if (notification.commentText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: Text(
                          notification.commentText!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Time
                    Text(
                      timeago.format(notification.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Notification icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getNotificationColor(
                    notification.type,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  size: 20,
                  color: _getNotificationColor(notification.type),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getActionText(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return ' liked your post';
      case NotificationType.comment:
        return ' commented on your post';
      case NotificationType.reply:
        return ' replied to your comment';
      case NotificationType.follow:
        return ' started following you';
      case NotificationType.mention:
        return ' mentioned you in a post';
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.comment;
      case NotificationType.reply:
        return Icons.reply;
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.mention:
        return Icons.alternate_email;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Colors.red;
      case NotificationType.comment:
        return Colors.blue;
      case NotificationType.reply:
        return Colors.green;
      case NotificationType.follow:
        return Colors.purple;
      case NotificationType.mention:
        return Colors.orange;
    }
  }

  void _handleNotificationTap(
    NotificationModel notification,
    String currentUserId,
  ) {
    // Mark as read
    if (!notification.isRead) {
      final service = ref.read(notificationServiceProvider);
      service.markAsRead(currentUserId, notification.id!);
    }

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.like:
      case NotificationType.comment:
      case NotificationType.reply:
        // Navigate to post (you'll need to implement this)
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => PostDetailScreen(postId: notification.postId!),
        //   ),
        // );
        break;
      case NotificationType.follow:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfile(userId: notification.senderId),
          ),
        );
        break;
      case NotificationType.mention:
        // Navigate to mentioned post
        break;
    }
  }

  void _markAllAsRead(String userId) {
    final service = ref.read(notificationServiceProvider);
    service.markAllAsRead(userId);
  }

  void _deleteNotification(String userId, String notificationId) {
    final service = ref.read(notificationServiceProvider);
    service.deleteNotification(userId, notificationId);
  }

  void _clearAllNotifications(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final service = ref.read(notificationServiceProvider);
              service.deleteAllNotifications(userId);
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When people interact with your posts, you\'ll see it here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.surfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(
    Object error,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
