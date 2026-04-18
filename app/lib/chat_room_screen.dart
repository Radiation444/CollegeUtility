import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

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
  bool _isUploadingImage = false; // To show a loading spinner while sending

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUserId == null) return;

    _messageController.clear();

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    // 1. Save the message
    await chatRef.collection('messages').add({
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text', 
    });

    // 2. Update the main chat doc
    await chatRef.update({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unreadCount_${widget.otherUserId}': FieldValue.increment(1),
    });
  }

  // --- NEW: THE IMAGE SENDER FUNCTION ---
  Future<void> _sendImage() async {
    if (currentUserId == null) return;

    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile == null) return; // User canceled

    setState(() => _isUploadingImage = true);

    try {
      final Uint8List bytes = await pickedFile.readAsBytes();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload to Firebase Storage inside a folder for this specific chat
      final ref = FirebaseStorage.instance.ref().child('chat_images/${widget.chatId}/$fileName');
      await ref.putData(bytes);
      final String imageUrl = await ref.getDownloadURL();

      final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

      // Save the image message
      await chatRef.collection('messages').add({
        'senderId': currentUserId,
        'imageUrl': imageUrl,
        'text': '📷 Image', // Fallback text
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'image', // Tag it as an image!
      });

      // Update the main chat doc so the Inbox says "📷 Image"
      await chatRef.update({
        'lastMessage': '📷 Image',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'unreadCount_${widget.otherUserId}': FieldValue.increment(1),
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send image.')));
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _handleRideRequest(String messageId, String rideId, String status) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .update({'requestStatus': status});

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
      backgroundColor: Colors.grey[100],
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
                  reverse: true, 
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == currentUserId;
                    final msgType = msg['type'] ?? 'text';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8, top: 4),
                        padding: EdgeInsets.all(msgType == 'image' ? 4 : 12), // Tighter padding for images
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.white,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                            bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                          ]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- RENDER NORMAL TEXT ---
                            if (msgType == 'text' || msgType == 'ride_request')
                              Text(
                                msg['text'] ?? '',
                                style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16),
                              ),
                            
                            // --- RENDER IMAGE ---
                            if (msgType == 'image' && msg['imageUrl'] != null)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FullScreenImageViewer(imageUrl: msg['imageUrl']),
                                    ),
                                  );
                                },
                                child: Hero(
                                  tag: msg['imageUrl'], // Smooth transition animation!
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      msg['imageUrl'],
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const SizedBox(
                                          height: 200, 
                                          width: 200, 
                                          child: Center(child: CircularProgressIndicator())
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            
                            // --- RENDER RIDE REQUEST BUTTONS ---
                            if (msgType == 'ride_request') ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(isMe ? 0.2 : 1), borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  children: [
                                    Text('🎟️ Ride Request', style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? Colors.white : Colors.black87)),
                                    const SizedBox(height: 8),
                                    if ((msg['requestStatus'] ?? 'pending') == 'pending' && !isMe)
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
                                      Text(
                                        (msg['requestStatus'] ?? 'pending').toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: msg['requestStatus'] == 'Accepted' ? Colors.green : (msg['requestStatus'] == 'Declined' ? Colors.red : Colors.orange),
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
                  // NEW: CAMERA BUTTON
                  IconButton(
                    icon: _isUploadingImage 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Icon(Icons.image, color: Colors.blue),
                    onPressed: _isUploadingImage ? null : _sendImage,
                  ),
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

// --- NEW: FULL SCREEN IMAGE VIEWER ---
class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Standard dark background for photo viewing
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white), // White back button
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true, // Lets you swipe around when zoomed in
          minScale: 1.0,
          maxScale: 4.0, // Lets you pinch-to-zoom up to 4x!
          child: Hero(
            tag: imageUrl, // Matches the tag in the chat room to catch the flying image
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }
}