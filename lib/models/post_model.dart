import 'user_model.dart';
import 'pet_model.dart';

class PostModel {
  final String id;
  final UserModel? author;
  final PetModel? pet;
  final String? content;
  final List<String> mediaUrls;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? checkInLocation;
  final List<Map<String, dynamic>>? petTags;

  PostModel({
    required this.id,
    this.author,
    this.pet,
    this.content,
    this.mediaUrls = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.createdAt,
    this.updatedAt,
    this.checkInLocation,
    this.petTags,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    UserModel? parsedAuthor;
    if (json['authorId'] is Map<String, dynamic>) {
      parsedAuthor = UserModel.fromJson(json['authorId']);
    } else if (json['author'] is Map<String, dynamic>) {
      parsedAuthor = UserModel.fromJson(json['author']);
    }

    PetModel? parsedPet;
    if (json['petId'] is Map<String, dynamic>) {
      parsedPet = PetModel.fromJson(json['petId']);
    } else if (json['pet'] is Map<String, dynamic>) {
      parsedPet = PetModel.fromJson(json['pet']);
    }

    List<String> media = [];
    if (json['mediaUrls'] is List) {
      media = (json['mediaUrls'] as List).map((e) => e.toString()).toList();
    } else if (json['images'] is List) {
      media = (json['images'] as List).map((e) => e.toString()).toList();
    }

    return PostModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      author: parsedAuthor,
      pet: parsedPet,
      content: json['content']?.toString() ?? json['caption']?.toString(),
      mediaUrls: media,
      likeCount: json['likeCount'] is int ? json['likeCount'] as int : int.tryParse(json['likeCount']?.toString() ?? '') ?? 0,
      commentCount: json['commentCount'] is int ? json['commentCount'] as int : int.tryParse(json['commentCount']?.toString() ?? '') ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
      checkInLocation: json['checkInLocation']?.toString() ?? json['location']?.toString(),
      petTags: json['petTags'] is List ? (json['petTags'] as List).cast<Map<String, dynamic>>() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,    // CommentSheet và các widget dùng 'id'
      '_id': id,   // Giữ backward compat với code cũ dùng '_id'
      'author': author?.toJson(),
      'pet': pet?.toJson(),
      'content': content,
      'mediaUrls': mediaUrls,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isLiked': isLiked,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'checkInLocation': checkInLocation,
      'petTags': petTags,
    };
  }
}
