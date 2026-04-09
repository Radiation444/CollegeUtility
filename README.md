
                        COLLEGE UTILITY APP
                   A Comprehensive Campus Mobile Platform

PROJECT OVERVIEW
----------------
Name        : College Utility App
Type        : Mobile Application
Stack       : Flutter + Firebase
Language    : Dart

The College Utility App is a comprehensive campus utility platform designed to
streamline student interactions, improve communication, and provide essential
campus services in a single mobile application.

The application solves common problems faced by students, including:
  - Lost & found item management
  - Lack of direct communication between students
  - Difficulty contacting item owners
  - Fragmented campus communication channels
  - Lack of centralized student utilities

The app provides a real-time, scalable, and user-friendly platform that
integrates multiple utilities commonly required in a college environment.


CORE FEATURES


1. LOST & FOUND SYSTEM
-----------------------
The Lost & Found system is one of the primary features of the application.

Capabilities:
  - Post lost items
  - Post found items
  - Upload multiple images
  - Add item description, category, and attributes
  - Add date & time of loss/found
  - Add location
  - Mark item status: Lost / Found / Closed

Each Post Includes:
  - Title
  - Item Name & Type
  - Description
  - Location
  - Date & Time
  - Status (Lost / Found / Closed)
  - Multiple Images
  - Poster User ID & Name
  - Timestamp
  - Custom Attributes (JSON map)

--------------------------------------------------------------------------------

2. CONTACT POSTER FEATURE
--------------------------
Users can directly contact the poster of any lost or found item.

Flow:
  User views post
    Clicks "Contact Poster"
    Chat screen opens
    User starts conversation

Benefits:
  - Improved communication efficiency
  - Faster item recovery
  - Increased user engagement

--------------------------------------------------------------------------------

3. REAL-TIME CHAT SYSTEM
-------------------------
A full real-time one-to-one messaging system is built into the app.

Chat Features:
  - One-to-one messaging
  - Real-time message updates via Firebase
  - Image messaging support
  - Message timestamps
  - Sender/receiver differentiation
  - Auto-scroll to latest message
  - Direct chat with Lost & Found posters
  - Full-screen image viewer

Chat UI:
  - Message bubbles with left/right alignment
  - Avatar display
  - Timestamp display
  - Scrollable message history

--------------------------------------------------------------------------------

4. IMAGE MESSAGING
-------------------
Users can send images within chat conversations.

Supported:
  - Mobile image picker
  - Web image picker (via FilePicker)
  - Firebase Storage upload
  - In-chat image preview
  - Full-screen image viewer

--------------------------------------------------------------------------------

5. USER PROFILE SYSTEM
-----------------------
Users can view profiles of post authors and other students.

Features:
  - Navigate to any user's profile
  - View user's posts
  - View user details
  - Avatar display

--------------------------------------------------------------------------------

6. MY POSTS SCREEN
-------------------
Users can manage their own contributions to the platform.

Features:
  - View personal lost posts
  - View personal found posts
  - Easy post management and tracking

================================================================================
TECHNICAL ARCHITECTURE
================================================================================

FRONTEND
--------
  Framework : Flutter
  Language  : Dart

  Folder Structure (Feature-Based):

    lib/
    ├── features/
    │   ├── chat/
    │   ├── lost_found/
    │   └── profile/
    ├── models/
    ├── services/
    └── widgets/

BACKEND  FIREBASE SERVICES
-----------------------------

  Firebase Authentication
    - User login & registration
    - User identity management
    - User ID management

  Cloud Firestore
    Collections:
      - lost_found_posts   Stores all lost & found post data
      - messages           Stores real-time chat messages
      - users              Stores user profile information

  Firebase Storage
    Storage Structure:
      - chatImages/          Images sent in chat conversations
      - lostFoundImages/     Images uploaded with lost & found posts

================================================================================
GETTING STARTED
================================================================================

PREREQUISITES
  - Flutter SDK (latest stable version)
  - Dart SDK
  - Firebase project set up (Authentication, Firestore, Storage enabled)
  - Android Studio / VS Code with Flutter plugin
  - Android or iOS device / emulator

INSTALLATION

  1. Clone the repository:
       git clone <repository-url>
       cd college-utility-app

  2. Install dependencies:
       flutter pub get

  3. Configure Firebase:
       - Add your google-services.json to android/app/
       - Add your GoogleService-Info.plist to ios/Runner/
       - Update Firebase config in lib/firebase_options.dart

  4. Run the application:
       flutter run

================================================================================
FIREBASE SECURITY RULES (Recommended)
================================================================================

  Firestore:
    - Authenticated users can read/write their own documents
    - Lost & Found posts are readable by all authenticated users

  Storage:
    - Only authenticated users can upload images
    - Images are publicly readable within the app context

================================================================================
CONTRIBUTING
================================================================================

  1. Fork the repository
  2. Create a feature branch:  git checkout -b feature/your-feature-name
  3. Commit your changes:       git commit -m "Add: your feature description"
  4. Push to branch:            git push origin feature/your-feature-name
  5. Open a Pull Request

================================================================================
LICENSE
================================================================================

  This project is intended for educational and campus use.
  Please refer to the LICENSE file for full terms and conditions.

================================================================================
CONTACT
================================================================================

  For questions, issues, or contributions, please open an issue in the
  project repository or contact the development team.

================================================================================
                     Built with Flutter & Firebase
                     Empowering Campus Life, One Feature at a Time
================================================================================
