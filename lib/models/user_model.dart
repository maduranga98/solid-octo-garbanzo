import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String firstname;
  final String lastname;
  final String email;
  final String userName;
  final List<String> type;
  final String country;
  final String? photoURl;
  final int postCount;
  final int followersCount;
  final int followingCount;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.userName,
    required this.type,
    required this.country,
    this.photoURl,
    required this.postCount,
    required this.followersCount,
    required this.followingCount,
    required this.createdAt,
  });

  // ✅ FIXED: Added proper null safety handling
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    print(data);
    return UserModel(
      uid: data['uid'] ?? '',
      firstname: data['firstname'] ?? '',
      lastname: data['lastname'] ?? '',
      email: data['email'] ?? '',
      userName: data['username'] ?? '',
      type: data['type'] != null
          ? List<String>.from(data['type'] as List<dynamic>)
          : <String>[],
      country: data['country'] ?? '',
      photoURl: data['photoURl'], // This can be null
      postCount: data['postCount'] ?? 0,
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // ✅ FIXED: Added proper null safety handling
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
      photoURl: data['photoURl'], // This can be null
      postCount: data['postCount'] ?? 0,
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Convert UserModel -> firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      "uid": uid,
      "firstname": firstname,
      "lastname": lastname,
      "email": email,
      "userName": userName,
      "type": type,
      "country": country,
      "photoURl": photoURl,
      "postCount": postCount,
      "followersCount": followersCount,
      "followingCount": followingCount,
      "createdAt": Timestamp.fromDate(createdAt),
    };
  }

  // For updates
  UserModel copyWith({
    String? firstname,
    String? lastname,
    String? email,
    String? userName,
    List<String>? type,
    String? country,
    String? photoURl,
    int? postCount,
    int? followersCount,
    int? followingCount,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid, // uid never changes
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      email: email ?? this.email,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      country: country ?? this.country,
      photoURl: photoURl ?? this.photoURl,
      postCount: postCount ?? this.postCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
