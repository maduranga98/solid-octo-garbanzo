import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_model.dart';
import '../models/block_model.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(firestore: FirebaseFirestore.instance);
});

class ReportRepository {
  final FirebaseFirestore _firestore;

  ReportRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  // Submit a report
  Future<void> submitReport(ReportModel report) async {
    try {
      await _firestore.collection('reports').add(report.toMap());
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  // Get reports submitted by a user
  Stream<List<ReportModel>> getUserReports(String userId) {
    return _firestore
        .collection('reports')
        .where('reportedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get a specific report by ID
  Future<ReportModel?> getReportById(String reportId) async {
    try {
      final doc = await _firestore.collection('reports').doc(reportId).get();
      if (doc.exists) {
        return ReportModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get report: $e');
    }
  }

  // Block a user
  Future<void> blockUser(BlockModel block) async {
    try {
      await _firestore
          .collection('users')
          .doc(block.blockedBy)
          .collection('blockedUsers')
          .doc(block.blockedUserId)
          .set(block.toMap());

      // Also update the blockedUsers array in the user document
      await _firestore.collection('users').doc(block.blockedBy).update({
        'blockedUsers': FieldValue.arrayUnion([block.blockedUserId]),
      });
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  // Unblock a user
  Future<void> unblockUser(String currentUserId, String blockedUserId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(blockedUserId)
          .delete();

      // Also update the blockedUsers array in the user document
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayRemove([blockedUserId]),
      });
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  // Get list of blocked users
  Stream<List<BlockModel>> getBlockedUsers(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('blockedUsers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BlockModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Check if a user is blocked
  Future<bool> isUserBlocked(String currentUserId, String otherUserId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(otherUserId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Report a post
  Future<void> reportPost({
    required String reportedBy,
    required String reporterEmail,
    required String reporterName,
    required String postId,
    required String postTitle,
    required String postAuthor,
    required ReportReason reason,
    required String description,
    String? subject,
  }) async {
    final report = ReportModel(
      docId: '',
      reportedBy: reportedBy,
      reporterEmail: reporterEmail,
      reporterName: reporterName,
      reportType: ReportType.post,
      reason: reason,
      subject: subject,
      description: description,
      status: ReportStatus.pending,
      createdAt: DateTime.now(),
      postId: postId,
      postTitle: postTitle,
      postAuthor: postAuthor,
    );
    await submitReport(report);
  }

  // Report a comment
  Future<void> reportComment({
    required String reportedBy,
    required String reporterEmail,
    required String reporterName,
    required String postId,
    required String commentId,
    required String commentText,
    required String commentAuthor,
    required ReportReason reason,
    required String description,
    String? subject,
  }) async {
    final report = ReportModel(
      docId: '',
      reportedBy: reportedBy,
      reporterEmail: reporterEmail,
      reporterName: reporterName,
      reportType: ReportType.comment,
      reason: reason,
      subject: subject,
      description: description,
      status: ReportStatus.pending,
      createdAt: DateTime.now(),
      postId: postId,
      commentId: commentId,
      commentText: commentText,
      commentAuthor: commentAuthor,
    );
    await submitReport(report);
  }

  // Report a profile
  Future<void> reportProfile({
    required String reportedBy,
    required String reporterEmail,
    required String reporterName,
    required String profileId,
    required String profileUsername,
    required ReportReason reason,
    required String description,
    String? subject,
  }) async {
    final report = ReportModel(
      docId: '',
      reportedBy: reportedBy,
      reporterEmail: reporterEmail,
      reporterName: reporterName,
      reportType: ReportType.profile,
      reason: reason,
      subject: subject,
      description: description,
      status: ReportStatus.pending,
      createdAt: DateTime.now(),
      profileId: profileId,
      profileUsername: profileUsername,
    );
    await submitReport(report);
  }

  // Report a message
  Future<void> reportMessage({
    required String reportedBy,
    required String reporterEmail,
    required String reporterName,
    required String chatId,
    required String messageId,
    required String messageText,
    required String messageAuthor,
    required ReportReason reason,
    required String description,
    String? subject,
  }) async {
    final report = ReportModel(
      docId: '',
      reportedBy: reportedBy,
      reporterEmail: reporterEmail,
      reporterName: reporterName,
      reportType: ReportType.message,
      reason: reason,
      subject: subject,
      description: description,
      status: ReportStatus.pending,
      createdAt: DateTime.now(),
      chatId: chatId,
      messageId: messageId,
      messageText: messageText,
      messageAuthor: messageAuthor,
    );
    await submitReport(report);
  }
}
