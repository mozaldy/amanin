// lib/screens/add_edit_post_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/post_provider.dart';
import '../providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEditPostScreen extends StatefulWidget {
  final PostModel? post;

  const AddEditPostScreen({Key? key, this.post}) : super(key: key);

  @override
  _AddEditPostScreenState createState() => _AddEditPostScreenState();
}

class _AddEditPostScreenState extends State<AddEditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String _crimeType = 'Maling';
  int _severity = 3;

  final List<String> _crimeTypes = [
    'Maling',
    'Jambret',
    'Kekerasan',
    'Perusakan',
    'Pembohongan',
    'Kecelakaan',
    'Narkoba',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _titleController.text = widget.post!.title;
      _descriptionController.text = widget.post!.description;
      _locationController.text = widget.post!.location;
      _crimeType = widget.post!.crimeType;
      _severity = widget.post!.severity;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _savePost() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final user = userProvider.user;

      if (user == null) return;

      final isEditing = widget.post != null;

      final PostModel post = PostModel(
        id: isEditing ? widget.post!.id : '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        timestamp: isEditing ? widget.post!.timestamp : DateTime.now(),
        authorId: isEditing ? widget.post!.authorId : user.uid,
        authorName: isEditing ? widget.post!.authorName : user.fullName,
        crimeType: _crimeType,
        severity: _severity,
        coordinates: GeoPoint(
          0,
          0,
        ), // Placeholder - would be set with actual coordinates
      );

      bool success;
      if (isEditing) {
        success = await postProvider.updatePost(post);
      } else {
        success = await postProvider.createPost(post);
      }

      if (success && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final isEditing = widget.post != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Post' : 'Add New Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _crimeType,
                decoration: const InputDecoration(
                  labelText: 'Crime Type',
                  border: OutlineInputBorder(),
                ),
                items:
                    _crimeTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _crimeType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Severity',
                style: TextStyle(fontSize: 16.0, color: Colors.grey),
              ),
              const SizedBox(height: 8.0),
              Slider(
                value: _severity.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: 'Level $_severity',
                onChanged: (double value) {
                  setState(() {
                    _severity = value.round();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Low', style: TextStyle(color: Colors.grey)),
                  Text('Medium', style: TextStyle(color: Colors.grey)),
                  Text('High', style: TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 24.0),
              if (postProvider.error != null)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.red.withOpacity(0.1),
                  child: Text(
                    postProvider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: postProvider.isLoading ? null : _savePost,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child:
                      postProvider.isLoading
                          ? const CircularProgressIndicator()
                          : Text(isEditing ? 'Update' : 'Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
