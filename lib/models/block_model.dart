import 'package:cloud_firestore/cloud_firestore.dart';

class BlockModel {
  final String docId;
  final String blockedBy;
  final String blockedUserId;
  final String blockedUsername;
  final DateTime createdAt;
  final String? reason;

  BlockModel({
    required this.docId,
    required this.blockedBy,
    required this.blockedUserId,
    required this.blockedUsername,
    required this.createdAt,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'blockedBy': blockedBy,
      'blockedUserId': blockedUserId,
      'blockedUsername': blockedUsername,
      'createdAt': createdAt,
      'reason': reason,
    };
  }

  factory BlockModel.fromMap(Map<String, dynamic> map, String docId) {
    return BlockModel(
      docId: docId,
      blockedBy: map['blockedBy'] ?? '',
      blockedUserId: map['blockedUserId'] ?? '',
      blockedUsername: map['blockedUsername'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      reason: map['reason'],
    );
  }
}
