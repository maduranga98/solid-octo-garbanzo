// lib/providers/notification_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/models/notification_model.dart';
import 'package:poem_application/services/notification_service.dart';

// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Provider to get notifications stream for a user
final notificationsProvider =
    StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
      final service = ref.watch(notificationServiceProvider);
      return service.getNotificationsStream(userId);
    });

// Provider to get unread notification count
final unreadNotificationCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  final service = ref.watch(notificationServiceProvider);
  return service.getUnreadCountStream(userId);
});
