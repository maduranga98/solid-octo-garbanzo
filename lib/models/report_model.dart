import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportType {
  post,
  comment,
  profile,
  message,
}

enum ReportReason {
  harassment,
  spam,
  inappropriateContent,
  violence,
  hateSpeech,
  childSafety,
  sexualContent,
  falseInformation,
  other,
}

enum ReportStatus {
  pending,
  underReview,
  resolved,
  dismissed,
}

class ReportModel {
  final String docId;
  final String reportedBy;
  final String reporterEmail;
  final String reporterName;
  final ReportType reportType;
  final ReportReason reason;
  final String? subject;
  final String description;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewNotes;

  // Content-specific fields
  final String? postId;
  final String? postTitle;
  final String? postAuthor;
  final String? commentId;
  final String? commentText;
  final String? commentAuthor;
  final String? profileId;
  final String? profileUsername;
  final String? messageId;
  final String? chatId;
  final String? messageText;
  final String? messageAuthor;

  ReportModel({
    required this.docId,
    required this.reportedBy,
    required this.reporterEmail,
    required this.reporterName,
    required this.reportType,
    required this.reason,
    this.subject,
    required this.description,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewNotes,
    this.postId,
    this.postTitle,
    this.postAuthor,
    this.commentId,
    this.commentText,
    this.commentAuthor,
    this.profileId,
    this.profileUsername,
    this.messageId,
    this.chatId,
    this.messageText,
    this.messageAuthor,
  });

  Map<String, dynamic> toMap() {
    return {
      'reportedBy': reportedBy,
      'reporterEmail': reporterEmail,
      'reporterName': reporterName,
      'reportType': reportType.name,
      'reason': reason.name,
      'subject': subject,
      'description': description,
      'status': status.name,
      'createdAt': createdAt,
      'reviewedAt': reviewedAt,
      'reviewNotes': reviewNotes,
      'postId': postId,
      'postTitle': postTitle,
      'postAuthor': postAuthor,
      'commentId': commentId,
      'commentText': commentText,
      'commentAuthor': commentAuthor,
      'profileId': profileId,
      'profileUsername': profileUsername,
      'messageId': messageId,
      'chatId': chatId,
      'messageText': messageText,
      'messageAuthor': messageAuthor,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReportModel(
      docId: docId,
      reportedBy: map['reportedBy'] ?? '',
      reporterEmail: map['reporterEmail'] ?? '',
      reporterName: map['reporterName'] ?? '',
      reportType: ReportType.values.firstWhere(
        (e) => e.name == map['reportType'],
        orElse: () => ReportType.post,
      ),
      reason: ReportReason.values.firstWhere(
        (e) => e.name == map['reason'],
        orElse: () => ReportReason.other,
      ),
      subject: map['subject'],
      description: map['description'] ?? '',
      status: ReportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReportStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewNotes: map['reviewNotes'],
      postId: map['postId'],
      postTitle: map['postTitle'],
      postAuthor: map['postAuthor'],
      commentId: map['commentId'],
      commentText: map['commentText'],
      commentAuthor: map['commentAuthor'],
      profileId: map['profileId'],
      profileUsername: map['profileUsername'],
      messageId: map['messageId'],
      chatId: map['chatId'],
      messageText: map['messageText'],
      messageAuthor: map['messageAuthor'],
    );
  }

  ReportModel copyWith({
    String? docId,
    String? reportedBy,
    String? reporterEmail,
    String? reporterName,
    ReportType? reportType,
    ReportReason? reason,
    String? subject,
    String? description,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewNotes,
    String? postId,
    String? postTitle,
    String? postAuthor,
    String? commentId,
    String? commentText,
    String? commentAuthor,
    String? profileId,
    String? profileUsername,
    String? messageId,
    String? chatId,
    String? messageText,
    String? messageAuthor,
  }) {
    return ReportModel(
      docId: docId ?? this.docId,
      reportedBy: reportedBy ?? this.reportedBy,
      reporterEmail: reporterEmail ?? this.reporterEmail,
      reporterName: reporterName ?? this.reporterName,
      reportType: reportType ?? this.reportType,
      reason: reason ?? this.reason,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      postId: postId ?? this.postId,
      postTitle: postTitle ?? this.postTitle,
      postAuthor: postAuthor ?? this.postAuthor,
      commentId: commentId ?? this.commentId,
      commentText: commentText ?? this.commentText,
      commentAuthor: commentAuthor ?? this.commentAuthor,
      profileId: profileId ?? this.profileId,
      profileUsername: profileUsername ?? this.profileUsername,
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      messageText: messageText ?? this.messageText,
      messageAuthor: messageAuthor ?? this.messageAuthor,
    );
  }

  String getReasonDisplayText() {
    switch (reason) {
      case ReportReason.harassment:
        return 'Harassment or Bullying';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.violence:
        return 'Violence or Threats';
      case ReportReason.hateSpeech:
        return 'Hate Speech';
      case ReportReason.childSafety:
        return 'Child Safety Concern';
      case ReportReason.sexualContent:
        return 'Sexual Content';
      case ReportReason.falseInformation:
        return 'False Information';
      case ReportReason.other:
        return 'Other';
    }
  }

  String getStatusDisplayText() {
    switch (status) {
      case ReportStatus.pending:
        return 'Pending Review';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.dismissed:
        return 'Dismissed';
    }
  }
}
