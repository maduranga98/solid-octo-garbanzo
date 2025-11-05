/**
 * Firebase Cloud Functions for Push Notifications
 */

const {onCall} = require("firebase-functions/v2/https");
const {
  onDocumentCreated,
  onDocumentDeleted,
} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

/**
 * Send a push notification to a specific user
 */
exports.sendNotification = onCall(async (request) => {
  const {token, title, body, data: notificationData} = request.data;

  if (!token || !title || !body) {
    throw new Error("Missing required parameters");
  }

  const message = {
    notification: {title, body},
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
    console.log("Notification sent:", response);
    return {success: true, messageId: response};
  } catch (error) {
    console.error("Error sending notification:", error);
    throw new Error("Failed to send notification");
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
 */
exports.sendBatchNotifications = onCall(async (request) => {
  const {tokens, title, body, data: notificationData} = request.data;

  if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
    throw new Error("tokens must be a non-empty array");
  }

  if (!title || !body) {
    throw new Error("title and body are required");
  }

  const message = {
    notification: {title, body},
    data: notificationData || {},
    android: {priority: "high", notification: {sound: "default"}},
    apns: {payload: {aps: {sound: "default"}}},
  };

  try {
    const response = await getMessaging().sendEachForMulticast({
      ...message,
      tokens: tokens,
    });

    console.log(
        `Batch sent. Success: ${response.successCount}, ` +
        `Failed: ${response.failureCount}`,
    );

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      responses: response.responses,
    };
  } catch (error) {
    console.error("Error sending batch notifications:", error);
    throw new Error("Failed to send batch notifications");
  }
});
