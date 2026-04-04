import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagingToggleTile extends StatefulWidget {
  const MessagingToggleTile({super.key});

  @override
  State<MessagingToggleTile> createState() => _MessagingToggleTileState();
}

class _MessagingToggleTileState extends State<MessagingToggleTile> {
  bool messagingEnabled = false;
  bool isLoading = true;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    loadSetting();
  }

  Future<void> loadSetting() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      setState(() {
        messagingEnabled = doc.data()?['messagingEnabled'] ?? false;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateSetting(bool value) async {
    setState(() {
      messagingEnabled = value;
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .set({
      'messagingEnabled': value,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const ListTile(
        title: Text("Enable Messaging"),
        trailing: CircularProgressIndicator(),
      );
    }

    return SwitchListTile(
      title: const Text("Enable Messaging"),
      subtitle: const Text("Allow others to message you"),
      value: messagingEnabled,
      onChanged: updateSetting,
    );
  }
}