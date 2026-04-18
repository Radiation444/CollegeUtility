import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';
import '../widgets/message_bubble.dart';
import 'image_viewer.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {

  // Existing
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatarUrl;

  // ✅ Added (for LostFoundCard compatibility)
  final String? receiverId;
  final String? receiverName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatarUrl,
    this.receiverId,
    this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ImagePicker _picker = ImagePicker();

  String get receiverId =>
      widget.receiverId ?? widget.otherUserId;

  String get receiverName =>
      widget.receiverName ?? widget.otherUserName;

  void sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await _chatService.sendMessage(
      receiverId: receiverId,
      message: text,
    );

    _controller.clear();

    Future.delayed(const Duration(milliseconds: 200), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// Pick Image
  Future<dynamic> pickImage() async {
    if (kIsWeb) {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        return result.files.first.bytes;
      }

      return null;
    } else {
      final XFile? image =
          await _picker.pickImage(source: ImageSource.gallery);

      if (image == null) return null;

      return File(image.path);
    }
  }

  /// Upload Image
  Future<String> uploadImage(dynamic image) async {
    String fileName = const Uuid().v4();

    Reference ref = FirebaseStorage.instance
        .ref()
        .child("chatImages")
        .child(fileName);

    UploadTask uploadTask;

    if (kIsWeb) {
      uploadTask = ref.putData(image as Uint8List);
    } else {
      uploadTask = ref.putFile(image as File);
    }

    TaskSnapshot snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }

  /// Send Image
  Future sendImage() async {
    final image = await pickImage();

    if (image == null) return;

    String imageUrl = await uploadImage(image);

    await _chatService.sendImageMessage(
      receiverId: receiverId,
      imageUrl: imageUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.otherUserAvatarUrl != null
                  ? NetworkImage(widget.otherUserAvatarUrl!)
                  : null,
              child: widget.otherUserAvatarUrl == null
                  ? Text(receiverName[0])
                  : null,
            ),
            const SizedBox(width: 10),
            Text(receiverName),
          ],
        ),
      ),
      body: Column(
        children: [
          /// Messages
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(receiverId),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      "Start chatting with $receiverName",
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe =
                        message.senderId == currentUser?.uid;

                    if (message.type == "image") {
                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ImageViewer(imageUrl: message.message),
                                ),
                              );
                            },
                            child: Hero(
                              tag: message.message,
                              child: Image.network(
                                message.message,
                                width: 200,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return MessageBubble(
                      message: message.message,
                      isMe: isMe,
                      timestamp: message.timestamp,
                    );
                  },
                );
              },
            ),
          ),

          /// Input Box
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: sendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(25),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    child: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: sendMessage,
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