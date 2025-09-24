import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String postId;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;

  CommentModel({
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
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// ✅ Map → CommentModel
  factory CommentModel.fromMap(Map<String, dynamic> data) {
    return CommentModel(
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
    String? postId,
    String? authorId,
    String? authorName,
    String? text,
    DateTime? createdAt,
  }) {
    return CommentModel(
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
