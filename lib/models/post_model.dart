import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String docId;
  final String authorName;
  final String uid;
  final String title;
  final String description;
  final String plainText;
  final String richText;
  final String? fontFamily;
  final String workType;
  final String createdBy;
  final int? commentCount;
  final int? fontSize;
  final int? likeCount;
  final int? shareCount;
  final int? viewCount;
  final DateTime createdAt;

  PostModel({
    required this.docId,
    required this.authorName,
    required this.uid,
    required this.title,
    required this.description,
    required this.plainText,
    required this.richText,
    this.fontFamily,
    required this.workType,
    required this.createdBy,
    this.commentCount,
    this.fontSize,
    this.likeCount,
    this.shareCount,
    this.viewCount,
    required this.createdAt,
  });

  /// ✅ Helper method to safely convert dynamic to int
  static int? _safeToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// ✅ Firestore → PostModel
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    print("PostModel data: $data");

    return PostModel(
      docId: doc.id, // better to use doc.id for unique reference
      authorName: data['authorName'] ?? '',
      uid: data['uid'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      plainText: data['plainText'] ?? '',
      richText: data['richText'] ?? '',
      fontFamily: data['fontFamily'],
      createdBy: data['createdBy'],
      workType: data['workType'] ?? '',
      // ✅ Fix: Safe conversion from double/dynamic to int
      commentCount: _safeToInt(data['commentCount']),
      fontSize: _safeToInt(data['fontSize']),
      likeCount: _safeToInt(data['likeCount']),
      shareCount: _safeToInt(data['shareCount']),
      viewCount: _safeToInt(data['viewCount']),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// ✅ Map → PostModel
  factory PostModel.fromMap(Map<String, dynamic> data, String docId) {
    return PostModel(
      docId: docId,
      authorName: data['authorName'] ?? '',
      uid: data['uid'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      plainText: data['plainText'] ?? '',
      richText: data['richText'] ?? '',
      fontFamily: data['fontFamily'],
      workType: data['workType'] ?? '',
      createdBy: data['createdBy'] ?? '',
      // ✅ Fix: Safe conversion from double/dynamic to int
      commentCount: _safeToInt(data['commentCount']),
      fontSize: _safeToInt(data['fontSize']),
      likeCount: _safeToInt(data['likeCount']),
      shareCount: _safeToInt(data['shareCount']),
      viewCount: _safeToInt(data['viewCount']),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// ✅ PostModel → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      "docId": docId,
      "authorName": authorName,
      "uid": uid,
      "title": title,
      "description": description,
      "plainText": plainText,
      "richText": richText,
      "fontFamily": fontFamily,
      "workType": workType,
      "commentCount": commentCount ?? 0,
      "fontSize": fontSize,
      "likeCount": likeCount ?? 0,
      "shareCount": shareCount ?? 0,
      "viewCount": viewCount ?? 0,
      "createdAt": Timestamp.fromDate(createdAt),
    };
  }

  /// ✅ CopyWith (update only certain fields)
  PostModel copyWith({
    required String docId,
    String? authorName,
    String? uid,
    String? title,
    String? description,
    String? plainText,
    String? richText,
    String? fontFamily,
    String? workType,
    int? commentCount,
    int? fontSize,
    int? likeCount,
    int? shareCount,
    int? viewCount,
    DateTime? createdAt,
  }) {
    return PostModel(
      docId: docId, // docId shouldn't change
      authorName: authorName ?? this.authorName,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      description: description ?? this.description,
      plainText: plainText ?? this.plainText,
      richText: richText ?? this.richText,
      fontFamily: fontFamily ?? this.fontFamily,
      workType: workType ?? this.workType,
      createdBy: createdBy,
      commentCount: commentCount ?? this.commentCount,
      fontSize: fontSize ?? this.fontSize,
      likeCount: likeCount ?? this.likeCount,
      shareCount: shareCount ?? this.shareCount,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods
  String get displayTitle => title.isNotEmpty ? title : 'Untitled';
  String get displayDescription =>
      description.isNotEmpty ? description : 'No description';
  String get previewText =>
      plainText.length > 100 ? '${plainText.substring(0, 100)}...' : plainText;

  bool get hasLikes => (likeCount ?? 0) > 0;
  bool get hasComments => (commentCount ?? 0) > 0;
  bool get hasShares => (shareCount ?? 0) > 0;
  bool get hasViews => (viewCount ?? 0) > 0;

  // Engagement metrics
  int get totalEngagement =>
      (likeCount ?? 0) + (commentCount ?? 0) + (shareCount ?? 0);

  @override
  String toString() {
    return 'PostModel(docId: $docId, title: $title, author: $authorName, workType: $workType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PostModel &&
        other.docId == docId &&
        other.authorName == authorName &&
        other.uid == uid &&
        other.title == title &&
        other.description == description &&
        other.plainText == plainText &&
        other.richText == richText &&
        other.fontFamily == fontFamily &&
        other.workType == workType &&
        other.commentCount == commentCount &&
        other.fontSize == fontSize &&
        other.likeCount == likeCount &&
        other.shareCount == shareCount &&
        other.viewCount == viewCount &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return docId.hashCode ^
        authorName.hashCode ^
        uid.hashCode ^
        title.hashCode ^
        description.hashCode ^
        plainText.hashCode ^
        richText.hashCode ^
        fontFamily.hashCode ^
        workType.hashCode ^
        commentCount.hashCode ^
        fontSize.hashCode ^
        likeCount.hashCode ^
        shareCount.hashCode ^
        viewCount.hashCode ^
        createdAt.hashCode;
  }
}
