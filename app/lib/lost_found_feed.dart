import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/lost_found_post.dart';
import 'widgets/lost_found_card.dart';
import 'create_post_screen.dart';

class LostFoundFeed extends StatefulWidget {
  const LostFoundFeed({super.key});

  @override
  State<LostFoundFeed> createState() => _LostFoundFeedState();
}

class _LostFoundFeedState extends State<LostFoundFeed> {
  // --- 1. STATE VARIABLES ---
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _sortDescending = true; // true = Newest first

  final List<String> _categories = [
    'All', 'Electronics', 'Documents', 'Clothing', 'Keys', 'Wallets', 'Books', 'Other'
  ];

  // --- 2. FIREBASE QUERY BUILDER ---
  Stream<QuerySnapshot> _buildStream() {
    Query query = FirebaseFirestore.instance.collection('lost_found_posts');

    if (_selectedCategory != 'All') {
      query = query.where('itemType', isEqualTo: _selectedCategory); 
    }

    query = query.orderBy('createdAt', descending: _sortDescending);

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Lost & Found'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          // --- SORT TOGGLE BUTTON ---
          IconButton(
            icon: Icon(_sortDescending ? Icons.arrow_downward : Icons.arrow_upward),
            tooltip: 'Sort by Date (Toggle)',
            onPressed: () {
              setState(() {
                _sortDescending = !_sortDescending;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 3. SEARCH & FILTER UI ---
          Container(
            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  flex: 5,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search title or desc...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Category Dropdown
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCategory,
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedCategory = v!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- 4. FIREBASE STREAM ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildStream(), // Using our custom builder method
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint("StreamBuilder Error: ${snapshot.error}"); 
                  return Center(child: Text('Error loading posts.\nCheck console for Firebase Index links!'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No lost & found items posted yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  );
                }

                // --- 5. LOCAL TEXT SEARCH FILTERING ---
                var rawDocs = snapshot.data!.docs;
                var filteredDocs = rawDocs;

                if (_searchQuery.isNotEmpty) {
                  filteredDocs = rawDocs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    var title = (data['title'] ?? '').toString().toLowerCase();
                    var desc = (data['description'] ?? '').toString().toLowerCase();
                    return title.contains(_searchQuery) || desc.contains(_searchQuery);
                  }).toList();
                }

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text('No items match your search.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  );
                }

                // --- 6. BUILD THE LIST (Using existing custom widgets) ---
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final post = LostFoundPost.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                    
                    return LostFoundCard(post: post);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}