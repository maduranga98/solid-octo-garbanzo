import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String docId; // Added document ID field
  final String postId;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.docId, // Added to constructor
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  /// ✅ Firestore → CommentModel
  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CommentModel(
      docId: doc.id, // Get document ID from snapshot
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// ✅ Map → CommentModel
  factory CommentModel.fromMap(Map<String, dynamic> data, String docId) {
    return CommentModel(
      docId: docId, // Pass document ID explicitly
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// ✅ CommentModel → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      "postId": postId,
      "authorId": authorId,
      "authorName": authorName,
      "text": text,
      "createdAt": Timestamp.fromDate(createdAt),
    };
  }

  /// ✅ CopyWith (update only certain fields)
  CommentModel copyWith({
    String? docId,
    String? postId,
    String? authorId,
    String? authorName,
    String? text,
    DateTime? createdAt,
  }) {
    return CommentModel(
      docId: docId ?? this.docId,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
