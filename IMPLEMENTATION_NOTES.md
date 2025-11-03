# Implementation Notes - Auth & Push Notifications

## Overview
This document outlines the implementation of Google Sign-In authentication and Firebase Cloud Messaging (FCM) push notifications for the Poetic Platform application.

## ✅ Completed Features

### 1. Google Sign-In Implementation

#### What was implemented:
- ✅ Full Google OAuth authentication flow
- ✅ User data collection screen for new Google users
- ✅ Automatic user document creation in Firestore
- ✅ Smart routing based on user existence in database

#### Files Modified/Created:
- **lib/services/auth_service.dart**: Implemented complete Google sign-in flow
- **lib/screens/auth/login.dart**: Added Google sign-in button handler with user existence check
- **lib/screens/auth/google_user_info_screen.dart**: NEW - Multi-step form to collect additional user data
- **lib/main.dart**: Updated AuthWrapper to check Firestore user document existence

#### How it works:
1. User clicks "Sign in with Google" button
2. Google authentication dialog appears
3. After successful authentication:
   - System checks if user document exists in Firestore
   - **If exists**: User is redirected to Home Screen (returning user)
   - **If not exists**: User is redirected to GoogleUserInfoScreen to complete profile (new user)
4. New users complete profile by providing:
   - Username (with availability check)
   - Country
   - Content types (Poetry, Lyrics, Stories, Quotes, Microfiction)
   - Profile photo (optional)
5. Profile is saved to Firestore and user is redirected to preferences intro screen

---

### 2. Firebase Cloud Messaging (FCM) Implementation

#### What was implemented:
- ✅ FCM service for managing device tokens and notifications
- ✅ Device token collection during user registration
- ✅ Push notifications for likes on posts
- ✅ Push notifications for comments on posts
- ✅ Token refresh handling
- ✅ Background notification handling

#### Files Modified/Created:
- **lib/services/fcm_service.dart**: NEW - Complete FCM service implementation
- **lib/providers/fcm_provider.dart**: NEW - Riverpod providers for FCM
- **lib/models/user_model.dart**: Added `fcmToken` field
- **lib/services/post_interaction_service.dart**: Added push notification on like
- **lib/repositories/comments_repository.dart**: Added push notification on comment
- **lib/screens/auth/signup.dart**: Added FCM token collection during email/password signup
- **lib/screens/auth/google_user_info_screen.dart**: Added FCM token collection during Google signup
- **lib/main.dart**: Added FCM background message handler initialization
- **pubspec.yaml**: Added `firebase_messaging` and `http` dependencies

#### How it works:
1. **During Registration**:
   - FCM service is initialized
   - Device token is requested and obtained
   - Token is stored in user document in Firestore
   - Token refresh listener is set up

2. **When Someone Likes a Post**:
   - In-app notification is created (existing functionality)
   - Push notification is sent to post owner's device (NEW)
   - Notification includes liker's name and post title

3. **When Someone Comments on a Post**:
   - In-app notification is created (existing functionality)
   - Push notification is sent to post owner's device (NEW)
   - Notification includes commenter's name, post title, and comment preview

4. **Token Management**:
   - Token is automatically refreshed when needed
   - Updated token is saved to Firestore
   - Token is deleted on user sign-out

---

## 📋 Database Schema Changes

### UserModel Updates
```dart
class UserModel {
  // Existing fields...
  final String? fcmToken; // NEW - FCM device token for push notifications
}
```

**Firestore Document Structure:**
```
users/{userId}/
  ├── fcmToken: String (nullable)
  ├── firstname: String
  ├── lastname: String
  ├── email: String
  ├── userName: String
  ├── ... (other existing fields)
```

---

## 🔧 Configuration Required

### For Google Sign-In to Work:

#### Android:
1. Add SHA-1 and SHA-256 fingerprints to Firebase Console
2. Download updated `google-services.json` and place in `android/app/`
3. Ensure package name matches in Firebase Console

#### iOS:
1. Add `GoogleService-Info.plist` to iOS project
2. Add URL schemes in `Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeRole</key>
       <string>Editor</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
       </array>
     </dict>
   </array>
   ```
3. Whitelist Google servers in `Info.plist`

### For FCM Push Notifications to Work:

#### Backend Setup Required:
⚠️ **IMPORTANT**: The current implementation logs notification details but doesn't actually send them. You need to set up a backend service or Firebase Cloud Function to send notifications.

#### Option 1: Firebase Cloud Functions (Recommended)
Create a Cloud Function to send notifications:

```javascript
// Firebase Cloud Function (Node.js)
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.https.onCall(async (data, context) => {
  const { token, title, body, data: notificationData } = data;

  const message = {
    notification: { title, body },
    data: notificationData || {},
    token: token,
  };

  try {
    const response = await admin.messaging().send(message);
    return { success: true, response };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Trigger on like creation
exports.sendLikeNotification = functions.firestore
  .document('posts/{postId}/likes/{userId}')
  .onCreate(async (snap, context) => {
    // Get post owner's FCM token
    // Send notification
  });

// Trigger on comment creation
exports.sendCommentNotification = functions.firestore
  .document('posts/{postId}/comments/{commentId}')
  .onCreate(async (snap, context) => {
    // Get post owner's FCM token
    // Send notification
  });
```

