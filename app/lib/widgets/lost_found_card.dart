import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lost_found_post.dart';
import '../profile_screen.dart';
import '../chat_room_screen.dart';

class LostFoundCard extends StatelessWidget {
  final LostFoundPost post;
  
  const LostFoundCard({super.key, required this.post});

  // Helper to determine badge color based on status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'found': return Colors.green;
      case 'closed': return Colors.grey;
      case 'open':
      case 'lost': 
      default: return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER SECTION ---
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () {
                      // Navigates to the profile of whoever authored this post
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(userId: post.userId),
                        ),
                      );
                    },
                  child: Text(
                    post.posterName, // <-- UPDATED: Now reads directly from the model
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const Spacer(),
                // Simple date format
                Text(
                  "${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- 2. TITLE & STATUS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    post.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(post.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(post.status)),
                  ),
                  child: Text(
                    post.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(post.status), 
                      fontWeight: FontWeight.bold, 
                      fontSize: 12
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // --- 3. IMAGE SECTION ---
// --- 3. IMAGE SECTION ---
            if (post.images.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageScreen(
                        imageUrl: post.images.first,
                        heroTag: 'image_${post.postId}', // Unique tag for the animation
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'image_${post.postId}', // Must match the tag in the new screen
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                      image: DecorationImage(
                        image: NetworkImage(post.images.first),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

            // --- 5. LOCATION & TIME SECTION ---
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                const SizedBox(width: 4),
                Text(post.location, style: const TextStyle(fontSize: 13)),
                const Spacer(),
                const Icon(Icons.access_time, size: 16, color: Colors.blueAccent),
                const SizedBox(width: 4),
                Text(
                  "${post.dateTime.hour}:${post.dateTime.minute.toString().padLeft(2, '0')}", 
                  style: const TextStyle(fontSize: 13)
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- 6. FOOTER ACTIONS (UNIVERSAL CHAT BUTTON) ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  final postOwnerId = post.userId;

                  // Don't let users message themselves!
                  if (currentUserId == null || currentUserId == postOwnerId) return;

                  // 1. Calculate Universal Chat ID
                  List<String> users = [currentUserId, postOwnerId];
                  users.sort();
                  String chatId = "${users[0]}_${users[1]}";

                  // 2. Safely create room
                  await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
                    'participants': [currentUserId, postOwnerId],
                  }, SetOptions(merge: true));

                  // 3. Send automated icebreaker context message
                  final icebreakerText = 'Hi! I am messaging you regarding your post about the ${post.title}.';
                  await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add({
                    'senderId': currentUserId,
                    'text': icebreakerText,
                    'timestamp': FieldValue.serverTimestamp(),
                    'type': 'text', 
                  });

                  // 4. Update Inbox Badges
                  await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
                    'lastMessage': icebreakerText,
                    'lastTimestamp': FieldValue.serverTimestamp(),
                    'unreadCount_$postOwnerId': FieldValue.increment(1),
                  });

                  // 5. Jump to Chat Room
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(
                          chatId: chatId,
                          otherUserId: postOwnerId,
                          otherUserName: post.posterName, // <-- UPDATED: Passes the name to the chat screen
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Contact Poster'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add this at the bottom of your lost_found_card.dart file

class FullScreenImageScreen extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const FullScreenImageScreen({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        // The back button is automatically added by the AppBar
      ),
      body: Center(
        // InteractiveViewer gives you free pinch-to-zoom!
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: heroTag,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              },
            ),
          ),
        ),
      ),
    );
  }
}