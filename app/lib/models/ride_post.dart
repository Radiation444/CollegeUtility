import 'package:cloud_firestore/cloud_firestore.dart';

class RidePost {
  final String id;
  final String userId;
  final String posterName;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final String transportMode; 
  final int availableSeats;
  final String notes;
  final String status; 
  final DateTime createdAt;

  RidePost({
    required this.id,
    required this.userId,
    required this.posterName,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.transportMode,
    required this.availableSeats,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  factory RidePost.fromMap(Map<String, dynamic> map, String documentId) {
    return RidePost(
      id: documentId,
      userId: map['userId'] ?? '',
      posterName: map['posterName'] ?? 'Student',
      origin: map['origin'] ?? 'Unknown',
      destination: map['destination'] ?? 'Unknown',
      departureTime: (map['departureTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      transportMode: map['transportMode'] ?? 'Cab',
      availableSeats: map['availableSeats'] ?? 1,
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'Open',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}