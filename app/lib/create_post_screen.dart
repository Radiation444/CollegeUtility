import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
  // --- Submit Post to Firestore ---
import 'package:firebase_storage/firebase_storage.dart'; // Add this import at the top
import 'package:path/path.dart' as p; // You might need: flutter pub add path
import './services/api_service.dart'; // <-- ADD THIS

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _locationController = TextEditingController();
  
  // State variables
  String _postType = 'Lost'; // Default
  String _itemType = 'Electronics'; // Default category
  Map<String, String> _attributes = {};
  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  final List<String> _categories = ['Electronics', 'Documents', 'Clothing', 'Keys', 'Wallets', 'Books', 'Other'];

  // --- Logic to Add a Custom Attribute ---
  void _addAttribute() {
    String key = "";
    String value = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Attribute"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(onChanged: (v) => key = v, decoration: const InputDecoration(hintText: "Property (e.g. Color)")),
            TextField(onChanged: (v) => value = v, decoration: const InputDecoration(hintText: "Value (e.g. Black)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (key.isNotEmpty && value.isNotEmpty) {
                setState(() => _attributes[key] = value);
                Navigator.pop(context);
              }
            }, 
            child: const Text("Add")
          ),
        ],
      ),
    );
  }

  // --- Logic to Pick Images ---
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _selectedImages.addAll(images));
    }
  }



  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one image.')));
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      List<String> imageUrls = [];

      // --- 1. UPLOAD IMAGES TO FIREBASE STORAGE ---
      for (var image in _selectedImages) {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
        Reference storageRef = FirebaseStorage.instance.ref().child('post_images/$fileName');

        UploadTask uploadTask;
        if (kIsWeb) {
          uploadTask = storageRef.putData(await image.readAsBytes());
        } else {
          uploadTask = storageRef.putFile(File(image.path));
        }

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      // --- 2. SAVE DOCUMENT TO FIRESTORE ---
      await FirebaseFirestore.instance.collection('lost_found_posts').add({
        'userId': user?.uid,
        'type': _postType,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'itemName': _itemNameController.text.trim(),
        'itemType': _itemType,
        'location': _locationController.text.trim(),
        'status': 'Open',
        'createdAt': FieldValue.serverTimestamp(),
        'dateTime': DateTime.now(),
        'attributes': _attributes,
        'images': imageUrls, 
      });

      // ==========================================================
      // --- 3. TRIGGER THE AI MATCHING ENGINE (NEW CODE!) ---
      // ==========================================================
      // We only send it if it's a mobile device (File paths work differently on Web)
      if (!kIsWeb && _selectedImages.isNotEmpty) {
        debugPrint("Sending first image to AI Brain for analysis...");
        
        // Send the first selected image to Python
        bool aiSuccess = await ApiService.uploadItem(
          imageFile: File(_selectedImages.first.path),
          status: _postType,   // 'Lost' or 'Found'
          category: _itemType, // e.g., 'Electronics'
        );

        if (aiSuccess) {
          debugPrint("✅ AI successfully processed the image!");
        } else {
          debugPrint("⚠️ AI processing failed, but Firebase upload succeeded.");
        }
      }
      // ==========================================================

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published & analyzing for matches!'))
        );
      }
    } catch (e) {
      print("Upload error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Post')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // 1. Post Type Toggle
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Lost', label: Text('Lost'), icon: Icon(Icons.search)),
                    ButtonSegment(value: 'Found', label: Text('Found'), icon: Icon(Icons.check_circle_outline)),
                  ],
                  selected: {_postType},
                  onSelectionChanged: (val) => setState(() => _postType = val.first),
                ),
                const SizedBox(height: 24),

                // 2. Title & Item Name
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Post Title (e.g., Lost Black Wallet)', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _itemType,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _itemType = v!),
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),

                // 3. Location
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location (e.g., Mess 1, LHC)', prefixIcon: Icon(Icons.map_outlined), border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),

                // 4. Attributes (JSON Map)
                const Text("Specific Details (Attributes)", style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: [
                    ..._attributes.entries.map((e) => Chip(
                      label: Text("${e.key}: ${e.value}"),
                      onDeleted: () => setState(() => _attributes.remove(e.key)),
                    )),
                    ActionChip(label: const Icon(Icons.add), onPressed: _addAttribute),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. Image Picker
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(_selectedImages.isEmpty ? "Add Photos" : "${_selectedImages.length} Photos Selected"),
                ),
                const SizedBox(height: 24),

                // 6. Submit Button
                ElevatedButton(
                  onPressed: _submitPost,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Publish Post', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
    );
  }
}