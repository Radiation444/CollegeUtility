import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatService chatService = ChatService();
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatService.getConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No conversations yet",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat =
                  chats[index].data() as Map<String, dynamic>;

              final participants =
                  List<String>.from(chat['participants']);

              final otherUserId = participants
                  .firstWhere((id) => id != currentUser!.uid);

              final lastMessage =
                  chat['lastMessage'] ?? '';

              return ListTile(
                leading: CircleAvatar(
                  child: const Icon(Icons.person),
                ),
                title: Text(otherUserId),
                subtitle: Text(lastMessage),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherUserId: otherUserId,
                        otherUserName: otherUserId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}