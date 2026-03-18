import 'package:cloud_firestore/cloud_firestore.dart';

class LostFoundPost {
  // Inherited from Post
  final String postId;
  final String userId;
  final String type; // e.g., 'Lost' or 'Found'
  final String title;
  final String description;
  final List<String> images;
  final DateTime createdAt;
  final String location;
  final String status; // 'Open', 'Found', 'Closed'

  // Specific to LostFoundPost
  final String itemType;
  final String itemName;
  final Map<String, dynamic> attributes; // Parsed from JSON
  final DateTime dateTime; // When it was lost/found

  LostFoundPost({
    required this.postId,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.images,
    required this.createdAt,
    required this.location,
    required this.status,
    required this.itemType,
    required this.itemName,
    required this.attributes,
    required this.dateTime,
  });

  // A factory to easily create this object from a Firestore document
  factory LostFoundPost.fromMap(Map<String, dynamic> map, String documentId) {
    return LostFoundPost(
      postId: documentId,
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'Lost',
      title: map['title'] ?? 'Untitled',
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: map['location'] ?? 'Unknown Location',
      status: map['status'] ?? 'Open',
      itemType: map['itemType'] ?? 'General',
      itemName: map['itemName'] ?? 'Unknown Item',
      attributes: Map<String, dynamic>.from(map['attributes'] ?? {}),
      dateTime: (map['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}