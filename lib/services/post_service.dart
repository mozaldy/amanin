import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath = 'posts';

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

  Future<PostModel?> getPost(String postId) async {
    final DocumentSnapshot doc =
        await _firestore.collection(collectionPath).doc(postId).get();
    if (doc.exists) {
      return PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<String> createPost(PostModel post) async {
    final DocumentReference docRef = await _firestore
        .collection(collectionPath)
        .add(post.toMap());
    return docRef.id;
  }

  Future<void> updatePost(PostModel post) async {
    await _firestore
        .collection(collectionPath)
        .doc(post.id)
        .update(post.toMap());
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection(collectionPath).doc(postId).delete();
  }
}
