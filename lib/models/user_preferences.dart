class UserPreferences {
  final String themeMode;
  final String presetTheme;
  final String language;
  final String weightUnit;
  final bool notifyFeeding;
  final bool notifyHealth;
  final bool notifySocial;
  final bool notifyBooking;
  final String? featuredPetId;

  UserPreferences({
    this.themeMode = 'light',
    this.presetTheme = 'sakura',
    this.language = 'vi',
    this.weightUnit = 'kg',
    this.notifyFeeding = true,
    this.notifyHealth = true,
    this.notifySocial = true,
    this.notifyBooking = true,
    this.featuredPetId,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    String tMode = json['themeMode']?.toString() ?? 'light';
    if (tMode == 'system') tMode = 'light';

    return UserPreferences(
      themeMode: tMode,
      presetTheme: json['presetTheme'] ?? 'sakura',
      language: json['language'] ?? 'vi',
      weightUnit: json['weightUnit'] ?? 'kg',
      notifyFeeding: json['notifyFeeding'] ?? true,
      notifyHealth: json['notifyHealth'] ?? true,
      notifySocial: json['notifySocial'] ?? true,
      notifyBooking: json['notifyBooking'] ?? true,
      featuredPetId: json['featuredPetId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'presetTheme': presetTheme,
      'language': language,
      'weightUnit': weightUnit,
      'notifyFeeding': notifyFeeding,
      'notifyHealth': notifyHealth,
      'notifySocial': notifySocial,
      'notifyBooking': notifyBooking,
      'featuredPetId': featuredPetId,
    };
  }

  UserPreferences copyWith({
    String? themeMode,
    String? presetTheme,
    String? language,
    String? weightUnit,
    bool? notifyFeeding,
    bool? notifyHealth,
    bool? notifySocial,
    bool? notifyBooking,
    String? featuredPetId,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      presetTheme: presetTheme ?? this.presetTheme,
      language: language ?? this.language,
      weightUnit: weightUnit ?? this.weightUnit,
      notifyFeeding: notifyFeeding ?? this.notifyFeeding,
      notifyHealth: notifyHealth ?? this.notifyHealth,
      notifySocial: notifySocial ?? this.notifySocial,
      notifyBooking: notifyBooking ?? this.notifyBooking,
      featuredPetId: featuredPetId ?? this.featuredPetId,
    );
  }
}
