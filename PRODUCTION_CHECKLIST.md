# Production Deployment Checklist for InkWing

This comprehensive checklist ensures your InkWing application is production-ready and secure.

## 🔐 Security (CRITICAL)

### Firebase Security Rules
- [x] **Firestore Security Rules** - Created in `firestore.rules`
  - Deploy: `firebase deploy --only firestore:rules`
  - Validates user authentication and data ownership
  - Prevents unauthorized access to user data and posts

- [x] **Firebase Storage Rules** - Created in `storage.rules`
  - Deploy: `firebase deploy --only storage`
  - Restricts file uploads to authenticated users
  - Enforces 10MB file size limit
  - Validates image file types only

- [ ] **Deploy Security Rules to Firebase**
  ```bash
  firebase deploy --only firestore:rules,storage
  ```

### Authentication & Authorization
- [ ] **Enable Email Verification** (Optional but Recommended)
  - Update `lib/config/app_config.dart`: Set `requireEmailVerification = true`
  - Configure email templates in Firebase Console

- [ ] **Configure Password Requirements**
  - Minimum 8 characters (already set in `AppConfig`)
  - Consider requiring special characters

- [ ] **Review OAuth Consent Screen**
  - Configure in Google Cloud Console
  - Add privacy policy and terms of service URLs
  - Restrict to authorized domains

### API Keys & Environment Variables
- [ ] **Secure Environment Variables**
  - ✅ `.env` file is in `.gitignore`
  - [ ] Create production `.env` file with real credentials
  - [ ] Validate all required variables are set:
    ```bash
    # Check .env.example for required variables
    cat .env.example
    ```

- [ ] **Restrict API Keys** (Firebase Console)
  - Go to Google Cloud Console → Credentials
  - Restrict Android API key to your app's SHA-1 fingerprint
  - Restrict iOS API key to your bundle identifier
  - Restrict Web API key to your domain(s)

### Cloud Functions Security
- [x] **Authentication Added** - All callable functions now require authentication
- [x] **Input Validation** - Sanitization and validation implemented
- [x] **Rate Limiting** - Batch size limited to 500 tokens
- [ ] **Deploy Updated Functions**
  ```bash
  cd functions
  npm install
  cd ..
  firebase deploy --only functions
  ```

### App Security
- [ ] **Enable Firebase App Check** (Highly Recommended)
  ```bash
  # Add to pubspec.yaml
  firebase_app_check: ^0.2.1+0

  # Initialize in main.dart
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );
  ```

- [ ] **Review Data Privacy**
  - Ensure GDPR compliance if targeting EU users
  - Add data deletion capability for users
  - Implement data export functionality

## 🔧 Configuration

### Firebase Project Setup
- [ ] **Upgrade Firebase Project to Blaze Plan** (Required for Cloud Functions)
- [ ] **Enable Required APIs**
  - Cloud Firestore API
  - Firebase Authentication
  - Firebase Cloud Messaging API
  - Cloud Storage for Firebase
  - Cloud Functions API

- [ ] **Configure Firebase Indexes**
  - Deploy indexes: `firebase deploy --only firestore:indexes`
  - Monitor index creation in Firebase Console

### Application Configuration
- [ ] **Update App Version** in `pubspec.yaml`
  - Increment version number (e.g., 1.0.0+1 → 1.0.1+2)

- [ ] **Set Production Mode**
  - Build in release mode (automatic when using `--release` flag)
  - Verify `AppConfig.isProduction` returns true in release builds

- [ ] **Configure Logging**
  - Review `lib/config/app_config.dart`
  - Ensure debug logs are disabled in production
  - Set up crash reporting (optional)

### Platform-Specific Configuration

#### Android
- [ ] **Generate Release Keystore**
  ```bash
  keytool -genkey -v -keystore ~/versebox-release-key.jks \
    -keyalg RSA -keysize 2048 -validity 10000 -alias versebox
  ```

- [ ] **Configure Signing** in `android/key.properties`
  ```properties
  storePassword=<your-password>
  keyPassword=<your-password>
  keyAlias=versebox
  storeFile=<path-to-jks-file>
  ```
  ⚠️ **Never commit `key.properties` to Git**

- [ ] **Update App Permissions** in `android/app/src/main/AndroidManifest.xml`
  - Remove unused permissions
  - Ensure `INTERNET` permission is present
  - Add `POST_NOTIFICATIONS` permission for Android 13+

- [ ] **Configure ProGuard** (for code obfuscation)
  - Already configured in `android/app/build.gradle`
  - Test thoroughly after enabling

#### iOS
- [ ] **Configure Bundle Identifier**
  - Update in `ios/Runner.xcodeproj`
  - Should match Firebase iOS app

- [ ] **Set up Push Notifications Certificate**
  - Create APNs certificate in Apple Developer Console
  - Upload to Firebase Console → Project Settings → Cloud Messaging

- [ ] **Update Info.plist Permissions**
  - Camera access description
  - Photo library access description
  - Notification permission description

#### Web
- [ ] **Configure Firebase Hosting** (if deploying web)
  ```bash
  flutter build web --release
  firebase deploy --only hosting
  ```

- [ ] **Update CORS Settings** for Firebase Storage
  - Create `cors.json`:
    ```json
    [
      {
        "origin": ["https://your-domain.com"],
        "method": ["GET"],
        "maxAgeSeconds": 3600
      }
    ]
    ```
  - Apply: `gsutil cors set cors.json gs://your-bucket-name`

