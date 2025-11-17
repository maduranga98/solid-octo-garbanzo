# VerseBox

**VerseBox** is a modern, multi-platform poetry and content sharing social platform built with Flutter. Share your verses, connect with fellow poets, and explore creative content across all devices.

## Features

- 📱 **Multi-Platform Support** - Android, iOS, Web, macOS, Windows, and Linux
- 🔐 **Secure Authentication** - Google Sign-In and Email/Password authentication via Firebase
- 📝 **Rich Text Editor** - Create beautifully formatted poetry and content using Flutter Quill
- 💬 **Social Interaction** - Like, comment, and engage with content
- 🔔 **Push Notifications** - Stay updated with real-time notifications via FCM
- 🌙 **Dark Mode** - Seamless theme switching for comfortable reading
- 💾 **Cloud Sync** - All your content synced across devices with Firestore
- 👤 **User Profiles** - Personalized profiles with custom photos
- 🔍 **Search & Discovery** - Find and follow your favorite poets
- 💾 **Save Posts** - Bookmark your favorite content for later

## Tech Stack

- **Framework:** Flutter 3.9.2+
- **State Management:** Riverpod
- **Backend:** Firebase (Firestore, Auth, Storage, Cloud Messaging)
- **Cloud Functions:** Node.js 22
- **UI Components:** Material Design 3
- **Text Editor:** Flutter Quill

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Firebase account
- Node.js 22+ (for Cloud Functions)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/maduranga98/solid-octo-garbanzo.git
   cd solid-octo-garbanzo
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate app icons:**
   ```bash
   dart run flutter_launcher_icons
   ```

4. **Set up Firebase:**
   - Create a Firebase project
   - Add your platform-specific configuration files:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`
     - Web: Update `lib/firebase_options.dart`

5. **Configure environment variables:**
   - Create a `.env` file in the root directory
   - Add required environment variables

6. **Run the app:**
   ```bash
   flutter run
   ```

## 🔒 Security & Production Deployment

VerseBox implements comprehensive security measures to protect user data:

- ✅ **Firestore Security Rules** - Database access control and validation
- ✅ **Storage Security Rules** - File upload protection (10MB limit, images only)
- ✅ **Authenticated Cloud Functions** - Server-side authentication and input validation
- ✅ **API Key Protection** - Environment variable configuration
- ✅ **Input Validation** - Client and server-side data validation
- ✅ **Production Logging** - Secure logging with sensitive data redaction

### 📚 Documentation

- **[DEPLOY.md](DEPLOY.md)** - Quick deployment commands and procedures
- **[PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md)** - Complete pre-launch checklist
- **[SECURITY_GUIDE.md](SECURITY_GUIDE.md)** - Security features and best practices
- **[PRODUCTION_DEPLOYMENT_GUIDE.md](PRODUCTION_DEPLOYMENT_GUIDE.md)** - Detailed deployment guide

### 🚀 Quick Deployment

**Deploy Firebase Security Rules (CRITICAL - Do This First!):**
```bash
firebase deploy --only firestore:rules,storage
```

**Deploy Cloud Functions:**
```bash
firebase deploy --only functions
```

**Build Apps:**

**Android:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

**Web:**
```bash
flutter build web --release
firebase deploy --only hosting
```

**⚠️ Important**: Review `PRODUCTION_CHECKLIST.md` before deploying to production!

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/
│   ├── theme.dart            # Material Design 3 theme configuration
│   └── app_config.dart       # Production settings & logging utility
├── models/                   # Data models (User, Post, Comment, etc.)
├── providers/                # Riverpod state providers
├── repositories/             # Data access layer
├── services/                 # Business logic (auth, notifications, etc.)
├── screens/                  # UI screens
└── widgets/                  # Reusable UI components

functions/                    # Firebase Cloud Functions (Node.js 22)
├── index.js                  # Cloud Functions with authentication
└── package.json

# Firebase Configuration
firebase.json                 # Firebase project configuration
firestore.rules               # Database security rules
storage.rules                 # File storage security rules
firestore.indexes.json        # Firestore composite indexes

# Documentation
DEPLOY.md                     # Quick deployment guide
PRODUCTION_CHECKLIST.md       # Pre-launch checklist
SECURITY_GUIDE.md             # Security features and best practices
.env.example                  # Environment variables template
```

## Firebase Services

### Cloud Functions (Production-Ready with Authentication)

All Cloud Functions now include:
- ✅ User authentication required
- ✅ Input validation and sanitization
- ✅ Rate limiting (500 token batch limit)
- ✅ Proper error handling with `HttpsError`

**Available Functions:**
- `sendLikeNotification` - Auto-triggered when a post is liked
- `sendCommentNotification` - Auto-triggered when a post receives a comment
- `sendNotification` - Send individual push notifications (authenticated)
- `sendBatchNotifications` - Send bulk notifications (authenticated, rate-limited)
- `cleanupFCMToken` - Cleanup tokens on user deletion

### Deploy Cloud Functions
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### Security Rules

**Firestore Rules** protect:
- User documents (only owner can modify)
- Posts (only author can edit/delete)
- Likes, comments, bookmarks (authenticated users only)
- Input validation (username format, content length, etc.)

**Storage Rules** enforce:
- Authentication required for all uploads
- Image files only (jpg, png, gif, webp)
- 10MB maximum file size
- User-specific folder isolation

Deploy rules:
```bash
firebase deploy --only firestore:rules,storage
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and feature requests, please use the GitHub issue tracker.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Open source community for various packages used in this project

---

**Version:** 1.0.0
**Last Updated:** 2025-11-17
**Status:** Production-Ready with Security Rules ✅
