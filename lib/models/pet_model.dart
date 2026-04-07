class PetModel {
  final String id;
  final String? ownerId;
  final String name;
  final String? species;
  final String? breed;
  final String? avatarUrl;
  final String? gender;
  final DateTime? birthDate;
  final double? weight;
  final String? currentFoodId;

  PetModel({
    required this.id,
    this.ownerId,
    required this.name,
    this.species,
    this.breed,
    this.avatarUrl,
    this.gender,
    this.birthDate,
    this.weight,
    this.currentFoodId,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? json['owner']?.toString(),
      name: json['name']?.toString() ?? 'Unknown Pet',
      species: json['species']?.toString(),
      breed: json['breed']?.toString(),
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar']?.toString(),
      gender: json['gender']?.toString(),
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate'].toString()) : null,
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) : null,
      currentFoodId: json['currentFoodId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'ownerId': ownerId,
      'name': name,
      'species': species,
      'breed': breed,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'weight': weight,
      'currentFoodId': currentFoodId,
    };
  }
}
