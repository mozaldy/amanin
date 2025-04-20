// lib/services/post_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath = 'posts';

  // Get all posts
  Stream<List<PostModel>> getPosts() {
    return _firestore
        .collection(collectionPath)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => PostModel.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // Get a single post
  Future<PostModel?> getPost(String postId) async {
    final DocumentSnapshot doc =
        await _firestore.collection(collectionPath).doc(postId).get();
    if (doc.exists) {
      return PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Create a new post
  Future<String> createPost(PostModel post) async {
    final DocumentReference docRef = await _firestore
        .collection(collectionPath)
        .add(post.toMap());
    return docRef.id;
  }

  // Update an existing post
  Future<void> updatePost(PostModel post) async {
    await _firestore
        .collection(collectionPath)
        .doc(post.id)
        .update(post.toMap());
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    await _firestore.collection(collectionPath).doc(postId).delete();
  }
}
