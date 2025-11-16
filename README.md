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

## Building for Production

Detailed production deployment instructions are available in [PRODUCTION_DEPLOYMENT_GUIDE.md](PRODUCTION_DEPLOYMENT_GUIDE.md).

### Quick Build Commands

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

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/                   # App configuration (theme, etc.)
├── models/                   # Data models
├── providers/                # Riverpod state providers
├── repositories/             # Data access layer
├── services/                 # Business logic (auth, notifications, etc.)
├── screens/                  # UI screens
└── widgets/                  # Reusable UI components

functions/                    # Firebase Cloud Functions
android/                      # Android platform files
ios/                          # iOS platform files
web/                          # Web platform files
```

## Firebase Services

### Cloud Functions
- `sendLikeNotification` - Triggered when a post is liked
- `sendCommentNotification` - Triggered when a post receives a comment
- `sendNotification` - Send individual notifications
- `sendBatchNotifications` - Send bulk notifications
- `cleanupFCMToken` - Cleanup tokens on user deletion

### Deploy Cloud Functions
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
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
**Last Updated:** 2025-11-16
