import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/models/post_model.dart';
import 'package:poem_application/repositories/post_repository.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(FirebaseFirestore.instance);
});

final postsProvider = StreamProvider<List<PostModel>>((ref) {
  final repo = ref.watch(postRepositoryProvider);
  return repo.getPost();
});

final getPostByUidProvider = StreamProvider.family<List<PostModel>, String>((
  ref,
  uid,
) {
  final repo = ref.watch(postRepositoryProvider);
  return repo.getPostByUid(uid);
});

// final createPostProvider = FutureProvider.family<void, PostModel>((ref, data) {
//   final repo = ref.watch(postRepositoryProvider);
//   return repo.createPost(data);
// });
// final detelePostByIdProvider = FutureProvider.family<void, String>((
//   ref,
//   postId,
// ) {
//   final repo = ref.watch(postRepositoryProvider);
//   return repo.deletePost(postId);
// });

// final updatePostProvider = FutureProvider.family<void, UpdatePostParam>((
//   ref,
//   params,
// ) {
//   final repo = ref.watch(postRepositoryProvider);
//   return repo.updatePost(params.postId, params.data);
// });

// class UpdatePostParam {
//   final String postId;
//   final PostModel data;
//   UpdatePostParam(this.postId, this.data);
// }
