import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String firstname;
  final String lastname;
  final String email;
  final String userName;
  final List<String> type;
  final String country;
  final String? bio;
  final String? photoURl;
  final int postCount;
  final int followersCount;
  final int followingCount;
  final DateTime createdAt;

  // New fields for language preferences
  final List<String> preferredReadingLanguages;
  final String preferredWritingLanguage;
  final bool exploreInternational;

  // FCM token for push notifications
  final String? fcmToken;

  // Child safety and age verification fields
  final DateTime? dateOfBirth;
  final bool isAgeVerified;
  final bool requiresParentalConsent;
  final bool parentalConsentGiven;
  final DateTime? parentalConsentDate;
  final List<String> blockedUsers;

  UserModel({
    required this.uid,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.userName,
    required this.type,
    required this.country,
    this.bio,
    this.photoURl,
    required this.postCount,
    required this.followersCount,
    required this.followingCount,
    required this.createdAt,
    this.preferredReadingLanguages = const ['English'],
    this.preferredWritingLanguage = 'English',
    this.exploreInternational = true,
    this.fcmToken,
    this.dateOfBirth,
    this.isAgeVerified = false,
    this.requiresParentalConsent = false,
    this.parentalConsentGiven = false,
    this.parentalConsentDate,
    this.blockedUsers = const [],
  });

  // Helper method to calculate age
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  // Check if user is a minor (under 18)
  bool get isMinor {
    final userAge = age;
    return userAge != null && userAge < 18;
  }

  // Check if user is under 13 (COPPA compliance)
  bool get isUnder13 {
    final userAge = age;
    return userAge != null && userAge < 13;
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: data['uid'] ?? '',
      firstname: data['firstname'] ?? '',
      lastname: data['lastname'] ?? '',
      email: data['email'] ?? '',
      userName: data['username'] ?? data['userName'],
      type: data['type'] != null
          ? List<String>.from(data['type'] as List<dynamic>)
          : <String>[],
      country: data['country'] ?? '',
      bio: data['bio'] ?? '',
      photoURl: data['photoURl'],
      postCount: data['postCount'] ?? 0,
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      preferredReadingLanguages: data['preferredReadingLanguages'] != null
          ? List<String>.from(
              data['preferredReadingLanguages'] as List<dynamic>,
            )
          : ['English'],
      preferredWritingLanguage: data['preferredWritingLanguage'] ?? 'English',
      exploreInternational: data['exploreInternational'] ?? true,
      fcmToken: data['fcmToken'],
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      isAgeVerified: data['isAgeVerified'] ?? false,
      requiresParentalConsent: data['requiresParentalConsent'] ?? false,
      parentalConsentGiven: data['parentalConsentGiven'] ?? false,
      parentalConsentDate: data['parentalConsentDate'] != null
          ? (data['parentalConsentDate'] as Timestamp).toDate()
          : null,
      blockedUsers: data['blockedUsers'] != null
          ? List<String>.from(data['blockedUsers'] as List<dynamic>)
          : [],
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      firstname: data['firstname'] ?? '',
      lastname: data['lastname'] ?? '',
      email: data['email'] ?? '',
      userName: data['userName'] ?? '',
      type: data['type'] != null
          ? List<String>.from(data['type'] as List<dynamic>)
          : <String>[],
      country: data['country'] ?? '',
      bio: data['bio'] ?? '',
      photoURl: data['photoURl'],
      postCount: data['postCount'] ?? 0,
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      preferredReadingLanguages: data['preferredReadingLanguages'] != null
          ? List<String>.from(
              data['preferredReadingLanguages'] as List<dynamic>,
            )
          : ['English'],
      preferredWritingLanguage: data['preferredWritingLanguage'] ?? 'English',
      exploreInternational: data['exploreInternational'] ?? true,
      fcmToken: data['fcmToken'],
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      isAgeVerified: data['isAgeVerified'] ?? false,
      requiresParentalConsent: data['requiresParentalConsent'] ?? false,
      parentalConsentGiven: data['parentalConsentGiven'] ?? false,
      parentalConsentDate: data['parentalConsentDate'] != null
          ? (data['parentalConsentDate'] as Timestamp).toDate()
          : null,
      blockedUsers: data['blockedUsers'] != null
          ? List<String>.from(data['blockedUsers'] as List<dynamic>)
          : [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "uid": uid,
      "firstname": firstname,
      "lastname": lastname,
      "email": email,
      "userName": userName,
      "type": type,
      "country": country,
      "bio": bio,
      "photoURl": photoURl,
      "postCount": postCount,
      "followersCount": followersCount,
      "followingCount": followingCount,
      "createdAt": Timestamp.fromDate(createdAt),
      "preferredReadingLanguages": preferredReadingLanguages,
      "preferredWritingLanguage": preferredWritingLanguage,
      "exploreInternational": exploreInternational,
      "fcmToken": fcmToken,
      "dateOfBirth": dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      "isAgeVerified": isAgeVerified,
      "requiresParentalConsent": requiresParentalConsent,
      "parentalConsentGiven": parentalConsentGiven,
      "parentalConsentDate": parentalConsentDate != null
          ? Timestamp.fromDate(parentalConsentDate!)
          : null,
      "blockedUsers": blockedUsers,
    };
  }

  UserModel copyWith({
    String? firstname,
    String? lastname,
    String? email,
    String? userName,
    List<String>? type,
    String? country,
    String? bio,
    String? photoURl,
    int? postCount,
    int? followersCount,
    int? followingCount,
    DateTime? createdAt,
    List<String>? preferredReadingLanguages,
    String? preferredWritingLanguage,
    bool? exploreInternational,
    String? fcmToken,
    DateTime? dateOfBirth,
    bool? isAgeVerified,
    bool? requiresParentalConsent,
    bool? parentalConsentGiven,
    DateTime? parentalConsentDate,
    List<String>? blockedUsers,
  }) {
    return UserModel(
      uid: uid,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      email: email ?? this.email,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      country: country ?? this.country,
      bio: bio ?? this.bio,
      photoURl: photoURl ?? this.photoURl,
      postCount: postCount ?? this.postCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      createdAt: createdAt ?? this.createdAt,
      preferredReadingLanguages:
          preferredReadingLanguages ?? this.preferredReadingLanguages,
      preferredWritingLanguage:
          preferredWritingLanguage ?? this.preferredWritingLanguage,
      exploreInternational: exploreInternational ?? this.exploreInternational,
      fcmToken: fcmToken ?? this.fcmToken,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      isAgeVerified: isAgeVerified ?? this.isAgeVerified,
      requiresParentalConsent: requiresParentalConsent ?? this.requiresParentalConsent,
      parentalConsentGiven: parentalConsentGiven ?? this.parentalConsentGiven,
      parentalConsentDate: parentalConsentDate ?? this.parentalConsentDate,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }
}
