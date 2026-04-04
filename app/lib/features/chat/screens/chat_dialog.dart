import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatDialog {
  static void show(
    BuildContext context, {
    required String otherUserId,
    required String otherUserName,
    String? otherUserAvatarUrl,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          otherUserAvatarUrl: otherUserAvatarUrl,
        ),
      ),
    );
  }
}