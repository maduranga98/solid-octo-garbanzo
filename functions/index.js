/**
 * Firebase Cloud Functions for Push Notifications
 * Production-ready with authentication, validation, and error handling
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

initializeApp();

/**
 * Helper function to validate FCM token format
 * @param {string} token - The FCM token to validate
 * @return {boolean} True if token is valid, false otherwise
 */
function isValidFCMToken(token) {
  return typeof token === "string" && token.length > 0 && token.length < 500;
}

/**
 * Helper function to sanitize string input
 * @param {string} str - The string to sanitize
 * @param {number} maxLength - Maximum length of the sanitized string
 * @return {string} Sanitized string
 */
function sanitizeString(str, maxLength = 1000) {
  if (typeof str !== "string") return "";
  return str.trim().substring(0, maxLength);
}

/**
 * Helper function to validate user authentication
 * @param {Object} request - The request object
 * @return {string} The authenticated user's UID
 * @throws {HttpsError} If user is not authenticated
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
 * Send a push notification to a specific user
 * Requires authentication
 */
exports.sendNotification = onCall(async (request) => {
  // Require authentication
  const userId = requireAuth(request);

  const {token, title, body, data: notificationData} = request.data;

  // Validate required parameters
  if (!token || !title || !body) {
    throw new HttpsError(
        "invalid-argument",
        "Missing required parameters: token, title, and body are required",
    );
  }

  // Validate FCM token format
  if (!isValidFCMToken(token)) {
    throw new HttpsError("invalid-argument", "Invalid FCM token format");
  }

  // Sanitize inputs
  const sanitizedTitle = sanitizeString(title, 100);
  const sanitizedBody = sanitizeString(body, 500);

  // Validate notification data
  if (notificationData && typeof notificationData !== "object") {
    throw new HttpsError(
        "invalid-argument",
        "Notification data must be an object",
    );
  }

  const message = {
    notification: {
      title: sanitizedTitle,
      body: sanitizedBody,
    },
    data: notificationData || {},
    token: token,
    android: {
      priority: "high",
      notification: {sound: "default", channelId: "high_importance_channel"},
    },
    apns: {payload: {aps: {sound: "default", badge: 1}}},
  };

  try {
    const response = await getMessaging().send(message);
    console.log(`Notification sent by user ${userId}:`, response);
    return {success: true, messageId: response};
  } catch (error) {
    console.error("Error sending notification:", error);
    if (
      error.code === "messaging/invalid-registration-token" ||
      error.code === "messaging/registration-token-not-registered"
    ) {
      throw new HttpsError("not-found", "Invalid or expired FCM token");
    }
    throw new HttpsError("internal", "Failed to send notification");
  }
});

/**
 * Trigger notification when a user likes a post
 */
exports.sendLikeNotification = onDocumentCreated(
    "posts/{postId}/likes/{userId}",
    async (event) => {
      try {
        const postId = event.params.postId;
        const likerId = event.params.userId;
        const db = getFirestore();

        const postDoc = await db.collection("posts").doc(postId).get();

        if (!postDoc.exists) {
          console.log("Post not found");
          return null;
        }

        const postData = postDoc.data();
        const postOwnerId = postData.createdBy;

        if (likerId === postOwnerId) {
          console.log("User liked own post, skipping");
          return null;
        }

        const likerDoc = await db.collection("users").doc(likerId).get();

        if (!likerDoc.exists) {
          console.log("Liker not found");
          return null;
        }

        const likerData = likerDoc.data();
        const likerName =
        `${likerData.firstname || ""} ${likerData.lastname || ""}`.trim() ||
        "Someone";

        const ownerDoc = await db.collection("users").doc(postOwnerId).get();

        if (!ownerDoc.exists) {
          console.log("Owner not found");
          return null;
        }

        const ownerData = ownerDoc.data();
        const fcmToken = ownerData.fcmToken;

        if (!fcmToken) {
          console.log("No FCM token");
          return null;
        }

        const postTitle =
        postData.title ||
        (postData.plainText ?
          postData.plainText.substring(0, 50) :
          "your post");

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
            },
          },
          apns: {payload: {aps: {sound: "default", badge: 1}}},
        };

        const response = await getMessaging().send(message);
        console.log("Like notification sent:", response);
        return {success: true};
      } catch (error) {
        console.error("Error sending like notification:", error);
        return null;
      }
    },
);

