import 'package:flutter/foundation.dart'; // Required for debugPrint
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Request Permission (Required for iOS and Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
      
      // 2. Get the unique FCM token for this device
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await saveTokenToDatabase(token);
      }

      // Listen for token refreshes
      _firebaseMessaging.onTokenRefresh.listen(saveTokenToDatabase);

      // 3. Setup Foreground Notifications
      _setupForegroundNotifications();
    }
  }

  // Save the token to the user's Firestore document
// Save the token to the user's Firestore document
  static Future<void> saveTokenToDatabase(String token) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      
      debugPrint("Attempting to save token...");
      debugPrint("Current User ID: $userId");

      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
        
        debugPrint("✅ SUCCESS: Token saved to Firestore for user: $userId");
      } else {
        debugPrint("❌ ERROR: User ID is null. Are they logged in yet?");
      }
    } catch (e) {
      debugPrint("❌ FIREBASE WRITE ERROR: $e");
    }
  }

  static void _setupForegroundNotifications() {
    const AndroidInitializationSettings androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInitSettings);
    
    // FIXED: Using the named parameter 'settings:'
    _localNotificationsPlugin.initialize(settings: initSettings);

    // This listens for messages while the app is OPEN on the screen
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      
      if (message.notification != null) {
        // FIXED: Using named parameters for the show() method
        _localNotificationsPlugin.show(
          id: message.notification!.hashCode,
          title: message.notification!.title,
          body: message.notification!.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel', // id
              'High Importance Notifications', // title
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }
}