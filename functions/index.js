/* eslint-disable max-len */
/* eslint-disable valid-jsdoc */
/**
 * Firebase Cloud Functions for VerseWing Push Notifications
 * Production-ready with all functions active
 * Version: 1.0.0
 */

const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {logger} = require("firebase-functions");

initializeApp();

/**
 * Helper function to validate FCM token format
 */
function isValidFCMToken(token) {
  return typeof token === "string" && token.length > 0 && token.length < 500;
}

/**
 * Helper function to sanitize string input
 */
function sanitizeString(str, maxLength = 1000) {
  if (typeof str !== "string") return "";
  return str.trim().substring(0, maxLength);
}

/**
 * Helper function to validate user authentication
 */
function requireAuth(request) {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User must be authenticated to call this function",
    );
  }
  return request.auth.uid;
}

/**
 * Helper function to safely get user's display name
 */
function getUserDisplayName(userData) {
  if (!userData) return "Someone";

  const firstname = userData.firstname || "";
  const lastname = userData.lastname || "";
  const fullName = `${firstname} ${lastname}`.trim();

  return fullName || userData.userName || userData.displayName || "Someone";
}

/**
 * ✅ ACTIVE: Send notification when a user likes a post
 */
exports.sendLikeNotification = onDocumentCreated(
    {
      document: "posts/{postId}/likes/{userId}",
      region: "us-central1",
    },
    async (event) => {
      try {
        const postId = event.params.postId;
        const likerId = event.params.userId;
        const db = getFirestore();

        logger.info(
            `Like notification triggered for post: ${postId} by user: ${likerId}`,
        );

        // Get post data
        const postDoc = await db.collection("posts").doc(postId).get();
        if (!postDoc.exists) {
          logger.warn("Post not found");
          return null;
        }

        const postData = postDoc.data();
        const postOwnerId = postData.createdBy || postData.userId;

        // Don't notify if user liked their own post
        if (likerId === postOwnerId) {
          logger.info("User liked own post, skipping notification");
          return null;
        }

        // Get liker data
        const likerDoc = await db.collection("users").doc(likerId).get();
        if (!likerDoc.exists) {
          logger.warn("Liker not found");
          return null;
        }

        const likerName = getUserDisplayName(likerDoc.data());

        // Get post owner data
        const ownerDoc = await db.collection("users").doc(postOwnerId).get();
        if (!ownerDoc.exists) {
          logger.warn("Post owner not found");
          return null;
        }

        const ownerData = ownerDoc.data();
        const fcmToken = ownerData.fcmToken;

        if (!fcmToken || !isValidFCMToken(fcmToken)) {
          logger.info("No valid FCM token for post owner");
          return null;
        }

        // Get post title/preview
        const postTitle =
        postData.title ||
        (postData.plainText ?
          postData.plainText.substring(0, 50) :
          "your post");

        // Send notification
        const message = {
          notification: {
            title: "❤️ New Like",
            body: `${likerName} liked your post "${postTitle}"`,
          },
          data: {
            type: "like",
            postId: postId,
            likerId: likerId,
            likerName: likerName,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          token: fcmToken,
          android: {
            priority: "high",
            notification: {
              sound: "default",
              channelId: "high_importance_channel",
              icon: "ic_notification",
              color: "#6366F1",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        const response = await getMessaging().send(message);
        logger.info(`Like notification sent successfully: ${response}`);
        return {success: true, messageId: response};
      } catch (error) {
        logger.error("Error sending like notification:", error);
        return null;
      }
    },
);

/**
 * ✅ ACTIVE: Send notification when a user comments on a post
 */
exports.sendCommentNotification = onDocumentCreated(
    {
      document: "posts/{postId}/comments/{commentId}",
      region: "us-central1",
    },
    async (event) => {
      try {
        const postId = event.params.postId;
        const commentId = event.params.commentId;
        const commentData = event.data.data();
        const commenterId = commentData.userId;
        const db = getFirestore();

        logger.info(`Comment notification triggered for post: ${postId}`);

        // Get post data
        const postDoc = await db.collection("posts").doc(postId).get();
        if (!postDoc.exists) {
          logger.warn("Post not found");
          return null;
        }

        const postData = postDoc.data();
        const postOwnerId = postData.createdBy || postData.userId;

        // Don't notify if user commented on their own post
        if (commenterId === postOwnerId) {
          logger.info("User commented on own post, skipping notification");
          return null;
        }

        // Get commenter data
        const commenterDoc = await db.collection("users").doc(commenterId).get();
        if (!commenterDoc.exists) {
          logger.warn("Commenter not found");
          return null;
        }

        const commenterName = getUserDisplayName(commenterDoc.data());

        // Get post owner data
        const ownerDoc = await db.collection("users").doc(postOwnerId).get();
        if (!ownerDoc.exists) {
          logger.warn("Post owner not found");
          return null;
        }

        const ownerData = ownerDoc.data();
        const fcmToken = ownerData.fcmToken;

        if (!fcmToken || !isValidFCMToken(fcmToken)) {
          logger.info("No valid FCM token for post owner");
          return null;
        }

        // Get post title/preview
        const postTitle =
        postData.title ||
        (postData.plainText ?
          postData.plainText.substring(0, 50) :
          "your post");

        const commentText = commentData.text || "";
        const commentPreview =
        commentText.length > 100 ?
          commentText.substring(0, 100) + "..." :
          commentText;

        // Send notification
        const message = {
          notification: {
            title: "💬 New Comment",
            body: `${commenterName} commented on "${postTitle}"`,
          },
          data: {
            type: "comment",
            postId: postId,
            commentId: commentId,
            commenterId: commenterId,
            commenterName: commenterName,
            commentText: commentPreview,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          token: fcmToken,
          android: {
            priority: "high",
            notification: {
              sound: "default",
              channelId: "high_importance_channel",
              icon: "ic_notification",
              color: "#6366F1",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        const response = await getMessaging().send(message);
        logger.info(`Comment notification sent successfully: ${response}`);
        return {success: true, messageId: response};
      } catch (error) {
        logger.error("Error sending comment notification:", error);
        return null;
      }
    },
);

/**
 * ✅ ACTIVE: Send notification when a user follows another user
 */
exports.sendFollowNotification = onDocumentCreated(
    {
      document: "users/{userId}/followers/{followerId}",
      region: "us-central1",
    },
    async (event) => {
      try {
        const userId = event.params.userId;
        const followerId = event.params.followerId;
        const db = getFirestore();

        logger.info(
            `Follow notification triggered: ${followerId} followed ${userId}`,
        );

        // Get follower data
        const followerDoc = await db.collection("users").doc(followerId).get();
        if (!followerDoc.exists) {
          logger.warn("Follower not found");
          return null;
        }

        const followerName = getUserDisplayName(followerDoc.data());

        // Get followed user data
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists) {
          logger.warn("Followed user not found");
          return null;
        }

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        if (!fcmToken || !isValidFCMToken(fcmToken)) {
          logger.info("No valid FCM token for followed user");
          return null;
        }

        // Send notification
        const message = {
          notification: {
            title: "👥 New Follower",
            body: `${followerName} started following you`,
          },
          data: {
            type: "follow",
            userId: followerId,
            followerId: followerId,
            followerName: followerName,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          token: fcmToken,
          android: {
            priority: "high",
            notification: {
              sound: "default",
              channelId: "high_importance_channel",
              icon: "ic_notification",
              color: "#6366F1",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        const response = await getMessaging().send(message);
        logger.info(`Follow notification sent successfully: ${response}`);
        return {success: true, messageId: response};
      } catch (error) {
        logger.error("Error sending follow notification:", error);
        return null;
      }
    },
);

/**
 * ✅ ACTIVE: Send notification when a new message is received
 */
exports.sendMessageNotification = onDocumentCreated(
    {
      document: "chats/{chatId}/messages/{messageId}",
      region: "us-central1",
    },
    async (event) => {
      try {
        const chatId = event.params.chatId;
        const messageData = event.data.data();
        const senderId = messageData.senderId;
        const messageText = messageData.text || "";
        const db = getFirestore();

        logger.info(`Message notification triggered for chat: ${chatId}`);

        // Get chat metadata
        const chatDoc = await db.collection("chats").doc(chatId).get();
        if (!chatDoc.exists) {
          logger.warn("Chat not found");
          return null;
        }

        const chatData = chatDoc.data();
        const participants = chatData.participants || [];

        // Find recipient (not the sender)
        const recipientId = participants.find((id) => id !== senderId);
        if (!recipientId) {
          logger.warn("No recipient found");
          return null;
        }

        // Get sender data
        const senderDoc = await db.collection("users").doc(senderId).get();
        if (!senderDoc.exists) {
          logger.warn("Sender not found");
          return null;
        }

        const senderName = getUserDisplayName(senderDoc.data());

        // Get recipient data
        const recipientDoc = await db.collection("users").doc(recipientId).get();
        if (!recipientDoc.exists) {
          logger.warn("Recipient not found");
          return null;
        }

        const recipientData = recipientDoc.data();
        const fcmToken = recipientData.fcmToken;

        if (!fcmToken || !isValidFCMToken(fcmToken)) {
          logger.info("No valid FCM token for recipient");
          return null;
        }

        // Create message preview
        const messagePreview =
        messageText.length > 100 ?
          messageText.substring(0, 100) + "..." :
          messageText;

        // Send notification
        const message = {
          notification: {
            title: `💬 ${senderName}`,
            body: messagePreview || "Sent you a message",
          },
          data: {
            type: "message",
            chatId: chatId,
            senderId: senderId,
            senderName: senderName,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          token: fcmToken,
          android: {
            priority: "high",
            notification: {
              sound: "default",
              channelId: "high_importance_channel",
              icon: "ic_notification",
              color: "#6366F1",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        const response = await getMessaging().send(message);
        logger.info(`Message notification sent successfully: ${response}`);
        return {success: true, messageId: response};
      } catch (error) {
        logger.error("Error sending message notification:", error);
        return null;
      }
    },
);

/**
 * ✅ ACTIVE: Send notification when a report is updated
 */
exports.sendReportUpdateNotification = onDocumentUpdated(
    {
      document: "reports/{reportId}",
      region: "us-central1",
    },
    async (event) => {
      try {
        const newData = event.data.after.data();
        const previousData = event.data.before.data();

        // Only send if status changed
        if (newData.status === previousData.status) {
          logger.info("Report status unchanged, skipping notification");
          return null;
        }

        const reportedBy = newData.reportedBy;
        if (!reportedBy) {
          logger.warn("No reporter ID found");
          return null;
        }

        // Get reporter data
        const userDoc = await getFirestore()
            .collection("users")
            .doc(reportedBy)
            .get();

        if (!userDoc.exists) {
          logger.warn(`User ${reportedBy} not found`);
          return null;
        }

        const fcmToken = userDoc.data().fcmToken;
        if (!fcmToken || !isValidFCMToken(fcmToken)) {
          logger.info(`No valid FCM token for user ${reportedBy}`);
          return null;
        }

        // Determine notification message
        let notificationTitle = "Report Update";
        let notificationBody = "";

        switch (newData.status) {
          case "underReview":
            notificationTitle = "Report Under Review";
            notificationBody =
            "Your report is being reviewed by our moderation team.";
            break;
          case "resolved":
            notificationTitle = "Report Resolved";
            notificationBody =
            "Your report has been reviewed and appropriate action has been taken. Thank you for helping keep our community safe.";
            break;
          case "dismissed":
            notificationTitle = "Report Update";
            notificationBody =
            "Your report has been reviewed. We could not find a violation of our community guidelines.";
            break;
          default:
            notificationBody = "Your report status has been updated.";
        }

        // Send notification
        const message = {
          notification: {
            title: notificationTitle,
            body: notificationBody,
          },
          data: {
            type: "report_update",
            reportId: event.params.reportId,
            status: newData.status,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          token: fcmToken,
          android: {
            priority: "high",
            notification: {
              sound: "default",
              channelId: "high_importance_channel",
              icon: "ic_notification",
              color: "#6366F1",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        await getMessaging().send(message);
        logger.info(`Report update notification sent to user ${reportedBy}`);
        return {success: true};
      } catch (error) {
        logger.error("Error sending report update notification:", error);
        return null;
      }
    },
);

/**
 * ✅ ACTIVE: Manual send notification (for testing/admin)
 */
exports.sendNotification = onCall(
    {region: "us-central1"},
    async (request) => {
    // Require authentication
      const userId = requireAuth(request);

      const {token, title, body, data: notificationData} = request.data;

      // Validate parameters
      if (!token || !title || !body) {
        throw new HttpsError(
            "invalid-argument",
            "Missing required parameters: token, title, and body",
        );
      }

      if (!isValidFCMToken(token)) {
        throw new HttpsError("invalid-argument", "Invalid FCM token format");
      }

      // Sanitize inputs
      const sanitizedTitle = sanitizeString(title, 100);
      const sanitizedBody = sanitizeString(body, 500);

      const message = {
        notification: {
          title: sanitizedTitle,
          body: sanitizedBody,
        },
        data: notificationData || {},
        token: token,
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channelId: "high_importance_channel",
            icon: "ic_notification",
            color: "#6366F1",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      try {
        const response = await getMessaging().send(message);
        logger.info(`Manual notification sent by user ${userId}: ${response}`);
        return {success: true, messageId: response};
      } catch (error) {
        logger.error("Error sending notification:", error);
        throw new HttpsError("internal", "Failed to send notification");
      }
    },
);

/**
 * ✅ ACTIVE: Clean up FCM token when user is deleted
 */
exports.cleanupFCMToken = onDocumentDeleted(
    {
      document: "users/{userId}",
      region: "us-central1",
    },
    async (event) => {
      const userId = event.params.userId;
      logger.info(`User deleted, FCM token cleanup for: ${userId}`);
      // Token is automatically deleted with the user document
      return null;
    },
);

/**
 * ═══════════════════════════════════════════════════════════════
 * BADGE SYSTEM - Auto-award badges based on user achievements
 * ═══════════════════════════════════════════════════════════════
 */

/**
 * Hardcoded badge configurations (fallback when badges_config collection is empty)
 */
const BADGE_CONFIGS = {
  pioneer: {
    name: "Pioneer",
    description: "First 100 members to join VerseWing",
    icon: "🌟",
    category: "achievement",
  },
  first_words: {
    name: "First Words",
    description: "Published your first post",
    icon: "✍️",
    category: "achievement",
  },
  fresh_ink: {
    name: "Fresh Ink",
    description: "Welcome to VerseWing, fresher!",
    icon: "🆕",
    category: "achievement",
  },
  prolific_writer: {
    name: "Prolific Writer",
    description: "Published 50+ posts",
    icon: "📚",
    category: "achievement",
  },
  engaged_reader: {
    name: "Engaged Reader",
    description: "Left 100+ comments",
    icon: "💬",
    category: "achievement",
  },
  rising_star: {
    name: "Rising Star",
    description: "Gained 1000+ likes within first month",
    icon: "⭐",
    category: "recognition",
  },
  community_favorite: {
    name: "Community Favorite",
    description: "Your post reached top 10 trending",
    icon: "❤️",
    category: "recognition",
  },
  consistent_creator: {
    name: "Consistent Creator",
    description: "Posted for 30 consecutive days",
    icon: "🔥",
    category: "recognition",
  },
  versewing_team: {
    name: "VerseWing Team",
    description: "Official VerseWing team member",
    icon: "👑",
    category: "special",
  },
};

/**
 * Helper function to award a badge to a user
 */
async function awardBadge(userId, badgeId) {
  const db = getFirestore();

  try {
    const existingBadge = await db
        .collection("users")
        .doc(userId)
        .collection("badges")
        .doc(badgeId)
        .get();

    if (existingBadge.exists) {
      logger.info(`User ${userId} already has badge ${badgeId}`);
      return false;
    }

    // Try Firestore config first, fall back to hardcoded config
    let badgeData;
    const badgeConfig = await db.collection("badges_config").doc(badgeId).get();

    if (badgeConfig.exists) {
      badgeData = badgeConfig.data();
    } else if (BADGE_CONFIGS[badgeId]) {
      badgeData = BADGE_CONFIGS[badgeId];
      logger.info(`Using fallback config for badge ${badgeId}`);
    } else {
      logger.error(`Badge config not found for ${badgeId}`);
      return false;
    }

    const batch = db.batch();

    const badgeRef = db
        .collection("users")
        .doc(userId)
        .collection("badges")
        .doc(badgeId);

    batch.set(badgeRef, {
      id: badgeId,
      name: badgeData.name,
      description: badgeData.description,
      icon: badgeData.icon,
      category: badgeData.category,
      earnedAt: FieldValue.serverTimestamp(),
      isPrimary: false,
    });

    const userRef = db.collection("users").doc(userId);
    batch.update(userRef, {
      badgeCount: FieldValue.increment(1),
    });

    await batch.commit();

    logger.info(`✅ Badge ${badgeId} awarded to user ${userId}`);
    return true;
  } catch (error) {
    logger.error(`Error awarding badge ${badgeId} to user ${userId}:`, error);
    return false;
  }
}

/**
 * Initialize badge configurations in Firestore (callable by admin)
 * This populates the badges_config collection using Admin SDK (bypasses rules)
 */
exports.initializeBadgeConfigs = onCall(
    {region: "us-central1"},
    async () => {
      const db = getFirestore();
      const batch = db.batch();
      let count = 0;

      for (const [badgeId, config] of Object.entries(BADGE_CONFIGS)) {
        const docRef = db.collection("badges_config").doc(badgeId);
        batch.set(docRef, {
          id: badgeId,
          ...config,
          criteria: {},
        });
        count++;
      }

      await batch.commit();
      logger.info(`✅ Initialized ${count} badge configurations`);
      return {success: true, count};
    },
);

/**
 * One-time callable: Retroactively award badges to all existing users
 * Call once, then remove
 */
exports.retroactivelyAwardBadges = onCall(
    {region: "us-central1"},
    async (request) => {
      const db = getFirestore();
      const results = {
        pioneer: 0,
        first_words: 0,
        errors: [],
      };

      try {
      // Get all users ordered by creation date
        const usersSnapshot = await db
            .collection("users")
            .orderBy("createdAt", "asc")
            .get();

        let userIndex = 0;

        for (const userDoc of usersSnapshot.docs) {
          userIndex++;
          const userId = userDoc.id;

          try {
          // Award Pioneer badge to first 100 users
            if (userIndex <= 100) {
              const awarded = await awardBadge(userId, "pioneer");
              if (awarded) results.pioneer++;
            }

            // Check if user has any posts -> award First Words
            const postsSnapshot = await db
                .collection("posts")
                .where("createdBy", "==", userId)
                .limit(1)
                .get();

            if (!postsSnapshot.empty) {
              const awarded = await awardBadge(userId, "first_words");
              if (awarded) results.first_words++;
            }
          } catch (err) {
            results.errors.push(`${userId}: ${err.message}`);
          }
        }

        logger.info("Retroactive badge results:", results);
        return results;
      } catch (error) {
        logger.error("Error in retroactive badges:", error);
        throw new HttpsError("internal", error.message);
      }
    },
);
/**
 * ✅ ACTIVE: Award Pioneer badge to first 100 users
 */
exports.checkPioneerBadge = onDocumentCreated(
    {
      document: "users/{userId}",
      region: "us-central1",
    },
    async (event) => {
      try {
        const userId = event.params.userId;
        const db = getFirestore();

        logger.info(`Checking Pioneer badge for new user: ${userId}`);

        // Count total users ordered by creation date
        const usersSnapshot = await db
            .collection("users")
            .orderBy("createdAt")
            .get();

        const userCount = usersSnapshot.docs.length;

        logger.info(`Total users: ${userCount}`);

        // Award Pioneer badge if user is within first 100
        if (userCount <= 100) {
          await awardBadge(userId, "pioneer");
          logger.info(
              `✅ Pioneer badge awarded to user ${userId} (user #${userCount})`,
          );
        } else {
          logger.info(`User ${userId} is not in first 100 (user #${userCount})`);
        }

        return null;
      } catch (error) {
        logger.error("Error checking Pioneer badge:", error);
        return null;
      }
    },
);

/**
 * ✅ ACTIVE: Award Fresh Ink badge to freshers
 */
exports.checkFresherBadge = onDocumentCreated(
    {
      document: "users/{userId}",
      region: "us-central1",
    },
    async (event) => {
      try {
        const userId = event.params.userId;
        const userData = event.data.data();

        logger.info(`Checking Fresher badge for new user: ${userId}`);

        // Check if user marked themselves as fresher
        if (userData.isFresher === true) {
          await awardBadge(userId, "fresh_ink");
          logger.info(`✅ Fresh Ink badge awarded to user ${userId}`);
        } else {
          logger.info(`User ${userId} is not a fresher`);
        }

        return null;
      } catch (error) {
        logger.error("Error checking Fresher badge:", error);
        return null;
      }
    },
);

/**
 * ✅ ACTIVE: Award First Words badge on first post
 */
exports.checkFirstPostBadge = onDocumentCreated(
    {
      document: "posts/{postId}",
      region: "us-central1",
    },
    async (event) => {
      try {
        const postData = event.data.data();
        const userId = postData.createdBy || postData.uid;
        const db = getFirestore();

        logger.info(`Checking First Words badge for user: ${userId}`);

        // Count user's total posts
        const postsSnapshot = await db
            .collection("posts")
            .where("createdBy", "==", userId)
            .get();

        const postCount = postsSnapshot.docs.length;

        logger.info(`User ${userId} has ${postCount} posts`);

        // Award First Words badge if this is their first post
        if (postCount === 1) {
          await awardBadge(userId, "first_words");
          logger.info(`✅ First Words badge awarded to user ${userId}`);
        }

        return null;
      } catch (error) {
        logger.error("Error checking First Words badge:", error);
        return null;
      }
    },
);

/**
 * ✅ ACTIVE: Award Prolific Writer badge at 50 posts
 */
exports.checkProlificWriterBadge = onDocumentCreated(
    {
      document: "posts/{postId}",
      region: "us-central1",
    },
    async (event) => {
      try {
        const postData = event.data.data();
        const userId = postData.createdBy || postData.uid;
        const db = getFirestore();

        logger.info(`Checking Prolific Writer badge for user: ${userId}`);

        // Count user's total posts
        const postsSnapshot = await db
            .collection("posts")
            .where("createdBy", "==", userId)
            .get();

        const postCount = postsSnapshot.docs.length;

        logger.info(`User ${userId} has ${postCount} posts`);

        // Award Prolific Writer badge at exactly 50 posts
        if (postCount === 50) {
          await awardBadge(userId, "prolific_writer");
          logger.info(`✅ Prolific Writer badge awarded to user ${userId}`);
        }

        return null;
      } catch (error) {
        logger.error("Error checking Prolific Writer badge:", error);
        return null;
      }
    },
);

/**
 * ✅ ACTIVE: Award Engaged Reader badge at 100 comments
 */
exports.checkEngagedReaderBadge = onDocumentCreated(
    {
      document: "posts/{postId}/comments/{commentId}",
      region: "us-central1",
    },
    async (event) => {
      try {
        const commentData = event.data.data();
        const userId = commentData.userId || commentData.authorId;
        const db = getFirestore();

        logger.info(`Checking Engaged Reader badge for user: ${userId}`);

        // Count user's total comments across all posts
        const postsSnapshot = await db.collection("posts").get();

        let totalComments = 0;

        for (const postDoc of postsSnapshot.docs) {
          const commentsSnapshot = await db
              .collection("posts")
              .doc(postDoc.id)
              .collection("comments")
              .where("userId", "==", userId)
              .get();

          totalComments += commentsSnapshot.docs.length;

          // Early exit if we've reached 100
          if (totalComments >= 100) break;
        }

        logger.info(`User ${userId} has ${totalComments} comments`);

        // Award Engaged Reader badge at exactly 100 comments
        if (totalComments === 100) {
          await awardBadge(userId, "engaged_reader");
          logger.info(`✅ Engaged Reader badge awarded to user ${userId}`);
        }

        return null;
      } catch (error) {
        logger.error("Error checking Engaged Reader badge:", error);
        return null;
      }
    },
);

/**
 * ✅ ACTIVE: Award Rising Star badge (1000 likes in first month)
 */
exports.checkRisingStarBadge = onDocumentCreated(
    {
      document: "posts/{postId}/likes/{likeId}",
      region: "us-central1",
    },
    async (event) => {
      try {
        const postId = event.params.postId;
        const db = getFirestore();

        // Get post data to find the author
        const postDoc = await db.collection("posts").doc(postId).get();
        if (!postDoc.exists) {
          logger.warn("Post not found");
          return null;
        }

        const postData = postDoc.data();
        const userId = postData.createdBy || postData.uid;

        logger.info(`Checking Rising Star badge for user: ${userId}`);

        // Get user's creation date
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists) {
          logger.warn("User not found");
          return null;
        }

        const userData = userDoc.data();
        const createdAt = userData.createdAt ? userData.createdAt.toDate() : null;

        if (!createdAt) {
          logger.warn("User creation date not found");
          return null;
        }

        // Check if user is within first 30 days
        const daysSinceCreation =
        (Date.now() - createdAt.getTime()) / (1000 * 60 * 60 * 24);

        if (daysSinceCreation > 30) {
          logger.info(
              `User ${userId} is beyond first month (${daysSinceCreation.toFixed(0)} days)`,
          );
          return null;
        }

        // Count total likes on all user's posts
        const userPostsSnapshot = await db
            .collection("posts")
            .where("createdBy", "==", userId)
            .get();

        let totalLikes = 0;

        for (const postDoc of userPostsSnapshot.docs) {
          const likesSnapshot = await db
              .collection("posts")
              .doc(postDoc.id)
              .collection("likes")
              .get();

          totalLikes += likesSnapshot.docs.length;

          // Early exit if we've reached 1000
          if (totalLikes >= 1000) break;
        }

        logger.info(
            `User ${userId} has ${totalLikes} total likes (within first ${daysSinceCreation.toFixed(0)} days)`,
        );

        // Award Rising Star badge at exactly 1000 likes within first month
        if (totalLikes === 1000 && daysSinceCreation <= 30) {
          await awardBadge(userId, "rising_star");
          logger.info(`✅ Rising Star badge awarded to user ${userId}`);
        }

        return null;
      } catch (error) {
        logger.error("Error checking Rising Star badge:", error);
        return null;
      }
    },
);