/**
 * Trigger notification when a user comments on a post
 */
exports.sendCommentNotification = onDocumentCreated(
    "posts/{postId}/comments/{commentId}",
    async (event) => {
      try {
        const postId = event.params.postId;
        const commentId = event.params.commentId;
        const commentData = event.data.data();
        const commenterId = commentData.userId;
        const db = getFirestore();

        const postDoc = await db.collection("posts").doc(postId).get();

        if (!postDoc.exists) {
          console.log("Post not found");
          return null;
        }

        const postData = postDoc.data();
        const postOwnerId = postData.createdBy;

        if (commenterId === postOwnerId) {
          console.log("User commented on own post, skipping");
          return null;
        }

        // eslint-disable-next-line max-len
        const commenterDoc = await db.collection("users").doc(commenterId).get();

        if (!commenterDoc.exists) {
          console.log("Commenter not found");
          return null;
        }

        const commenterData = commenterDoc.data();
        const commenterName =
        `${commenterData.firstname || ""} ${
          commenterData.lastname || ""
        }`.trim() || "Someone";

        const ownerDoc = await db.collection("users").doc(postOwnerId).get();

        if (!ownerDoc.exists) {
          console.log("Owner not found");
          return null;
        }

        const ownerData = ownerDoc.data();
        const fcmToken = ownerData.fcmToken;

        if (!fcmToken) {
          console.log("No FCM token");
          return null;
        }

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
            },
          },
          apns: {payload: {aps: {sound: "default", badge: 1}}},
        };

        const response = await getMessaging().send(message);
        console.log("Comment notification sent:", response);
        return {success: true};
      } catch (error) {
        console.error("Error sending comment notification:", error);
        return null;
      }
    },
);

/**
 * Clean up FCM tokens when a user deletes their account
 */
exports.cleanupFCMToken = onDocumentDeleted("users/{userId}", async (event) => {
  const userId = event.params.userId;
  console.log(`Cleaning up FCM token for user: ${userId}`);
  return null;
});

/**
 * Batch send notifications
 * Requires authentication and has limits to prevent abuse
 */
exports.sendBatchNotifications = onCall(async (request) => {
  // Require authentication
  const userId = requireAuth(request);

  const {tokens, title, body, data: notificationData} = request.data;

  // Validate tokens array
  if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
    throw new HttpsError(
        "invalid-argument",
        "tokens must be a non-empty array",
    );
  }

  // Limit batch size to prevent abuse
  const MAX_BATCH_SIZE = 500;
  if (tokens.length > MAX_BATCH_SIZE) {
    throw new HttpsError(
        "invalid-argument",
        `Cannot send to more than ${MAX_BATCH_SIZE} tokens at once`,
    );
  }

  // Validate all tokens
  const validTokens = tokens.filter((token) => isValidFCMToken(token));
  if (validTokens.length === 0) {
    throw new HttpsError("invalid-argument", "No valid FCM tokens provided");
  }

  // Validate title and body
  if (!title || !body) {
    throw new HttpsError("invalid-argument", "title and body are required");
  }

  // Sanitize inputs
  const sanitizedTitle = sanitizeString(title, 100);
  const sanitizedBody = sanitizeString(body, 500);

  // Validate notification data
  if (notificationData && typeof notificationData !== "object") {
    throw new HttpsError(
        "invalid-argument",
        "Notification data must be an object",
    );
  }

  const message = {
    notification: {
      title: sanitizedTitle,
      body: sanitizedBody,
    },
    data: notificationData || {},
    android: {priority: "high", notification: {sound: "default"}},
    apns: {payload: {aps: {sound: "default"}}},
  };

  try {
    const response = await getMessaging().sendEachForMulticast({
      ...message,
      tokens: validTokens,
    });

    console.log(
        `Batch sent by user ${userId}. ` +
        `Success: ${response.successCount}, ` +
        `Failed: ${response.failureCount}`,
    );

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      totalRequested: tokens.length,
      validTokensUsed: validTokens.length,
    };
  } catch (error) {
    console.error("Error sending batch notifications:", error);
    throw new HttpsError("internal", "Failed to send batch notifications");
  }
});

