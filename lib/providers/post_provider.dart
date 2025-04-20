// lib/providers/post_provider.dart

import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

class PostProvider extends ChangeNotifier {
  final PostService _postService = PostService();
  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _error;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize the provider
  void initialize() {
    _getPosts();
  }

  // Listen to posts stream
  void _getPosts() {
    _isLoading = true;
    notifyListeners();

    _postService.getPosts().listen(
      (posts) {
        _posts = posts;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Create a new post
  Future<bool> createPost(PostModel post) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _postService.createPost(post);
      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update an existing post
  Future<bool> updatePost(PostModel post) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _postService.updatePost(post);
      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a post
  Future<bool> deletePost(String postId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _postService.deletePost(postId);
      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
