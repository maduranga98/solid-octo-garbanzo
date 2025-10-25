// lib/models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { like, comment, reply, follow, mention }

class NotificationModel {
  final String? id;
  final String recipientId; // User who receives the notification
  final String senderId; // User who performed the action
  final String senderName;
  final String? senderPhotoUrl;
  final NotificationType type;
  final String? postId;
  final String? postTitle;
  final String? commentId;
  final String? commentText;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    this.id,
    required this.recipientId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.type,
    this.postId,
    this.postTitle,
    this.commentId,
    this.commentText,
    this.isRead = false,
    required this.createdAt,
  });

  // Create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      recipientId: data['recipientId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhotoUrl: data['senderPhotoUrl'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${data['type']}',
        orElse: () => NotificationType.like,
      ),
      postId: data['postId'],
      postTitle: data['postTitle'],
      commentId: data['commentId'],
      commentText: data['commentText'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'type': type.toString().split('.').last,
      'postId': postId,
      'postTitle': postTitle,
      'commentId': commentId,
      'commentText': commentText,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Copy with method
  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    NotificationType? type,
    String? postId,
    String? postTitle,
    String? commentId,
    String? commentText,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      type: type ?? this.type,
      postId: postId ?? this.postId,
      postTitle: postTitle ?? this.postTitle,
      commentId: commentId ?? this.commentId,
      commentText: commentText ?? this.commentText,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Get notification message
  String getMessage() {
    switch (type) {
      case NotificationType.like:
        return '$senderName liked your post${postTitle != null ? ' "$postTitle"' : ''}';
      case NotificationType.comment:
        return '$senderName commented on your post${postTitle != null ? ' "$postTitle"' : ''}';
      case NotificationType.reply:
        return '$senderName replied to your comment';
      case NotificationType.follow:
        return '$senderName started following you';
      case NotificationType.mention:
        return '$senderName mentioned you in a post';
    }
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $type, sender: $senderName, recipient: $recipientId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationModel &&
        other.id == id &&
        other.recipientId == recipientId &&
        other.senderId == senderId &&
        other.type == type &&
        other.postId == postId &&
        other.isRead == isRead;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        recipientId.hashCode ^
        senderId.hashCode ^
        type.hashCode ^
        postId.hashCode ^
        isRead.hashCode;
  }
}
