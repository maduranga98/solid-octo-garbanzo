// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poem_application/models/post_model.dart';

class PostRepository {
  final FirebaseFirestore firestore;
  PostRepository(this.firestore);

  //get posts
  Stream<List<PostModel>> getPost() {
    return firestore
        .collection('posts')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList(),
        );
  }

  //get post from userId
  Stream<List<PostModel>> getPostByUid(String uid) {
    return firestore
        .collection("posts")
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList(),
        );
  }

  // create a post
  Future<void> createPost(PostModel data) async {
    try {
      final docRef = firestore.collection("posts").doc();
      final postWithId = data.copyWith(docId: docRef.id);
      await docRef.set(postWithId.toFirestore());
    } on Exception catch (e) {
      print("Error in creating a post: $e");
    }
  }

  // delete the post
  Future<void> deletePost(String postId) async {
    try {
      await firestore.collection('posts').doc(postId).delete();
    } on Exception catch (e) {
      print("print error in delect post: $e");
    }
  }

  //update the posts
  Future<PostModel?> updatePost(String postId, PostModel data) async {
    try {
      await firestore
          .collection('posts')
          .doc(postId)
          .update(data.toFirestore());
      final postDoc = await firestore.collection('posts').doc(postId).get();
      if (postDoc.exists) {
        return PostModel.fromFirestore(postDoc);
      }
      return null;
    } on Exception catch (e) {
      print("Error in updating post: $e");
      return null;
    }
  }
}
