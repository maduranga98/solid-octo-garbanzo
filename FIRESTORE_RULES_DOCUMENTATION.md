# Firebase Firestore Security Rules Documentation

## Overview
This document explains the Firestore security rules implemented for the VerseWing/InkWing poetry and content sharing platform. These rules ensure data security while allowing all application features to function properly.

---

## Security Principles

### 1. **Authentication Required**
- All operations require user authentication
- Anonymous access is completely blocked
- Protects against unauthorized data access

### 2. **Data Ownership**
- Users can only modify their own data
- Post authors control their posts
- Comment authors control their comments

### 3. **Public Reading with Privacy**
- Authenticated users can view posts and profiles (social features)
- Private data (bookmarks, notifications, ideas) only accessible to owner
- Blocking functionality prevents blocked users from viewing content

### 4. **Data Validation**
- Field types are validated (strings, integers, timestamps)
- Required fields are enforced
- Username format validation (3-20 chars, alphanumeric + underscore)
- Email format validation
- Timestamps must be recent (within 5 minutes)

### 5. **Immutable Fields**
- Creation timestamps cannot be changed
- User IDs cannot be altered
- Email addresses cannot be modified after account creation

---

## Collections & Rules

### 📁 `/users/{userId}`

#### Read Access
- ✅ Any authenticated user (for social features like profiles, following)
- ❌ Blocked users cannot read profiles

#### Write Access
- ✅ **Create**: User creating their own profile with valid data
- ✅ **Update**: User updating their own profile (immutable fields protected)
- ✅ **Delete**: User deleting their own account

#### Validation Rules
- Username: 3-20 characters, alphanumeric + underscore
- Email: Valid email format
- Initial counters (posts, followers, following) must be 0
- Required fields: firstname, lastname, email, userName, uid, type
- Creation timestamp must be recent

---

### 📁 `/users/{userId}/following/{targetUserId}`

#### Purpose
Tracks who a user is following

#### Rules
- ✅ **Read**: User can read their own following list
- ✅ **Create**: User can follow others
- ✅ **Delete**: User can unfollow

---

### 📁 `/users/{userId}/followers/{followerId}`

#### Purpose
Tracks a user's followers

#### Rules
- ✅ **Read**: User can read their own followers list
- ✅ **Create**: Follower creates their own follower document
- ✅ **Delete**: Follower can remove themselves (unfollow)

---

### 📁 `/users/{userId}/bookmarks/{postId}`

#### Purpose
Private bookmarks collection for each user

#### Rules
- ✅ **Read**: User can only read their own bookmarks
- ✅ **Create**: User can bookmark posts
- ✅ **Delete**: User can remove bookmarks

#### Validation
- postId must be a valid string
- bookmarkedAt timestamp must be recent

---

### 📁 `/users/{userId}/notifications/{notificationId}`

#### Purpose
User notifications for likes, comments, follows, mentions

#### Rules
- ✅ **Read**: User can only read their own notifications
- ✅ **Create**: Any authenticated user can create notifications (for sending to others)
- ✅ **Update**: Recipient can mark as read (only `isRead` field)
- ✅ **Delete**: Recipient can delete their notifications

#### Validation
- recipientId must match userId
- senderId, type must be valid strings
- isRead must be false on creation
- createdAt must be recent timestamp

#### Cloud Functions Integration
- Cloud Functions can create notifications for users
- Supports bulk notification creation

---

### 📁 `/users/{userId}/blockedUsers/{blockedUserId}`

#### Purpose
Track blocked users for safety features

#### Rules
- ✅ **Read**: User can read their own blocked list
- ✅ **Create**: User can block others
- ✅ **Delete**: User can unblock

#### Validation
- blockedBy must match userId
- blockedUserId must be valid string
- createdAt must be recent

---

### 📁 `/users/{userId}/ideas/{ideaId}`

#### Purpose
Private drafts and ideas storage

#### Rules
- ✅ **All operations**: User has full access to their own ideas

---

### 📁 `/posts/{postId}`

#### Read Access
- ✅ Any authenticated user (public posts for social platform)

#### Write Access
- ✅ **Create**: Any authenticated user can create posts
- ✅ **Update**: Only post author (immutable fields protected)
- ✅ **Delete**: Only post author

