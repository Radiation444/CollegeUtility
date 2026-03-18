import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart'; // To route back to Dashboard

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _phoneController = TextEditingController();
  final _deptController = TextEditingController();
  final _bioController = TextEditingController();
  final _hostelController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Save all data to Firestore in a document named after their UID
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'uid': user.uid,
        'phone': _phoneController.text.trim(),
        'department': _deptController.text.trim(),
        'bio': _bioController.text.trim(),
        'hostel': _hostelController.text.trim(),
        'isProfileComplete': true, 
      });

      // Push them to the Dashboard once saved
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
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            const Text('Welcome! Please fill out your details to continue.', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
            const SizedBox(height: 16),
            TextField(controller: _deptController, decoration: const InputDecoration(labelText: 'Department (e.g., CSE)')),
            const SizedBox(height: 16),
            TextField(controller: _hostelController, decoration: const InputDecoration(labelText: 'Hostel Name & Room')),
            const SizedBox(height: 16),
            TextField(controller: _bioController, decoration: const InputDecoration(labelText: 'Short Bio'), maxLines: 3),
            const SizedBox(height: 32),
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save Profile & Enter App'),
                )
          ],
        ),
      ),
    );
  }
}