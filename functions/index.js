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
const {getFirestore} = require("firebase-admin/firestore");
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
