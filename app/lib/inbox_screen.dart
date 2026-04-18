import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'chat_room_screen.dart'; // We will build this next!

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Direct Messages'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .orderBy('lastTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading inbox. Check Firebase Indexes!'));
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No messages yet.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatDoc = chats[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              
              // Figure out who the OTHER person is
              final participants = List<String>.from(chatData['participants']);
              final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => currentUserId);
              
              final lastMessage = chatData['lastMessage'] ?? '';
              final unreadCount = chatData['unreadCount_$currentUserId'] ?? 0;
              final timestamp = chatData['lastTimestamp'] as Timestamp?;
              final timeString = timestamp != null ? DateFormat('hh:mm a').format(timestamp.toDate()) : '';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox(height: 72); // Placeholder height
                  
                  final userData = userSnap.data?.data() as Map<String, dynamic>?;
                  final otherName = userData?['name'] ?? 'Student';
                  final otherImage = userData?['profileImage'];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    tileColor: unreadCount > 0 ? Colors.white : Colors.transparent,
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage: otherImage != null ? NetworkImage(otherImage) : null,
                      child: otherImage == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(
                      otherName, 
                      style: TextStyle(fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500)
                    ),
                    subtitle: Text(
                      lastMessage, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: unreadCount > 0 ? Colors.black87 : Colors.grey)
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(timeString, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        if (unreadCount > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ]
                      ],
                    ),
                    onTap: () {
                      // Reset unread count to 0 when opening the chat!
                      FirebaseFirestore.instance.collection('chats').doc(chatDoc.id).update({
                        'unreadCount_$currentUserId': 0,
                      });

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoomScreen(
                            chatId: chatDoc.id, 
                            otherUserId: otherUserId, 
                            otherUserName: otherName
                          )
                        ),
                      );
                    },
                  );
                }
              );
            },
          );
        },
      ),
    );
  }
}