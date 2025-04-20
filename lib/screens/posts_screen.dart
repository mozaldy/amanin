// lib/screens/posts_screen.dart

import 'package:amanin/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/post_model.dart';
import '../providers/post_provider.dart';
import '../providers/user_provider.dart';
import 'add_edit_post_screen.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({Key? key}) : super(key: key);

  @override
  _PostsScreenState createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the posts provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    final isAdmin = userProvider.user?.isAdmin ?? false;

    return Stack(
      children: [
        postProvider.isLoading && postProvider.posts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : postProvider.posts.isEmpty
            ? const Center(
              child: Text(
                'Masih belum ada insiden.',
                style: TextStyle(fontSize: 18.0),
              ),
            )
            : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: postProvider.posts.length,
              itemBuilder: (context, index) {
                final post = postProvider.posts[index];
                return _buildPostCard(context, post, isAdmin);
              },
            ),
        if (isAdmin)
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditPostScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  Widget _buildPostCard(BuildContext context, PostModel post, bool isAdmin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            color: AppTheme.getSeverityColor(post.severity),
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                _buildSeverityIndicator(post.severity),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.category, size: 16.0, color: Colors.grey),
                    const SizedBox(width: 4.0),
                    Text(
                      post.crimeType,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16.0,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4.0),
                    Expanded(
                      child: Text(
                        post.location,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16.0,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      DateFormat('MMM dd, yyyy - HH:mm').format(post.timestamp),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Text(post.description, style: const TextStyle(fontSize: 16.0)),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16.0, color: Colors.grey),
                    const SizedBox(width: 4.0),
                    Text(
                      'Pelapor: ${post.authorName}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditPostScreen(post: post),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _showDeleteConfirmation(context, post.id);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeverityIndicator(int severity) {
    return Row(
      children: [
        Text(
          'Level: ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14.0,
          ),
        ),
        ...List.generate(
          5,
          (index) => Icon(
            Icons.circle,
            size: 12.0,
            color:
                index < severity ? Colors.white : Colors.white.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Post'),
            content: const Text(
              'Are you sure you want to delete this post? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  Provider.of<PostProvider>(
                    context,
                    listen: false,
                  ).deletePost(postId);
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'DELETE',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
