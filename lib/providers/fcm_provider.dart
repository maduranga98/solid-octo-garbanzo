import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/services/fcm_service.dart';

/// Provider for FCM Service instance
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

/// Provider to get FCM token
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final fcmService = ref.watch(fcmServiceProvider);
  return await fcmService.getToken();
});
