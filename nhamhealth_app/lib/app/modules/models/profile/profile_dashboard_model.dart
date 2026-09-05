class ProfileDashboardModel {
  const ProfileDashboardModel({
    required this.userId,
    required this.email,
    this.fullName,
    this.profileImageUrl,
    this.membership,
    this.phone,
    this.phoneVerified = false,
    this.dateOfBirth,
    this.gender,
    this.age,
    this.heightCm,
    this.weightKg,
    this.calories,
    this.protein,
    this.fat,
    this.water,
    this.fiber,
    this.sugar,
    this.insight,
  });

  final int userId;
  final String email;
  final String? fullName;
  final String? profileImageUrl;
  final String? membership;
  final String? phone;
  final bool phoneVerified;
  final DateTime? dateOfBirth;
  final String? gender;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final ProfileProgressModel? calories;
  final ProfileProgressModel? protein;
  final ProfileProgressModel? fat;
  final ProfileProgressModel? water;
  final ProfileProgressModel? fiber;
  final ProfileProgressModel? sugar;
  final String? insight;

  factory ProfileDashboardModel.fromJson(Map<String, dynamic> json) {
    return ProfileDashboardModel(
      userId: (json['userId'] as num).toInt(),
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      membership: json['membership'] as String?,
      phone: json['phone'] as String?,
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      dateOfBirth: DateTime.tryParse(json['dateOfBirth'] as String? ?? ''),
      gender: json['gender'] as String?,
      age: (json['age'] as num?)?.toInt(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      calories: _progress(json['calories']),
      protein: _progress(json['protein']),
      fat: _progress(json['fat']),
      water: _progress(json['water']),
      fiber: _progress(json['fiber']),
      sugar: _progress(json['sugar']),
      insight: json['insight'] as String?,
    );
  }

  static ProfileProgressModel? _progress(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    return ProfileProgressModel.fromJson(value);
  }
}

class ProfileProgressModel {
  const ProfileProgressModel({required this.current, required this.goal});

  final double current;
  final double goal;

  factory ProfileProgressModel.fromJson(Map<String, dynamic> json) {
    return ProfileProgressModel(
      current: (json['current'] as num?)?.toDouble() ?? 0,
      goal: (json['goal'] as num?)?.toDouble() ?? 0,
    );
  }
}
