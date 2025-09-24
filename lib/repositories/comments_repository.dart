import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poem_application/models/comment_model.dart';

class CommentsRepository {
  final FirebaseFirestore firestore;
  CommentsRepository(this.firestore);

  //get comments
  Stream<List<CommentModel>> getComments(String postId) {
    return firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList(),
        );
  }

  // add a commnet
  Future<CommentModel> addComment(String postId, CommentModel data) async {
    final docRef = await firestore
        .collection('posts')
        .doc(postId)
        .collection("comments")
        .add(data.toFirestore());

    final snapshot = await docRef.get();

    return CommentModel.fromFirestore(snapshot);
  }

  // add a reply
  // Future<CommentModel> addReply(String postId, CommentModel data) async {
  //   final docRef = await firestore
  //       .collection('posts')
  //       .doc(postId)
  //       .collection("comments")
  //       .add(data.toFirestore());

  //   final snapshot = await docRef.get();

  //   return CommentModel.fromFirestore(snapshot);
  // }
}
