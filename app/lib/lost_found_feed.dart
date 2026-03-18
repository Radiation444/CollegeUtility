import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/lost_found_post.dart';
import 'widgets/lost_found_card.dart';

class LostFoundFeed extends StatelessWidget {
  const LostFoundFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Lost & Found'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      // StreamBuilder listens to Firestore in real-time
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lost_found_posts') // Your collection name
            .orderBy('createdAt', descending: true) // Chronological sorting
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading posts.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No lost & found items posted yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final doc = posts[index];
              final post = LostFoundPost.fromMap(doc.data() as Map<String, dynamic>, doc.id);
              
              return LostFoundCard(post: post);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to Create Post Screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}