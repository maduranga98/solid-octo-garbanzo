# InkWing Security Guide

This document outlines the security measures implemented in InkWing and best practices for maintaining security in production.

## 🔒 Security Overview

InkWing implements multiple layers of security to protect user data and prevent unauthorized access:

1. **Authentication** - Firebase Authentication with email/password and Google Sign-In
2. **Authorization** - Firestore and Storage security rules
3. **Input Validation** - Client and server-side validation
4. **Data Protection** - Encrypted transmission and secure storage
5. **API Security** - Authenticated Cloud Functions with rate limiting

## 🛡️ Security Features Implemented

### 1. Firebase Security Rules

#### Firestore Security Rules (`firestore.rules`)

**Key Protection Mechanisms:**

- ✅ **Authentication Required** - All operations require a logged-in user
- ✅ **Ownership Validation** - Users can only modify their own data
- ✅ **Input Validation** - Data types and lengths are validated
- ✅ **Field-Level Protection** - Critical fields (uid, email) cannot be changed
- ✅ **Subcollection Security** - Likes, comments, followers are protected

**Collections Protected:**

```
users/{userId}
  ├── Read: Any authenticated user
  ├── Write: Owner only
  ├── bookmarks/{bookmarkId} - Owner only
  ├── followers/{followerId} - Controlled access
  ├── following/{followingId} - Owner only
  └── notifications/{notificationId} - Owner only

posts/{postId}
  ├── Read: Any authenticated user
  ├── Write: Owner only
  ├── likes/{likeId} - User can like/unlike
  └── comments/{commentId} - User can comment, owner can delete
```

**Validation Rules:**

```javascript
// Username: 3-30 characters, alphanumeric and underscore only
userName.matches('^[a-zA-Z0-9_]+$')

// Email: Valid email format
email.matches('.*@.*\\..*')

// Bio: Max 500 characters
bio.size() <= 500

// Post title: 1-200 characters
title.size() >= 1 && title.size() <= 200

// Comment: 1-1000 characters
comment.size() >= 1 && comment.size() <= 1000
```

#### Firebase Storage Rules (`storage.rules`)

**Key Protection Mechanisms:**

- ✅ **Authentication Required** - All uploads require login
- ✅ **File Type Validation** - Only image files allowed
- ✅ **File Size Limits** - Maximum 10MB per file
- ✅ **Path-Based Authorization** - Users can only upload to their own folders

**Protected Paths:**

```
/users/{userId}/profile/{filename}
  └── Only user can upload/delete their profile photo

/posts/{userId}/{postId}/{filename}
  └── Only user can upload/delete images for their posts

/temp/{userId}/{filename}
  └── Temporary uploads for image processing
```

### 2. Cloud Functions Security

**Authentication & Authorization:**

All callable Cloud Functions (`sendNotification`, `sendBatchNotifications`) now:

- ✅ Require user authentication via `requireAuth()`
- ✅ Validate all input parameters
- ✅ Sanitize string inputs to prevent injection attacks
- ✅ Use `HttpsError` for proper error handling
- ✅ Log user actions for audit trails

**Input Validation:**

```javascript
// FCM Token Validation
- Format: String, 1-500 characters
- Purpose: Prevent malformed tokens

// String Sanitization
- Trim whitespace
- Limit length (title: 100, body: 500, comment: 1000)
- Prevent oversized data

// Batch Size Limits
- Maximum 500 tokens per batch
- Prevents spam and abuse
```

**Rate Limiting:**

- Batch notifications limited to 500 tokens per request
- Prevents mass spamming
- Firestore triggers automatically rate-limited by Firebase

### 3. Client-Side Security

#### Password Security

**Requirements (configurable in `lib/config/app_config.dart`):**

- Minimum 8 characters
- Can require special characters (set `requireStrongPassword`)
- Handled by Firebase Authentication (bcrypt hashing)
- Never stored in plaintext

#### Data Validation

**Content Limits:**

```dart
// In lib/config/app_config.dart
maxPostTitleLength = 200
maxPostContentLength = 5000
maxCommentLength = 1000
maxBioLength = 500
maxUsernameLength = 30
minUsernameLength = 3
```

**File Upload Limits:**

```dart
maxImageSizeMB = 10
allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp']
```

#### Logging & Privacy

