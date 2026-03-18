import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  final String userId; 

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  final List<String> _departments = [
    'Computer Science and Engineering', 'Electrical Engineering', 
    'Mechanical Engineering', 'Civil Engineering', 'Artificial Intelligence', 
    'Bioscience and Bioengineering', 'Other'
  ];
  final List<String> _hostels = ['Hostel 1', 'Hostel 2', 'Hostel 3', 'Girls Hostel', 'Day Scholar'];

  void _showEditProfileSheet(Map<String, dynamic> userData) {
    // THE NEW NAME CONTROLLER FOR EDITING
    final nameController = TextEditingController(text: userData['name'] ?? '');
    final phoneController = TextEditingController(text: userData['phone']);
    final bioController = TextEditingController(text: userData['bio']);
    String rawDept = userData['department'] ?? _departments.first;
    String rawHostel = userData['hostel'] ?? _hostels.first;
    String selectedDept = _departments.contains(rawDept) ? rawDept : _departments.first;
    String selectedHostel = _hostels.contains(rawHostel) ? rawHostel : _hostels.first;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              TextField(
                controller: TextEditingController(text: userData['email']),
                enabled: false, 
                decoration: const InputDecoration(labelText: 'College Email (Cannot be changed)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              
              // THE NEW NAME TEXT BOX IN THE EDIT SHEET
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: selectedDept,
                items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => selectedDept = v!,
                decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedHostel,
                items: _hostels.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                onChanged: (v) => selectedHostel = v!,
                decoration: const InputDecoration(labelText: 'Hostel', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: bioController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isNotEmpty) {
                    await FirebaseAuth.instance.currentUser?.updateDisplayName(nameController.text.trim());
                  }

                  await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
                    'name': nameController.text.trim(), 
                    'phone': phoneController.text.trim(),
                    'department': selectedDept,
                    'hostel': selectedHostel,
                    'bio': bioController.text.trim(),
                  });
                  if (context.mounted) Navigator.pop(context); 
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!')));
                },
                child: const Text('Save Changes'),
              ),
              const SizedBox(height: 24),
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
        title: Text(isOwnProfile ? 'My Profile' : 'Student Profile'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(widget.userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text('User not found.'));

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String email = userData['email'] ?? 'No Email';
          
          // Grabs the real name to display at the top of the profile
          String displayName = userData['name'] ?? email.split('@').first.toUpperCase(); 

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?', style: const TextStyle(fontSize: 40, color: Colors.white)),
                ),
                const SizedBox(height: 16),
                Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(email, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 24),

                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ListTile(leading: const Icon(Icons.phone), title: const Text('Phone'), subtitle: Text(userData['phone'] ?? 'N/A')),
                        const Divider(),
                        ListTile(leading: const Icon(Icons.science), title: const Text('Department'), subtitle: Text(userData['department'] ?? 'N/A')),
                        const Divider(),
                        ListTile(leading: const Icon(Icons.apartment), title: const Text('Hostel'), subtitle: Text(userData['hostel'] ?? 'N/A')),
                        const Divider(),
                        ListTile(leading: const Icon(Icons.info_outline), title: const Text('Bio'), subtitle: Text(userData['bio']?.isEmpty ?? true ? 'No bio provided.' : userData['bio'])),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (isOwnProfile)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showEditProfileSheet(userData),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  )
              ],
            ),
          );
        },
      ),
    );
  }
}