#### Validation Rules
- uid and createdBy must match authenticated user
- Required fields: authorName, title, description, workType
- Initial counters (comments, likes, shares, views) must be 0
- createdAt must be recent timestamp

#### Protected Fields
- uid, createdBy, createdAt cannot be changed
- Counter fields must remain integers

---

### 📁 `/posts/{postId}/likes/{userId}`

#### Purpose
Track post likes

#### Rules
- ✅ **Read**: Any authenticated user (for like counts)
- ✅ **Create**: User can like posts
- ✅ **Delete**: User can unlike posts

#### Validation
- userId must match authenticated user
- likedAt timestamp must be recent

---

### 📁 `/posts/{postId}/comments/{commentId}`

#### Purpose
Comments on posts

#### Rules
- ✅ **Read**: Any authenticated user
- ✅ **Create**: Any authenticated user can comment
- ✅ **Update**: Only comment author (immutable fields protected)
- ✅ **Delete**: Comment author OR post author

#### Validation
- authorId must match authenticated user
- Required fields: authorName, text, postId
- createdAt must be recent

#### Special Features
- Post authors can delete comments on their posts (moderation)

---

### 📁 `/posts/{postId}/comments/{commentId}/replies/{replyId}`

#### Purpose
Nested replies to comments

#### Rules
- ✅ **Read**: Any authenticated user
- ✅ **Create**: Any authenticated user can reply
- ✅ **Update**: Only reply author (immutable fields protected)
- ✅ **Delete**: Reply author, comment author, OR post author

#### Validation
- authorId must match authenticated user
- Required fields: authorName, text
- createdAt must be recent

#### Special Features
- Three-level moderation: reply author, parent comment author, or post author can delete

---

### 📁 `/commentLikes/{likeId}`

#### Purpose
Track likes on comments (flat collection for performance)

#### Rules
- ✅ **Read**: Any authenticated user
- ✅ **Create**: Any authenticated user can like comments
- ✅ **Delete**: Only the user who liked

#### Validation
- userId must match authenticated user
- Required fields: commentId, postId
- likedAt must be recent timestamp

---

### 📁 `/reports/{reportId}`

#### Purpose
User-generated reports for content moderation

#### Rules
- ✅ **Read**: Only the reporter can read their own reports
- ✅ **Create**: Any authenticated user can submit reports
- ❌ **Update/Delete**: Blocked (admin-only via Cloud Functions/Admin SDK)

#### Validation
- reportedBy must match authenticated user
- Required fields: reporterEmail, reporterName, reportType, reason, description
- reportType must be one of: `post`, `comment`, `profile`, `message`
- reason must be one of: `harassment`, `spam`, `inappropriateContent`, `violence`, `hateSpeech`, `childSafety`, `sexualContent`, `falseInformation`, `other`
- status must be `pending` on creation
- createdAt must be recent

#### Admin Operations
- Report status updates handled by Cloud Functions with Admin SDK
- Ensures users cannot modify or dismiss their own reports

---

### 📁 `/chats/{chatId}`

#### Purpose
Chat metadata for direct messaging

#### Rules
- ✅ **Read**: Only chat participants
- ✅ **Create**: Any authenticated user (must be in participants list)
- ✅ **Update**: Only participants (cannot remove themselves from participants)
- ✅ **Delete**: Only participants

#### Validation
- participants must be a list with at least 1 member
- Creator must be in participants list

---

### 📁 `/chats/{chatId}/messages/{messageId}`

#### Purpose
Messages within chats

#### Rules
- ✅ **Read**: Only chat participants
- ✅ **Create**: Only chat participants
- ✅ **Update**: Only message sender (immutable fields protected)
- ✅ **Delete**: Only message sender

#### Validation
- Sender must be a chat participant
- Required field: text
- createdAt must be recent timestamp

---

## Helper Functions

### `isAuthenticated()`
Checks if user is logged in

### `isOwner(userId)`
Checks if authenticated user matches the document owner

### `isBlockedBy(userId)`
Checks if current user is blocked by another user

### `isValidString(field)`
Validates that a field is a non-empty string

### `isValidUsername(username)`
Validates username format (3-20 chars, alphanumeric + underscore)

### `isValidEmail(email)`
Validates email format using regex