#### Option 2: Custom Backend Server
Create a backend API endpoint that:
1. Accepts notification requests from the app
2. Uses Firebase Admin SDK to send notifications
3. Handles token validation and error cases

#### Android Configuration:
1. Notification icon: Place notification icon in `android/app/src/main/res/drawable/`
2. Add to `AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.firebase.messaging.default_notification_icon"
       android:resource="@drawable/ic_notification" />
   <meta-data
       android:name="com.google.firebase.messaging.default_notification_color"
       android:resource="@color/colorPrimary" />
   ```

#### iOS Configuration:
1. Enable Push Notifications capability in Xcode
2. Upload APNs authentication key to Firebase Console
3. Add background modes in `Info.plist`:
   ```xml
   <key>UIBackgroundModes</key>
   <array>
     <string>fetch</string>
     <string>remote-notification</string>
   </array>
   ```

---

## 🔄 User Flows

### Email/Password Registration Flow (Updated):
```
1. User fills registration form
   ├── Personal info (name, username, email, password)
   ├── Country selection
   ├── Content type selection
   └── Profile photo (optional)
2. FCM token is requested and obtained
3. User account is created in Firebase Auth
4. User document is created in Firestore (with FCM token)
5. FCM token refresh listener is started
6. User is redirected to preferences intro screen
7. User is redirected to home screen
```

### Google Sign-In Flow (New):
```
1. User clicks "Sign in with Google"
2. Google authentication dialog
3. Check if user exists in Firestore
   ├── If YES: Redirect to Home Screen
   └── If NO: Redirect to GoogleUserInfoScreen
       ├── Step 1: Username selection
       ├── Step 2: Country & Content types
       ├── Step 3: Profile photo (optional)
       ├── FCM token is requested
       ├── User document is created in Firestore
       ├── FCM token refresh listener is started
       └── Redirect to preferences intro screen
```

### Notification Flow:
```
LIKE:
1. User A likes User B's post
2. Like is recorded in Firestore
3. In-app notification is created for User B
4. FCM service sends push notification to User B's device
5. User B sees notification on their device

COMMENT:
1. User A comments on User B's post
2. Comment is saved in Firestore
3. In-app notification is created for User B
4. FCM service sends push notification to User B's device
5. User B sees notification on their device
```

---

## 🧪 Testing Checklist

### Google Sign-In Testing:
- [ ] Test with new Google account (should show user info screen)
- [ ] Test with existing Google account (should go directly to home)
- [ ] Test username availability check
- [ ] Test country selection
- [ ] Test content type selection
- [ ] Test profile photo upload
- [ ] Test canceling Google sign-in
- [ ] Test with account that has no profile picture
- [ ] Test with account that has no display name

### FCM Testing:
- [ ] Test token generation on signup
- [ ] Test token storage in Firestore
- [ ] Test notification permission request
- [ ] Test foreground notifications
- [ ] Test background notifications
- [ ] Test notification tap handling
- [ ] Test token refresh
- [ ] Test notifications on post like
- [ ] Test notifications on post comment
- [ ] Test that users don't get notifications for their own actions

---

## 📝 Known Limitations

1. **Push Notifications**: Currently only logs notification details. Requires backend setup to actually send notifications.

2. **Google Sign-In on Web**: Web configuration not included in this implementation.

3. **Notification Customization**: Notification appearance can be further customized (icons, sounds, etc.).

4. **Notification Channels**: Android notification channels can be configured for better user control.

5. **Rich Notifications**: Can be enhanced with images, action buttons, etc.

---

## 🚀 Next Steps

1. **Set up Firebase Cloud Functions** for sending push notifications
2. **Configure APNs** for iOS push notifications
3. **Add notification settings** screen for users to control notification preferences
4. **Implement notification badges** to show unread notification count
5. **Add notification history** to show all past notifications
6. **Implement notification categories** (likes, comments, follows, mentions, etc.)
7. **Add do-not-disturb mode** for quiet hours
8. **Implement notification sounds** and custom vibration patterns

---

## 📚 Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications) - For enhanced notification UI

---

## 🐛 Troubleshooting

### Google Sign-In Issues:
- **"Sign in failed"**: Check SHA-1/SHA-256 fingerprints in Firebase Console
- **"Network error"**: Check internet connection and Firebase configuration
- **"Invalid client"**: Verify package name matches Firebase Console

### FCM Issues:
- **Token is null**: Check permissions and Firebase configuration
- **Notifications not received**: Verify FCM is properly set up in Firebase Console
- **Background notifications not working**: Check background handler is registered in main.dart

### Username Availability Issues:
- **Always shows unavailable**: Check Firestore rules and network connection
- **Slow checking**: Consider implementing better debouncing

---

## 👨‍💻 Developer Notes

- All print statements use emoji prefixes for easy log filtering:
  - ✅ for success
  - ❌ for errors
  - ⚠️ for warnings
  - 📱 for FCM token operations
  - 📩 📬 📭 📨 for notification operations

- FCM service is designed to be extensible. You can easily add:
  - More notification types (follow, mention, reply, etc.)
  - Topic subscriptions for broadcast notifications
  - Notification grouping and batching
  - Silent notifications for data sync

- User info screen uses the same UI patterns as the signup screen for consistency

---

## 📄 License
This implementation follows the project's existing license.
