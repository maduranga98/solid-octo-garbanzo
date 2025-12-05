# InkWing - Production Deployment Guide

This guide provides step-by-step instructions to prepare and deploy InkWing to production environments across all platforms.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Generate App Icons](#generate-app-icons)
3. [Android Production Setup](#android-production-setup)
4. [iOS Production Setup](#ios-production-setup)
5. [Web Production Setup](#web-production-setup)
6. [Firebase Configuration](#firebase-configuration)
7. [Build and Deploy](#build-and-deploy)
8. [Post-Deployment Checklist](#post-deployment-checklist)

---

## Prerequisites

Ensure you have the following installed and configured:
- Flutter SDK (stable channel)
- Android Studio with SDK tools
- Xcode (for iOS/macOS builds)
- Firebase CLI
- Node.js 22+ (for Cloud Functions)
- Active Firebase project: `poetic-platform`

---

## Generate App Icons

The app logo (`assets/inkwing-logo.jpg`) has been configured to generate icons for all platforms using `flutter_launcher_icons`.

### Steps:

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Generate icons for all platforms:**
   ```bash
   dart run flutter_launcher_icons
   ```

   This will automatically generate:
   - Android icons (all DPI variants: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
   - iOS icons (all required sizes for iPhone, iPad, and App Store)
   - Web icons (favicon, 192x192, 512x512, maskable icons)
   - macOS icons
   - Windows icons

3. **Verify generated icons:**
   - Android: `android/app/src/main/res/mipmap-*/ic_launcher.png`
   - iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
   - Web: `web/icons/` and `web/favicon.png`

---

## Android Production Setup

### 1. Create Release Keystore

Generate a keystore for signing the Android release APK/AAB:

```bash
keytool -genkey -v -keystore ~/inkwing-release-key.jks \
  -alias inkwing \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

**IMPORTANT:** Save the keystore file and passwords securely. You'll need them for all future releases.

### 2. Create Key Properties File

Create `android/key.properties` (this file is gitignored for security):

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=inkwing
storeFile=<path-to-your-keystore-file>
# Example: storeFile=/Users/yourname/inkwing-release-key.jks
```

**IMPORTANT:** Add `key.properties` to `.gitignore` to prevent committing sensitive credentials.

### 3. Build Configuration

The following production optimizations are already configured in `android/app/build.gradle.kts`:

- **Application ID:** `com.inkwing.app`
- **Code shrinking:** Enabled with ProGuard
- **Resource shrinking:** Enabled
- **Obfuscation:** Configured via `proguard-rules.pro`
- **Release signing:** Configured to use keystore from `key.properties`

### 4. Update Firebase Configuration

Ensure `android/app/google-services.json` is present and configured for the Firebase project.

If you need to update the package name:
1. Update the package name in Firebase Console
2. Download the new `google-services.json`
3. Replace the existing file in `android/app/`

### 5. Build Android Release

**Build APK:**
```bash
flutter build apk --release
```

**Build App Bundle (recommended for Play Store):**
```bash
flutter build appbundle --release
```

Output locations:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

---

## iOS Production Setup

### 1. Update Bundle Identifier

The bundle identifier has been updated to match your organization. Verify in `ios/Runner.xcodeproj`:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Verify Bundle Identifier matches your provisioning profile
4. Consider changing to: `com.inkwing.app` (currently using generated identifier)

### 2. Configure Code Signing

1. Open Xcode
2. Select your development team
3. Enable "Automatically manage signing" or configure manual signing
4. Ensure provisioning profiles are valid

### 3. Update Firebase Configuration

Ensure `ios/Runner/GoogleService-Info.plist` is present and configured for your Firebase project.

### 4. Build iOS Release

**From terminal:**
```bash
flutter build ios --release
```

**For App Store submission:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" as build target
3. Product → Archive
4. Follow Xcode's distribution wizard

---

## Web Production Setup

### 1. Configuration

Web configuration has been updated with:
- **App Name:** InkWing
- **Description:** "InkWing - Where Words Take Flight"
- **PWA Support:** Configured via `manifest.json`
- **Icons:** Will be generated automatically

### 2. Firebase Hosting Setup

The project is already configured for Firebase Hosting. Verify `firebase.json`:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"]
  }
}
```

### 3. Build and Deploy Web

**Build for production:**
```bash
flutter build web --release --web-renderer html
```

**Deploy to Firebase Hosting:**
```bash
firebase deploy --only hosting
```

**Custom domain setup:**
1. Go to Firebase Console → Hosting
2. Add custom domain
3. Follow DNS configuration instructions

---

## Firebase Configuration

### 1. Cloud Functions Setup

Cloud Functions are configured in the `functions/` directory for:
- Push notifications (FCM)
- Like notifications
- Comment notifications
- Batch notifications
- Token cleanup

**Deploy Cloud Functions:**
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### 2. Firestore Security Rules

Ensure Firestore security rules are properly configured for production:

```bash
firebase deploy --only firestore:rules
```

### 3. Firebase Authentication

Verify authentication providers are enabled in Firebase Console:
- ✅ Email/Password
- ✅ Google Sign-In

Update allowed domains in Firebase Console for web deployment.

---

## Build and Deploy

### Quick Deployment Commands

**Android:**
```bash
# Generate icons
dart run flutter_launcher_icons

# Build release
flutter build appbundle --release

# Upload to Google Play Console
# (Manual step - upload build/app/outputs/bundle/release/app-release.aab)
```

**iOS:**
```bash
# Generate icons
dart run flutter_launcher_icons

# Build release
flutter build ios --release

# Archive and upload via Xcode
open ios/Runner.xcworkspace
```

**Web:**
```bash
# Generate icons
dart run flutter_launcher_icons

# Build and deploy
flutter build web --release
firebase deploy --only hosting
```

**All Cloud Functions:**
```bash
firebase deploy --only functions
```

---

## Post-Deployment Checklist

### Before Release
- [ ] Generate all app icons: `dart run flutter_launcher_icons`
- [ ] Create Android release keystore
- [ ] Configure `android/key.properties` with keystore details
- [ ] Test Android release build on physical device
- [ ] Configure iOS code signing certificates
- [ ] Test iOS release build on physical device
- [ ] Test web build in production mode
- [ ] Deploy and test Cloud Functions
- [ ] Verify Firebase Authentication providers
- [ ] Test push notifications on all platforms
- [ ] Review and deploy Firestore security rules
- [ ] Update Privacy Policy and Terms of Service URLs
- [ ] Test Google Sign-In on all platforms
- [ ] Verify app icons appear correctly on all platforms

### Google Play Store
- [ ] Create app listing in Google Play Console
- [ ] Upload release AAB
- [ ] Add screenshots (phone, tablet, feature graphic)
- [ ] Complete content rating questionnaire
- [ ] Set up pricing and distribution
- [ ] Configure app categories and tags
- [ ] Add privacy policy URL
- [ ] Submit for review

### Apple App Store
- [ ] Create app in App Store Connect
- [ ] Upload build via Xcode or Transporter
- [ ] Add screenshots for all device sizes
- [ ] Complete app information
- [ ] Set pricing and availability
- [ ] Add privacy policy URL
- [ ] Submit for review

### Web Deployment
- [ ] Deploy to Firebase Hosting
- [ ] Configure custom domain (if applicable)
- [ ] Test PWA installation
- [ ] Verify SEO meta tags
- [ ] Test on multiple browsers
- [ ] Enable HTTPS (automatic with Firebase Hosting)

### Firebase
- [ ] Set up Firebase project billing (Blaze plan for Cloud Functions)
- [ ] Configure usage limits and alerts
- [ ] Set up Firebase Analytics
- [ ] Configure Crashlytics (optional)
- [ ] Review and optimize Firestore indexes
- [ ] Set up backup strategy for Firestore

### Security
- [ ] Review and update Firestore security rules
- [ ] Enable App Check for Firebase (recommended)
- [ ] Implement rate limiting for Cloud Functions
- [ ] Review ProGuard rules for Android
- [ ] Enable two-factor authentication for all developer accounts
- [ ] Store keystore and credentials in secure vault

### Performance
- [ ] Test app performance on low-end devices
- [ ] Optimize image loading and caching
- [ ] Monitor Cloud Functions execution time
- [ ] Set up Firebase Performance Monitoring
- [ ] Review app size and optimize if needed

---

## Important Notes

### Package Name / Bundle Identifier
- **Android:** `com.inkwing.app`
- **iOS:** Update in Xcode to match your provisioning profile
- **Web:** Domain-based (Firebase Hosting or custom domain)

### Version Management
- Current version: `1.0.0+1` (SemVer + build number)
- Update in `pubspec.yaml` for new releases
- Follow [Semantic Versioning](https://semver.org/): MAJOR.MINOR.PATCH

### Keystore Security
⚠️ **CRITICAL:** The Android keystore is required for all future updates. If lost, you cannot update the app on Google Play Store.

**Backup strategy:**
1. Store keystore file in secure cloud storage (encrypted)
2. Save passwords in password manager
3. Keep multiple secure backups
4. Document keystore location for your team

### Firebase Project
- Project ID: `poetic-platform`
- Ensure all platforms are registered in Firebase Console
- Verify Firebase configurations are correct before building

---

## Support and Resources

- **Flutter Documentation:** https://docs.flutter.dev/
- **Firebase Documentation:** https://firebase.google.com/docs
- **Android Publishing:** https://developer.android.com/studio/publish
- **iOS Publishing:** https://developer.apple.com/app-store/submissions/

---

## Troubleshooting

### Icons not generating
```bash
# Clear Flutter cache and regenerate
flutter clean
flutter pub get
dart run flutter_launcher_icons
```

### Android signing issues
- Verify `key.properties` file exists and has correct paths
- Check keystore file permissions
- Ensure keystore alias and passwords are correct

### iOS build failures
- Clean build folder in Xcode: Product → Clean Build Folder
- Update CocoaPods: `cd ios && pod install`
- Verify code signing certificates are valid

### Web deployment issues
- Ensure Firebase CLI is logged in: `firebase login`
- Verify project is selected: `firebase use poetic-platform`
- Check `firebase.json` configuration

---

**Last Updated:** 2025-11-16
**InkWing Version:** 1.0.0
**App Name:** InkWing
**Organization:** Verse Technologies
