// lib/models/post_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime timestamp;
  final String authorId;
  final String authorName;
  final GeoPoint? coordinates;
  final String? imageUrl;
  final String crimeType;
  final int severity; // 1-5 scale

  PostModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.timestamp,
    required this.authorId,
    required this.authorName,
    required this.crimeType,
    required this.severity,
    this.coordinates,
    this.imageUrl,
  });

  factory PostModel.fromMap(Map<String, dynamic> data, String id) {
    return PostModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      crimeType: data['crimeType'] ?? 'Other',
      severity: data['severity'] ?? 1,
      coordinates: data['coordinates'],
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'timestamp': Timestamp.fromDate(timestamp),
      'authorId': authorId,
      'authorName': authorName,
      'crimeType': crimeType,
      'severity': severity,
      'coordinates': coordinates,
      'imageUrl': imageUrl,
    };
  }
}
