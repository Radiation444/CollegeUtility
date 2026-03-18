import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart'; 

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  // NEW: Name Controller added
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  
  String? _selectedDept;
  String? _selectedHostel;
  bool _isLoading = false;

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

  Future<void> _saveProfile() async {
    // NEW: Added name validation
    if (_nameController.text.isEmpty || _selectedDept == null || _selectedHostel == null || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all required fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // NEW: Attach the name to their underlying Firebase Auth account!
      await user.updateDisplayName(_nameController.text.trim());

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'uid': user.uid,
        'name': _nameController.text.trim(), // NEW: Save to database
        'phone': _phoneController.text.trim(),
        'department': _selectedDept, 
        'hostel': _selectedHostel,  
        'bio': _bioController.text.trim(),
        'isProfileComplete': true, 
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome!', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            const Text(
              'Let your campus know a bit about you before you start sharing rides and finding items.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),

            // NEW: Full Name Field
            TextField(
              controller: _nameController, 
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Phone Number
            TextField(
              controller: _phoneController, 
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Department Dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Department *',
                prefixIcon: const Icon(Icons.science),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              value: _selectedDept,
              items: _departments.map((dept) {
                return DropdownMenuItem(value: dept, child: Text(dept));
              }).toList(),
              onChanged: (value) => setState(() => _selectedDept = value),
            ),
            const SizedBox(height: 16),

            // Hostel Dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Hostel *',
                prefixIcon: const Icon(Icons.apartment),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              value: _selectedHostel,
              items: _hostels.map((hostel) {
                return DropdownMenuItem(value: hostel, child: Text(hostel));
              }).toList(),
              onChanged: (value) => setState(() => _selectedHostel = value),
            ),
            const SizedBox(height: 16),

            // Bio
            TextField(
              controller: _bioController, 
              decoration: InputDecoration(
                labelText: 'Short Bio (Optional)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ), 
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Save Button
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Profile & Enter App', style: TextStyle(fontSize: 16)),
                )
          ],
        ),
      ),
    );
  }
}