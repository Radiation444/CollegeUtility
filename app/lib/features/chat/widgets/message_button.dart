import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/chat_screen.dart';

class MessageButton extends StatelessWidget {
  final String targetUserId;
  final String targetUserName;
  final String? targetUserAvatarUrl;
  final bool compact;

  const MessageButton({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserAvatarUrl,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    /// Don't show button on own profile
    if (currentUser?.uid == targetUserId) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return IconButton(
        icon: const Icon(Icons.message),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                otherUserId: targetUserId,
                otherUserName: targetUserName,
                otherUserAvatarUrl: targetUserAvatarUrl,
              ),
            ),
          );
        },
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.message),
        label: const Text("Message"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                otherUserId: targetUserId,
                otherUserName: targetUserName,
                otherUserAvatarUrl: targetUserAvatarUrl,
              ),
            ),
          );
        },
      ),
    );
  }
}