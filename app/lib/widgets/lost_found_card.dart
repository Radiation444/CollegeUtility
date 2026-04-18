import 'package:flutter/material.dart';
import '../models/lost_found_post.dart';
import '../profile_screen.dart';
import '../features/chat/screens/chat_screen.dart';

class LostFoundCard extends StatelessWidget {
  final LostFoundPost post;
  
  // In a NoSQL database, you often save the poster's name directly on the post 
  // to avoid doing a secondary lookup, or you fetch it separately. 
  // We'll pass it in here for the UI.
  final String posterName; 

  const LostFoundCard({super.key, required this.post, this.posterName = "Student"});

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
                    posterName,
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
            if (post.images.isNotEmpty)
              Container(
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

            // --- 4. DETAILS SECTION ---
            Row(
              children: [
                const Icon(Icons.category, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${post.itemName} • ${post.itemType}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(post.description, style: TextStyle(color: Colors.grey[800], fontSize: 14)),
            const SizedBox(height: 12),

            // Attributes Chips
            if (post.attributes.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: post.attributes.entries.map((entry) {
                  return Chip(
                    label: Text('${entry.key}: ${entry.value}', style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.grey[100],
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            const Divider(),

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

            // --- 6. FOOTER ACTIONS ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        otherUserId: post.userId,
                       otherUserName: posterName,
                      ),
                    ),
                  );
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