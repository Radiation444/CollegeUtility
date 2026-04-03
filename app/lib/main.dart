import 'ride_share_feed.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'auth_screen.dart';
import 'lost_found_feed.dart';
import 'profile_setup_screen.dart'; 
import 'profile_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const CampusUtilityApp());
}
class CampusUtilityApp extends StatefulWidget {
  const CampusUtilityApp({super.key});

  @override
  State<CampusUtilityApp> createState() => _CampusUtilityAppState();
}

class _CampusUtilityAppState extends State<CampusUtilityApp> {
  
  @override
  void initState() {
    super.initState();
    // THIS IS THE MISSING PIECE!
    // As soon as the app boots, ask for permissions and get the token.
    NotificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Campus Hub'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        leading: const Icon(Icons.home),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'My Profile',
            onPressed: (){
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              if (currentUserId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(userId: currentUserId)),
                );
              }
            },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What do you need today?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Feature Card 1: Ride Sharing
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RideShareFeed()),
                    );                    
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car_filled, size: 64, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 16),
                        const Text('Ride Sharing', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Find or offer a ride to the station/airport.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Feature Card 2: Lost & Found
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LostFoundFeed()),
                    );                    
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_rounded, size: 64, color: Colors.orange[400]),
                        const SizedBox(height: 16),
                        const Text('Lost & Found', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Report a lost item or help return one.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      ],
                    ),
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