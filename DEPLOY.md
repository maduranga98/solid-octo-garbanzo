# Quick Deployment Guide for InkWing

This guide provides the essential commands to deploy InkWing to production.

## 📋 Prerequisites

Before deploying, ensure you have:

- [x] Firebase CLI installed: `npm install -g firebase-tools`
- [x] Logged in to Firebase: `firebase login`
- [x] Project configured: `firebase use poetic-platform`
- [ ] Production `.env` file created with real credentials
- [ ] All items in `PRODUCTION_CHECKLIST.md` completed

## 🚀 Deployment Commands

### 1. Deploy Security Rules (CRITICAL - Do This First!)

```bash
# Deploy Firestore and Storage security rules
firebase deploy --only firestore:rules,storage
```

**What this does:**
- Deploys `firestore.rules` to protect your database
- Deploys `storage.rules` to protect file uploads
- **Critical**: Without this, your data is publicly accessible!

**Verification:**
```bash
# Check deployment status
firebase deploy --only firestore:rules,storage --dry-run
```

### 2. Deploy Firestore Indexes

```bash
# Deploy composite indexes for efficient queries
firebase deploy --only firestore:indexes
```

**What this does:**
- Creates indexes defined in `firestore.indexes.json`
- Improves query performance
- May take several minutes to build

### 3. Deploy Cloud Functions

```bash
# Navigate to functions directory
cd functions

# Install dependencies (if not already done)
npm install

# Return to project root
cd ..

# Deploy all Cloud Functions
firebase deploy --only functions
```

**What this does:**
- Deploys updated Cloud Functions with authentication
- Functions deployed:
  - `sendNotification` - Individual push notifications
  - `sendLikeNotification` - Auto-triggered on likes
  - `sendCommentNotification` - Auto-triggered on comments
  - `sendBatchNotifications` - Batch notifications
  - `cleanupFCMToken` - User deletion cleanup

**Individual function deployment** (if needed):
```bash
firebase deploy --only functions:sendNotification
```

### 4. Deploy Web Hosting (Optional)

If deploying the web version:

```bash
# Build the web app
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

### 5. Deploy Everything at Once

```bash
# Deploy all Firebase services
firebase deploy
```

**Warning**: This deploys all services. Use individual commands for targeted updates.

## 🔍 Verify Deployment

### Check Firestore Rules

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `poetic-platform`
3. Navigate to **Firestore Database** → **Rules**
4. Verify rules are active (not default deny/allow all)

### Check Storage Rules

1. In Firebase Console, go to **Storage** → **Rules**
2. Verify rules match `storage.rules` file

### Check Cloud Functions

1. In Firebase Console, go to **Functions**
2. Verify all 5 functions are deployed
3. Check recent logs for errors

### Test Security

```bash
# Use Firebase Emulators for local testing
firebase emulators:start
```

Test scenarios:
- [x] Unauthenticated users cannot read/write data
- [x] Users can only modify their own data
- [x] Users can create posts
- [x] Users can like and comment on posts

## 🏗️ Build Mobile Apps

### Android

```bash
# Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk

# Or build App Bundle for Play Store
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

**Install and test:**
```bash
flutter install --release
```

**Sign the app** (required for Play Store):
1. Generate keystore (if not already done):
   ```bash
   keytool -genkey -v -keystore ~/versebox-release-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias versebox
   ```

2. Create `android/key.properties`:
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=versebox
   storeFile=/path/to/versebox-release-key.jks
   ```

3. Rebuild:
   ```bash
   flutter build appbundle --release
   ```

### iOS

```bash
# Build iOS release
flutter build ios --release
```

**Then in Xcode:**
1. Open `ios/Runner.xcworkspace`
2. Select "Any iOS Device" as target
3. Product → Archive
4. Upload to App Store Connect

### Web

```bash
# Build web release
flutter build web --release

# Output: build/web/

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

## 🔒 Security Pre-Deployment Checklist

**CRITICAL - Complete before deploying:**

- [ ] ✅ Firestore rules deployed
- [ ] ✅ Storage rules deployed
- [ ] ✅ Cloud Functions deployed with authentication
- [ ] ⚠️ Firebase API keys restricted (Google Cloud Console)
- [ ] ⚠️ Production `.env` file configured
- [ ] ⚠️ Email verification enabled (optional)
- [ ] ⚠️ Privacy policy and terms of service ready
- [ ] ⚠️ Firebase App Check enabled (recommended)

## 📊 Post-Deployment Monitoring

### Check Firebase Console

1. **Authentication**
   - Monitor user signups
   - Check for unusual patterns

2. **Firestore Database**
   - Monitor read/write operations
   - Check usage quotas

3. **Cloud Functions**
   - View logs for errors
   - Monitor invocation counts

4. **Usage & Billing**
   - Set up budget alerts
   - Monitor costs

### Set Up Alerts

```bash
# In Google Cloud Console, set up:
# - Budget alerts
# - Error rate alerts for Cloud Functions
# - Firestore usage alerts
```

## 🔄 Rollback Procedures

### Rollback Firestore Rules

```bash
# View previous rule versions
firebase firestore:rules:list

# Rollback to specific version
firebase firestore:rules:release <ruleset-id>
```

### Rollback Cloud Functions

```bash
# Functions automatically keep previous versions
# Rollback via Firebase Console:
# Functions → Select function → Version History → Rollback
```

### Rollback App Version

- **Android**: Release previous version in Play Console
- **iOS**: Remove current version from App Store Connect
- **Web**: Redeploy previous build

## 🆘 Emergency Procedures

### If security breach detected:

1. **Immediate lockdown:**
   ```bash
   # Deploy deny-all rules temporarily
   # Edit firestore.rules to deny all access
   firebase deploy --only firestore:rules
   ```

2. **Investigate:**
   - Check Cloud Functions logs
   - Review Firestore activity
   - Identify compromised accounts

3. **Fix and redeploy:**
   ```bash
   # After fixing security issue
   firebase deploy --only firestore:rules,functions
   ```

### If Cloud Functions failing:

1. **Check logs:**
   ```bash
   firebase functions:log
   ```

2. **Disable problematic function:**
   - In Firebase Console, delete the function temporarily

3. **Fix and redeploy:**
   ```bash
   firebase deploy --only functions:functionName
   ```

## 📞 Deployment Support

### Firebase CLI Commands

```bash
# Check Firebase CLI version
firebase --version

# Login to Firebase
firebase login

# List available projects
firebase projects:list

# Use specific project
firebase use poetic-platform

# Get current project
firebase use

# View help
firebase --help
firebase deploy --help
```

### Useful Links

- **Firebase Console**: https://console.firebase.google.com/
- **Google Cloud Console**: https://console.cloud.google.com/
- **Firebase CLI Docs**: https://firebase.google.com/docs/cli
- **Flutter Build Docs**: https://docs.flutter.dev/deployment

## 📝 Deployment Log Template

Keep a record of your deployments:

```
Date: 2025-11-17
Version: 1.0.0
Deployed By: [Your Name]
Services Deployed:
  - [x] Firestore Rules
  - [x] Storage Rules
  - [x] Cloud Functions
  - [ ] Hosting
  - [ ] Android App
  - [ ] iOS App

Notes:
- Initial production deployment
- All security rules in place
- Tested authentication flows
- Monitoring enabled

Issues:
- None

Next Steps:
- Monitor for 24 hours
- Prepare marketing launch
```

---

**Need help?** Review `PRODUCTION_CHECKLIST.md` and `SECURITY_GUIDE.md` for detailed information.

**Version:** 1.0.0
**Last Updated:** 2025-11-17