/**
 * Send notification when a new message is received
 * Triggered when a new message is created in a chat
 */
exports.sendMessageNotification = onDocumentCreated(
    "chats/{chatId}/messages/{messageId}",
    async (event) => {
      try {
        const chatId = event.params.chatId;
        const messageData = event.data.data();
        const senderId = messageData.senderId;
        const messageText = messageData.text || "";
        const db = getFirestore();

        // Get chat metadata to find the recipient
        const chatDoc = await db.collection("chats").doc(chatId).get();

        if (!chatDoc.exists) {
          console.log("Chat not found");
          return null;
        }

        const chatData = chatDoc.data();
        const participants = chatData.participants || [];

        // Find the recipient (the user who is not the sender)
        const recipientId = participants.find((id) => id !== senderId);

        if (!recipientId) {
          console.log("No recipient found");
          return null;
        }

        // Get sender's information
        const senderDoc = await db.collection("users").doc(senderId).get();

        if (!senderDoc.exists) {
          console.log("Sender not found");
          return null;
        }

        const senderData = senderDoc.data();
        const senderName =
        `${senderData.firstname || ""} ${senderData.lastname || ""}`.trim() ||
        "Someone";

        // Get recipient's FCM token
        const recipientDoc = await db.collection("users").doc(recipientId).get();

        if (!recipientDoc.exists) {
          console.log("Recipient not found");
          return null;
        }

        const recipientData = recipientDoc.data();
        const fcmToken = recipientData.fcmToken;

        if (!fcmToken || !isValidFCMToken(fcmToken)) {
          console.log("No valid FCM token for recipient");
          return null;
        }

        // Create message preview (limit to 100 characters)
        const messagePreview =
        messageText.length > 100 ?
          messageText.substring(0, 100) + "..." :
          messageText;

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
            },
          },
          apns: {payload: {aps: {sound: "default", badge: 1}}},
        };

        const response = await getMessaging().send(message);
        console.log("Message notification sent:", response);
        return {success: true};
      } catch (error) {
        console.error("Error sending message notification:", error);
        return null;
      }
    },
);

/**
 * Send notification when a report is reviewed/updated
 * Triggered when a report document is updated
 */
exports.sendReportUpdateNotification = onDocumentUpdated(
    "reports/{reportId}",
    async (event) => {
      try {
        const newData = event.data.after.data();
        const previousData = event.data.before.data();

        // Only send notification if status changed
        if (newData.status === previousData.status) {
          console.log("Report status unchanged, skipping notification");
          return null;
        }

        const reportedBy = newData.reportedBy;
        if (!reportedBy) {
          console.log("No reporter ID found");
          return null;
        }

        // Get reporter's FCM token
        const userDoc = await getFirestore()
            .collection("users")
            .doc(reportedBy)
            .get();

        if (!userDoc.exists) {
          console.log(`User ${reportedBy} not found`);
          return null;
        }

        const fcmToken = userDoc.data().fcmToken;
        if (!fcmToken || !isValidFCMToken(fcmToken)) {
          console.log(`No valid FCM token for user ${reportedBy}`);
          return null;
        }

        // Determine notification message based on status
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
            // eslint-disable-next-line max-len
            notificationBody =
            // eslint-disable-next-line max-len
            "Your report has been reviewed and appropriate action has been taken. Thank you for helping keep our community safe.";
            break;
          case "dismissed":
            notificationTitle = "Report Update";
            // eslint-disable-next-line max-len
            notificationBody =
            // eslint-disable-next-line max-len
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
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
          token: fcmToken,
        };

        await getMessaging().send(message);
        console.log(`Report update notification sent to user ${reportedBy}`);

        return null;
      } catch (error) {
        console.error("Error sending report update notification:", error);
        return null;
      }
    },
);
