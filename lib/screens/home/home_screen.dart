import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poem_application/providers/postRepositoryProvider.dart';
import 'package:poem_application/providers/user_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("All Posts")),
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text("No posts found"));
          }
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              print(post.createdBy);
              final userAsync = ref.watch(getUserDataProvider(post.createdBy));

              return Container(
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.black38, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        userAsync.when(
                          data: (user) {
                            if (user == null) {
                              return const Text("User not found");
                            }
                            return Row(
                              children: [
                                CircleAvatar(child: Text(user.userName[0])),
                                const SizedBox(width: 8),
                                Text(user.userName),
                              ],
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (e, _) => Text("Error: $e"),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
}
