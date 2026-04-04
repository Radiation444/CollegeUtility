import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:college_utility_application/features/chat/chat.dart';

class ProfileScreen extends StatefulWidget {
final String userId;

const ProfileScreen({super.key, required this.userId});

@override
State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
final String currentUserId =
FirebaseAuth.instance.currentUser?.uid ?? '';

Uint8List? _image;
bool _isUploading = false;

final List<String> _departments = [
'Computer Science and Engineering',
'Electrical Engineering',
'Mechanical Engineering',
'Civil Engineering',
'Artificial Intelligence',
'Bioscience and Bioengineering',
'Other'
];

final List<String> _hostels = [
'Hostel 1',
'Hostel 2',
'Hostel 3',
'Girls Hostel',
'Day Scholar'
];

Future<void> _pickImage() async {
final XFile? file =
await ImagePicker().pickImage(source: ImageSource.gallery);


if (file != null) {
  final bytes = await file.readAsBytes();

  setState(() {
    _image = bytes;
  });

  await _uploadImage(bytes);
}


}

Future<void> _uploadImage(Uint8List image) async {
setState(() {
_isUploading = true;
});

try {
  final ref = FirebaseStorage.instance
      .ref()
      .child('profile_images')
      .child('${widget.userId}.jpg');

  await ref.putData(image);

  String imageUrl = await ref.getDownloadURL();

  await FirebaseFirestore.instance
      .collection('users')
      .doc(widget.userId)
      .update({
    'profileImage': imageUrl,
  });
} catch (e) {
  print(e);
}

setState(() {
  _isUploading = false;
});


}

void _showEditProfileSheet(Map<String, dynamic> userData) {
final nameController =
TextEditingController(text: userData['name'] ?? '');


final phoneController =
    TextEditingController(text: userData['phone']);

final bioController =
    TextEditingController(text: userData['bio']);

String selectedDept =
    userData['department'] ?? _departments.first;

String selectedHostel =
    userData['hostel'] ?? _hostels.first;

showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
  builder: (context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context)
              .viewInsets
              .bottom,
          left: 24,
          right: 24,
          top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Edit Profile',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: nameController,
            decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder()),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: phoneController,
            decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder()),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: selectedDept,
            items: _departments
                .map((d) =>
                    DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => selectedDept = v!,
            decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder()),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: selectedHostel,
            items: _hostels
                .map((h) =>
                    DropdownMenuItem(value: h, child: Text(h)))
                .toList(),
            onChanged: (v) => selectedHostel = v!,
            decoration: const InputDecoration(
                labelText: 'Hostel',
                border: OutlineInputBorder()),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: bioController,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder()),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .update({
                'name': nameController.text.trim(),
                'phone': phoneController.text.trim(),
                'department': selectedDept,
                'hostel': selectedHostel,
                'bio': bioController.text.trim(),
              });

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  },
);


}

@override
Widget build(BuildContext context) {
bool isOwnProfile = widget.userId == currentUserId;


return Scaffold(
  backgroundColor: Colors.grey[100],
  appBar: AppBar(
    title: Text(isOwnProfile ? "My Profile" : "Profile"),
  ),
  body: FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(
            child: CircularProgressIndicator());
      }

      var userData =
          snapshot.data!.data() as Map<String, dynamic>;

      String email = userData['email'] ?? "No email";
      String displayName =
          userData['name'] ?? email.split('@').first;
      String? imageUrl = userData['profileImage'];

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            GestureDetector(
              onTap: isOwnProfile ? _pickImage : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _image != null
                        ? MemoryImage(_image!)
                        : (imageUrl != null
                            ? NetworkImage(imageUrl)
                            : null) as ImageProvider?,
                    child: imageUrl == null &&
                            _image == null
                        ? Text(
                            displayName[0].toUpperCase(),
                            style:
                                const TextStyle(fontSize: 40),
                          )
                        : null,
                  ),

                  if (isOwnProfile)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blue,
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              displayName,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),

            Text(email),

            const SizedBox(height: 16),

            if (!isOwnProfile)
              MessageButton(
                targetUserId: widget.userId,
                targetUserName: displayName,
                targetUserAvatarUrl: imageUrl,
              ),

            const SizedBox(height: 24),

            Card(
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text("Phone"),
                      subtitle: Text(
                          userData['phone'] ?? "N/A"),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(Icons.school),
                      title: const Text("Department"),
                      subtitle: Text(
                          userData['department'] ?? "N/A"),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(Icons.home),
                      title: const Text("Hostel"),
                      subtitle: Text(
                          userData['hostel'] ?? "N/A"),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text("Bio"),
                      subtitle:
                          Text(userData['bio'] ?? "No Bio"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (isOwnProfile) ...[
              const MessagingToggleTile(),
              const SizedBox(height: 10),

              ElevatedButton.icon(
                onPressed: () =>
                    _showEditProfileSheet(userData),
                icon: const Icon(Icons.edit),
                label: const Text("Edit Profile"),
              ),
            ]
          ],
        ),
      );
    },
  ),
);


}
}