**Production Logging** (`lib/config/app_config.dart`):

- Debug logs automatically disabled in release mode
- Sensitive data (passwords, tokens) never logged
- Error logs sent to monitoring service (when configured)
- `AppLogger.sanitize()` redacts sensitive information

### 4. API Key Protection

**Environment Variables:**

All Firebase credentials stored in `.env` file:

```bash
# .env is in .gitignore - NEVER commit this file
APIKEY=...
APP_ID_ANDROID=...
MESSAGING_SENDER_ID=...
STORAGE_BUCKET=...
```

**API Key Restrictions (Configure in Google Cloud Console):**

1. **Android API Key:**
   - Restrict to app's SHA-1 fingerprint
   - Prevents use by unauthorized apps

2. **iOS API Key:**
   - Restrict to bundle identifier
   - Prevents use by other iOS apps

3. **Web API Key:**
   - Restrict to authorized domains only
   - Prevents use from unknown websites

## 🚨 Common Security Threats & Mitigations

### 1. Unauthorized Data Access

**Threat:** User tries to read/modify another user's data

**Mitigation:**
- Firestore rules check `request.auth.uid == userId`
- All queries filtered by user ID
- Subcollections protected by parent document ownership

**Example Protection:**
```javascript
// In firestore.rules
match /users/{userId} {
  allow update: if request.auth.uid == userId
                && request.resource.data.uid == userId;
}
```

### 2. Injection Attacks

**Threat:** Malicious input in comments, posts, or user data

**Mitigation:**
- Cloud Functions sanitize all string inputs
- Firestore rules validate data types and formats
- Flutter Quill editor sanitizes rich text
- Input length limits prevent oversized data

**Example Protection:**
```javascript
// In Cloud Functions
const sanitizedTitle = sanitizeString(title, 100);
const sanitizedBody = sanitizeString(body, 500);
```

### 3. Mass Data Extraction

**Threat:** Attacker tries to download all user data or posts

**Mitigation:**
- Firestore rules require authentication
- No public query access to entire collections
- Pagination limits data per request
- Rate limiting in Cloud Functions

### 4. Spam & Abuse

**Threat:** User sends spam notifications or creates spam posts

**Mitigation:**
- Batch notification limit: 500 tokens per request
- Client-side cooldowns (configurable in `AppConfig`)
- Post creation cooldown: 10 seconds
- Comment cooldown: 3 seconds
- Like cooldown: 500ms

**Example Configuration:**
```dart
// In lib/config/app_config.dart
static const Duration postCreationCooldown = Duration(seconds: 10);
static const Duration commentCooldown = Duration(seconds: 3);
```

### 5. Account Takeover

**Threat:** Attacker gains access to user account

**Mitigation:**
- Firebase Authentication handles password hashing
- Google Sign-In uses OAuth 2.0
- Password reset via verified email only
- Email verification (optional, configurable)
- FCM tokens tied to specific devices

### 6. Man-in-the-Middle (MITM) Attacks

**Threat:** Attacker intercepts data in transit

**Mitigation:**
- All Firebase communication uses HTTPS/TLS
- Certificate pinning (automatic with Firebase)
- Secure WebSocket connections for real-time data
- No custom HTTP endpoints (all through Firebase)

### 7. Malicious File Uploads

**Threat:** User uploads malware disguised as images

**Mitigation:**
- Storage rules only allow image MIME types
- File size limited to 10MB
- Files stored in isolated user folders
- No server-side execution of uploaded files

**Storage Rule Example:**
```javascript
function isImageFile() {
  return request.resource.contentType.matches('image/.*');
}

function isValidFileSize() {
  return request.resource.size <= 10 * 1024 * 1024;
}

allow write: if isImageFile() && isValidFileSize();
```

### 8. Cross-Site Scripting (XSS)

**Threat:** Malicious scripts in user-generated content

**Mitigation:**
- Flutter apps not vulnerable to traditional XSS
- Web version uses Flutter's safe rendering
- Rich text sanitized by Flutter Quill
- No `eval()` or dynamic HTML injection

## 🔐 Best Practices for Developers

### 1. Environment Variables

```bash
# ✅ DO: Use .env for secrets
APIKEY=your_actual_key

# ❌ DON'T: Hardcode credentials
const apiKey = "AIzaSyC-hardcoded-key";
```

