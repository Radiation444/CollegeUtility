import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // Uncomment when you fix the .env issue
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'auth_screen.dart';
import 'profile_setup_screen.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  // await dotenv.load(fileName: ".env"); // Temporarily bypassed
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CampusUtilityApp());
}

class CampusUtilityApp extends StatelessWidget {
  const CampusUtilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus App',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          
          if (snapshot.hasData) {
            // THE ANTI-FLASH SHIELD:
            // If Firebase auto-logged them in during signup, but they aren't verified,
            // block them from going to the Gatekeeper. Keep them on the AuthScreen.
            if (!snapshot.data!.emailVerified) {
              return const AuthScreen();
            }
            
            // Verified and logged in! Send them to check for their profile.
            return const AuthGate(); 
          }
          
          return const AuthScreen();
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        // If the database document doesn't exist, they need to complete their profile!
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const ProfileSetupScreen();
        }

        // Profile exists, let them into the dashboard
        return const DashboardScreen();
      },
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride-Sharing & Lost-and-Found'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome! You are fully verified and your profile is complete.', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}