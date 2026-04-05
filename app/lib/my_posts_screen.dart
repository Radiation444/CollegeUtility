import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  // --- LOGIC: Mark Post as Resolved ---
  Future<void> _markAsResolved(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('lost_found_posts')
          .doc(docId)
          .update({'status': 'Resolved'});
          
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post marked as Resolved! 🎉')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating post: $e')),
        );
      }
    }
  }

  // --- LOGIC: Delete Post (Optional but recommended) ---
  Future<void> _deletePost(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('lost_found_posts')
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint("Error deleting: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the currently logged-in user's ID
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Posts')),
        body: const Center(child: Text('Please log in to view your posts.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Posts'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // --- THE FIREBASE QUERY ---
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lost_found_posts')
            // ONLY fetch posts where the userId matches the logged-in user
            .where('userId', isEqualTo: currentUserId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint("My Posts Error: ${snapshot.error}");
            return const Center(child: Text('Error loading your posts. Check Firebase Indexes!'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("You haven't made any posts yet.", style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          final myDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: myDocs.length,
            itemBuilder: (context, index) {
              final doc = myDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isResolved = data['status'] == 'Resolved';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Type and Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['type'] ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: data['type'] == 'Lost' ? Colors.red : Colors.green,
                            ),
                          ),
                          Chip(
                            label: Text(
                              data['status'] ?? 'Open',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            backgroundColor: isResolved ? Colors.grey : Colors.blue,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        data['title'] ?? 'No Title',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Delete Button (Icon)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deletePost(context, doc.id),
                            tooltip: 'Delete Post',
                          ),
                          const SizedBox(width: 8),
                          // Resolve Button
                          ElevatedButton.icon(
                            onPressed: isResolved ? null : () => _markAsResolved(context, doc.id),
                            icon: Icon(isResolved ? Icons.check_circle : Icons.check),
                            label: Text(isResolved ? 'Resolved' : 'Mark as Resolved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isResolved ? Colors.grey[300] : Colors.green,
                              foregroundColor: isResolved ? Colors.grey[600] : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}