### 2. Error Handling

```dart
// ✅ DO: Use generic error messages for users
throw Exception('Authentication failed');

// ❌ DON'T: Expose internal details
throw Exception('User not found in Firestore: $userId');
```

### 3. Logging

```dart
// ✅ DO: Use AppLogger in production
AppLogger.error('Login failed', error);

// ❌ DON'T: Use print() for sensitive data
print('Password: $password'); // NEVER DO THIS
```

### 4. Validation

```dart
// ✅ DO: Validate on both client and server
if (title.isEmpty || title.length > AppConfig.maxPostTitleLength) {
  throw Exception('Invalid title');
}

// ❌ DON'T: Trust client-side validation alone
// Always validate in Firestore rules too
```

### 5. User Input

```dart
// ✅ DO: Sanitize and limit input
final sanitizedBio = bio.trim().substring(0, AppConfig.maxBioLength);

// ❌ DON'T: Accept unlimited or unsanitized input
await updateBio(bio); // No validation!
```

## 🔍 Security Monitoring

### What to Monitor

1. **Authentication Failures**
   - Unusual login patterns
   - Repeated failed login attempts
   - Account creation spikes

2. **Firestore Usage**
   - Unexpected read/write spikes
   - Large data downloads
   - Rule violation attempts (logged by Firebase)

3. **Cloud Functions**
   - Error rates
   - Timeout frequencies
   - Invocation patterns

4. **Storage Usage**
   - Large file uploads
   - Unusual upload patterns
   - Storage quota consumption

### Firebase Console Monitoring

1. **Authentication Tab**
   - View sign-in methods usage
   - Monitor user growth
   - Check for suspicious accounts

2. **Firestore Rules Tab**
   - Test rules with simulator
   - View rule violation attempts
   - Update rules as needed

3. **Cloud Functions Logs**
   - Filter by severity (errors, warnings)
   - Search for specific user IDs
   - Set up alerts for critical errors

4. **Usage & Billing**
   - Set budget alerts
   - Monitor quota usage
   - Track costs per service

## 🆘 Incident Response

### If a Security Issue is Discovered

1. **Immediate Actions:**
   - Document the issue and impact
   - Determine if data was compromised
   - Disable affected features if needed
   - Rotate compromised API keys

2. **Investigation:**
   - Review Cloud Functions logs
   - Check Firestore activity logs
   - Identify affected users
   - Determine root cause

3. **Remediation:**
   - Deploy security fix
   - Update security rules if needed
   - Notify affected users (if required)
   - Document lessons learned

4. **Prevention:**
   - Add tests for the vulnerability
   - Update security documentation
   - Review similar code patterns
   - Train team on the issue

## 📞 Security Contacts

### Reporting Security Issues

If you discover a security vulnerability:

1. **Do NOT** open a public GitHub issue
2. Email: [your-security-email@example.com]
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Your contact information

### Third-Party Security

- **Firebase Security**: https://firebase.google.com/support/privacy
- **Google Cloud Security**: https://cloud.google.com/security
- **Flutter Security**: https://github.com/flutter/flutter/security

## 📋 Security Checklist

Before deploying to production:

- [ ] All security rules deployed and tested
- [ ] API keys restricted to app/domain
- [ ] Environment variables properly configured
- [ ] Debug logging disabled in production
- [ ] Cloud Functions authentication enabled
- [ ] Input validation on all user inputs
- [ ] File upload restrictions in place
- [ ] Monitoring and alerts configured
- [ ] Privacy policy and terms of service ready
- [ ] Incident response plan documented
- [ ] Security testing completed
- [ ] Team trained on security practices

## 🔄 Regular Security Maintenance

### Weekly
- Review Cloud Functions error logs
- Check for unusual authentication patterns
- Monitor storage and database usage

### Monthly
- Review security rules for needed updates
- Audit user account activity
- Check for deprecated dependencies
- Review and rotate service account keys

### Quarterly
- Security penetration testing
- Review and update security documentation
- Train team on new security threats
- Audit third-party dependencies

### Annually
- Comprehensive security audit
- Update privacy policy and terms
- Review compliance requirements
- Renew SSL certificates (automatic with Firebase)

---

**Version:** 1.0.0
**Last Updated:** 2025-11-17

For questions or security concerns, please contact the development team.
