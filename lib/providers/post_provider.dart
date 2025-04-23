import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

final postServiceProvider = Provider<PostService>((ref) {
  return PostService();
});

class PostsState {
  final List<PostModel> posts;
  final bool isLoading;
  final String? error;

  PostsState({required this.posts, required this.isLoading, this.error});

  PostsState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    String? error,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PostsNotifier extends StateNotifier<PostsState> {
  final PostService _postService;

  PostsNotifier(this._postService)
    : super(PostsState(posts: [], isLoading: false));

  void getPosts() {
    state = state.copyWith(isLoading: true);

    _postService.getPosts().listen(
      (posts) {
        state = state.copyWith(posts: posts, isLoading: false, error: null);
      },
      onError: (e) {
        state = state.copyWith(isLoading: false, error: e.toString());
      },
    );
  }

  Future<bool> createPost(PostModel post) async {
    state = state.copyWith(isLoading: true);

    try {
      await _postService.createPost(post);
      state = state.copyWith(isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updatePost(PostModel post) async {
    state = state.copyWith(isLoading: true);

    try {
      await _postService.updatePost(post);
      state = state.copyWith(isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    state = state.copyWith(isLoading: true);

    try {
      await _postService.deletePost(postId);
      state = state.copyWith(isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final postsProvider = StateNotifierProvider<PostsNotifier, PostsState>((ref) {
  final postService = ref.watch(postServiceProvider);
  return PostsNotifier(postService);
});
