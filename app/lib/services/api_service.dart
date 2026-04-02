import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // 10.0.2.2 points to your computer's localhost from the Android emulator
  static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<bool> uploadItem({
    required File imageFile,
    required String status,
    required String category,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("User not logged in");
        return false;
      }

      // 1. Create a unique ID for this post based on time
      final postId = 'post_${DateTime.now().millisecondsSinceEpoch}';

      // 2. Prepare the Multi-part request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload_item/'),
      );

      // 3. Add the text fields (Must match FastAPI exactly!)
      request.fields['post_id'] = postId;
      request.fields['user_id'] = user.uid;
      request.fields['status'] = status.toLowerCase(); // 'lost' or 'found'
      request.fields['category'] = category.toLowerCase(); // e.g., 'bottle'

      // 4. Attach the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      // 5. Send it to Python!
      debugPrint("Sending item to AI Backend...");
      var response = await request.send();

      if (response.statusCode == 200) {
        debugPrint("✅ Successfully uploaded to Backend!");
        return true;
      } else {
        debugPrint("❌ Backend Error: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ API Service Error: $e");
      return false;
    }
  }
}