### `isRecentTimestamp(timestamp)`
Ensures timestamp is within ±5 minutes of request time (prevents backdating)

---

## Security Features

### ✅ Authentication Protection
- All operations require valid Firebase Authentication
- Anonymous access completely blocked

### ✅ User Privacy
- Bookmarks are private
- Notifications are private
- Ideas/drafts are private
- Users control their own data

### ✅ Social Features Enabled
- Public post reading (authenticated users)
- Public profile viewing (authenticated users)
- Following/followers functionality
- Like and comment features
- Blocking functionality

### ✅ Content Moderation
- Post authors can delete comments on their posts
- Comment authors can delete replies on their comments
- Users can block other users
- Reporting system for inappropriate content
- Admin-controlled report management

### ✅ Data Integrity
- Field type validation
- Required field enforcement
- Immutable field protection
- Timestamp validation (prevents backdating/future dating)
- Username and email format validation

### ✅ Child Safety
- Age verification fields in user profiles
- Parental consent tracking
- Report categories include `childSafety`
- Blocking functionality

### ✅ No Feature Blocking
- All application features remain functional
- Social interactions work properly
- Messaging enabled
- Notifications delivered
- Counter increments allowed

---

## Cloud Functions Integration

These rules are designed to work seamlessly with your Firebase Cloud Functions:

1. **sendLikeNotification** ✅ Can create notifications
2. **sendCommentNotification** ✅ Can create notifications
3. **sendReportUpdateNotification** ✅ Can update reports (Admin SDK)
4. **cleanupFCMToken** ✅ Can delete user data (Admin SDK)
5. **sendNotification** ✅ Can create notifications (callable)
6. **sendBatchNotifications** ✅ Can create notifications (callable)

Cloud Functions using Admin SDK bypass these rules and have full access.

---

## Testing Recommendations

### Test User Operations
- ✅ Create user account
- ✅ Update profile
- ✅ Delete account
- ❌ Try to modify another user's profile (should fail)

### Test Post Operations
- ✅ Create post
- ✅ Update own post
- ✅ Delete own post
- ✅ View others' posts
- ❌ Try to edit another user's post (should fail)

### Test Social Features
- ✅ Follow/unfollow users
- ✅ Like/unlike posts
- ✅ Comment on posts
- ✅ Reply to comments
- ✅ Bookmark posts

### Test Privacy
- ✅ View own bookmarks
- ❌ Try to view another user's bookmarks (should fail)
- ✅ View own notifications
- ❌ Try to view another user's notifications (should fail)

### Test Moderation
- ✅ Delete own comment
- ✅ Delete comment on own post (as post author)
- ✅ Block/unblock users
- ✅ Submit report

### Test Messaging
- ✅ Create chat
- ✅ Send message in chat
- ❌ Try to read messages from chat you're not in (should fail)

---

## Deployment

These rules are ready to deploy to Firebase:

```bash
firebase deploy --only firestore:rules
```

Or deploy everything:

```bash
firebase deploy
```

---

## Maintenance Notes

### When Adding New Features
1. Add validation rules for new fields
2. Test create/update/delete operations
3. Ensure immutable fields are protected
4. Validate data types and formats

### Performance Considerations
- Rules use `get()` calls for nested permissions (e.g., checking post author)
- `get()` calls count towards read quotas
- Consider denormalizing data if performance issues arise
- Current structure optimized for security over performance

### Security Best Practices ✅
- ✅ Default deny all (last rule blocks everything not explicitly allowed)
- ✅ Authenticate all operations
- ✅ Validate all user input
- ✅ Protect immutable fields
- ✅ Prevent privilege escalation
- ✅ Block user enumeration attacks
- ✅ Enforce data ownership

---

## Summary

These Firestore security rules provide **comprehensive protection** for the VerseWing/InkWing platform while ensuring **all features work properly**. The rules:

- ✅ Require authentication for all operations
- ✅ Enforce data ownership and privacy
- ✅ Validate all user input
- ✅ Protect against common security vulnerabilities
- ✅ Support all social features (following, likes, comments)
- ✅ Enable content moderation and safety features
- ✅ Work seamlessly with Cloud Functions
- ✅ Follow Firebase security best practices

**Status**: Production-ready 🚀
