class UserModel {
  final String id;
  final String? username;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final String? fcmToken;
  final int? followersCount;
  final int? followingCount;
  final bool? isVerified;

  UserModel({
    required this.id,
    this.username,
    this.displayName,
    this.email,
    this.avatarUrl,
    this.fcmToken,
    this.followersCount,
    this.followingCount,
    this.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username']?.toString(),
      displayName: json['displayName']?.toString() ?? json['fullName']?.toString(),
      email: json['email']?.toString(),
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar']?.toString(),
      fcmToken: json['fcmToken']?.toString(),
      followersCount: json['followersCount'] is int ? json['followersCount'] as int : int.tryParse(json['followersCount']?.toString() ?? '') ?? 0,
      followingCount: json['followingCount'] is int ? json['followingCount'] as int : int.tryParse(json['followingCount']?.toString() ?? '') ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'fcmToken': fcmToken,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'isVerified': isVerified,
    };
  }
}
