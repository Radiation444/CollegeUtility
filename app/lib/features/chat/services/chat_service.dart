import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser!.uid;

  /// Generate chat id between two users
  String getChatId(String otherUserId) {
    final ids = [currentUserId, otherUserId]..sort();
    return ids.join('_');
  }

  /// Send message
  Future<void> sendMessage({
    required String receiverId,
    required String message,
  }) async {
    final chatId = getChatId(receiverId);

    final messageData = {
      'senderId': currentUserId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    /// Update chat metadata
    await _firestore.collection('chats').doc(chatId).set({
      'participants': [currentUserId, receiverId],
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': currentUserId,
    }, SetOptions(merge: true));
  }

  /// Get messages stream (real-time)
  Stream<List<MessageModel>> getMessages(String otherUserId) {
    final chatId = getChatId(otherUserId);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Get conversations list
  Stream<QuerySnapshot> getConversations() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
}