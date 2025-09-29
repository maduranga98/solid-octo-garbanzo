// lib/providers/follow_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/services/follow_service.dart';

final followServiceProvider = Provider<FollowService>((ref) {
  return FollowService(FirebaseFirestore.instance);
});

// Add autoDispose to clean up streams when not needed
final isFollowingProvider = StreamProvider.autoDispose
    .family<bool, FollowParams>((ref, params) {
      final service = ref.watch(followServiceProvider);
      return service.isFollowing(params.currentUserId, params.targetUserId);
    });

final followerCountProvider = StreamProvider.autoDispose.family<int, String>((
  ref,
  userId,
) {
  final service = ref.watch(followServiceProvider);
  return service.getFollowerCount(userId);
});

final followingCountProvider = StreamProvider.autoDispose.family<int, String>((
  ref,
  userId,
) {
  final service = ref.watch(followServiceProvider);
  return service.getFollowingCount(userId);
});

final followingUserIdsProvider = StreamProvider.family<List<String>, String>((
  ref,
  userId,
) {
  final service = ref.watch(followServiceProvider);
  return service.getFollowingUserIds(userId);
});

class FollowParams {
  final String currentUserId;
  final String targetUserId;

  FollowParams({required this.currentUserId, required this.targetUserId});

  // Add these to ensure proper caching
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowParams &&
          runtimeType == other.runtimeType &&
          currentUserId == other.currentUserId &&
          targetUserId == other.targetUserId;

  @override
  int get hashCode => currentUserId.hashCode ^ targetUserId.hashCode;
}