## 📊 Monitoring & Analytics

- [ ] **Enable Firebase Analytics**
  - Already included in dependencies
  - Events logged automatically

- [ ] **Set up Firebase Crashlytics** (Recommended)
  ```yaml
  # Add to pubspec.yaml
  firebase_crashlytics: ^3.4.0
  ```

- [ ] **Configure Performance Monitoring**
  ```yaml
  firebase_performance: ^0.9.3+0
  ```

- [ ] **Set up Usage Alerts** in Firebase Console
  - Database read/write alerts
  - Storage usage alerts
  - Cloud Functions invocation alerts
  - Budget alerts in Google Cloud Console

## 🧪 Testing

- [ ] **Test Authentication Flows**
  - [x] Email/password signup
  - [x] Email/password login
  - [x] Google Sign-In
  - [x] Password reset
  - [ ] Account deletion

- [ ] **Test Core Features**
  - [ ] Create post
  - [ ] Edit post
  - [ ] Delete post
  - [ ] Like/unlike post
  - [ ] Comment on post
  - [ ] Follow/unfollow user
  - [ ] Search users
  - [ ] Bookmark posts
  - [ ] Receive notifications

- [ ] **Test Security Rules**
  ```bash
  # Use Firebase Emulator for local testing
  firebase emulators:start --only firestore,storage
  ```
  - Verify users can only edit their own data
  - Verify users can only delete their own content
  - Test unauthorized access attempts

- [ ] **Performance Testing**
  - Test with slow network conditions
  - Test with large datasets
  - Monitor memory usage
  - Check image loading performance

- [ ] **Cross-Platform Testing**
  - [ ] Test on Android (multiple versions)
  - [ ] Test on iOS (multiple versions)
  - [ ] Test on Web browsers
  - [ ] Test on different screen sizes

## 🚀 Build & Release

### Android Release
- [ ] **Build Release APK/AAB**
  ```bash
  flutter build apk --release
  # or for Google Play
  flutter build appbundle --release
  ```

- [ ] **Test Release Build**
  ```bash
  flutter install --release
  ```

- [ ] **Prepare Play Store Listing**
  - App screenshots
  - Feature graphic
  - App description
  - Privacy policy URL
  - Content rating questionnaire

### iOS Release
- [ ] **Build iOS Release**
  ```bash
  flutter build ios --release
  ```

- [ ] **Archive in Xcode**
  - Open `ios/Runner.xcworkspace` in Xcode
  - Product → Archive
  - Upload to App Store Connect

- [ ] **Prepare App Store Listing**
  - App preview videos
  - Screenshots for all device sizes
  - App description
  - Keywords
  - Privacy policy URL

### Web Release
- [ ] **Build Web Release**
  ```bash
  flutter build web --release
  firebase deploy --only hosting
  ```

## 📝 Legal & Compliance

- [ ] **Create Privacy Policy**
  - Explain data collection and usage
  - GDPR compliance if targeting EU
  - Link from app and store listings

- [ ] **Create Terms of Service**
  - User responsibilities
  - Content guidelines
  - Account termination policy

- [ ] **Add In-App Links**
  - Privacy policy
  - Terms of service
  - Contact/support information
  - Attribution for third-party libraries

## 🔄 Post-Deployment

- [ ] **Monitor Firebase Console**
  - Check for errors in Cloud Functions logs
  - Monitor Firestore usage
  - Review authentication activity

- [ ] **Set up Automated Backups**
  - Configure daily Firestore exports
  - Set up Storage bucket versioning

- [ ] **Create Rollback Plan**
  - Document rollback procedures
  - Keep previous version builds
  - Have database backup ready

- [ ] **User Feedback Channel**
  - Set up support email
  - Monitor app store reviews
  - Create feedback form in app

## 📋 Environment-Specific Tasks

### Development Environment
- ✅ `.env` file with development credentials
- ✅ Firebase Emulators for local testing (optional)
- ✅ Debug logging enabled

### Staging Environment (Optional but Recommended)
- [ ] Separate Firebase project for staging
- [ ] Staging `.env` file
- [ ] Limited logging
- [ ] Real Firebase services (not emulators)

### Production Environment
- [ ] Production `.env` file with real credentials
- [ ] Debug logging disabled (automatic in release mode)
- [ ] All Firebase services properly configured
- [ ] Security rules deployed and tested
- [ ] Monitoring and alerts configured

## 🎯 Critical Pre-Launch Tasks

**DO NOT LAUNCH WITHOUT COMPLETING THESE:**

1. ✅ Deploy Firestore security rules
2. ✅ Deploy Storage security rules
3. ✅ Deploy updated Cloud Functions with authentication
4. [ ] Restrict Firebase API keys to your apps/domains
5. [ ] Test all security rules thoroughly
6. [ ] Enable Firebase App Check
7. [ ] Set up monitoring and alerts
8. [ ] Test the complete app in release mode
9. [ ] Have privacy policy and terms of service ready
10. [ ] Create backup and rollback plan

## 📞 Support & Resources

- **Firebase Documentation**: https://firebase.google.com/docs
- **Flutter Documentation**: https://docs.flutter.dev
- **Firebase Console**: https://console.firebase.google.com
- **Google Cloud Console**: https://console.cloud.google.com

---

**Last Updated**: 2025-11-17
**Version**: 1.0.0

Use this checklist before every production deployment to ensure nothing is missed!
