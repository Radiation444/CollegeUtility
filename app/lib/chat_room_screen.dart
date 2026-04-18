import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUserId == null) return;

    _messageController.clear();

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    // 1. Save the message in the subcollection
    await chatRef.collection('messages').add({
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text', // Normal text message
    });

    // 2. Update the main chat document
    await chatRef.update({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unreadCount_${widget.otherUserId}': FieldValue.increment(1),
    });
  }

  Future<void> _handleRideRequest(String messageId, String rideId, String status) async {
    // Update the message bubble to show "Accepted" or "Declined"
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .update({'requestStatus': status});

    // If accepted, reduce the available seats in the actual ride!
    if (status == 'Accepted') {
      final rideRef = FirebaseFirestore.instance.collection('ride_shares').doc(rideId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final rideSnapshot = await transaction.get(rideRef);
        if (rideSnapshot.exists) {
          final currentSeats = rideSnapshot.data()?['availableSeats'] ?? 0;
          if (currentSeats > 0) {
            transaction.update(rideRef, {'availableSeats': currentSeats - 1});
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Start from the bottom like a real chat app!
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == currentUserId;
                    final isRideRequest = msg['type'] == 'ride_request';
                    final requestStatus = msg['requestStatus'] ?? 'pending';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8, top: 8),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                            bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['text'] ?? '',
                              style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 16),
                            ),
                            
                            // IF THIS IS A RIDE REQUEST, DRAW THE BUTTONS!
                            if (isRideRequest) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(isMe ? 0.2 : 1), borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  children: [
                                    Text('🎟️ Ride Request', style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? Colors.white : Colors.black87)),
                                    const SizedBox(height: 8),
                                    
                                    // If it's pending and I am NOT the sender (I am the driver receiving it)
                                    if (requestStatus == 'pending' && !isMe)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          TextButton(
                                            onPressed: () => _handleRideRequest(messages[index].id, msg['rideId'], 'Declined'),
                                            child: const Text('Decline', style: TextStyle(color: Colors.red)),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                            onPressed: () => _handleRideRequest(messages[index].id, msg['rideId'], 'Accepted'),
                                            child: const Text('Accept'),
                                          ),
                                        ],
                                      )
                                    else
                                      // It has been answered (or I am the sender waiting for an answer)
                                      Text(
                                        requestStatus.toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: requestStatus == 'Accepted' ? Colors.green : (requestStatus == 'Declined' ? Colors.red : Colors.orange),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // --- THE TEXT INPUT BAR ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}