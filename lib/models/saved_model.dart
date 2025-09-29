import 'package:cloud_firestore/cloud_firestore.dart';

class SavedModel {
  final String postAuthor;
  final String postId;
  final String postTitle;
  final Timestamp bookmarkedAt;

  SavedModel({
    required this.postAuthor,
    required this.postId,
    required this.postTitle,
    required this.bookmarkedAt,
  });

  factory SavedModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SavedModel(
      postAuthor: data["postAuthor"],
      postId: data["postId"],
      postTitle: data["postTitle"],
      bookmarkedAt: data["bookmarkedAt"],
    );
  }
}
