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
    this.carbs,
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
  final ProfileProgressModel? carbs;
  final ProfileProgressModel? fat;
  final ProfileProgressModel? water;
  final ProfileProgressModel? fiber;
  final ProfileProgressModel? sugar;
  final String? insight;

  factory ProfileDashboardModel.fromJson(Map<String, dynamic> json) {
    return ProfileDashboardModel(
      userId: (json['userId'] as num).toInt(),
      email: json['email'] as String? ?? '',
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
      carbs: _progress(json['carbs']),
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

  ProfileDashboardModel copyWith({
    int? userId,
    String? email,
    String? fullName,
    String? profileImageUrl,
    String? membership,
    String? phone,
    bool? phoneVerified,
    DateTime? dateOfBirth,
    String? gender,
    int? age,
    double? heightCm,
    double? weightKg,
    ProfileProgressModel? calories,
    ProfileProgressModel? protein,
    ProfileProgressModel? carbs,
    ProfileProgressModel? fat,
    ProfileProgressModel? water,
    ProfileProgressModel? fiber,
    ProfileProgressModel? sugar,
    String? insight,
  }) {
    return ProfileDashboardModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      membership: membership ?? this.membership,
      phone: phone ?? this.phone,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      water: water ?? this.water,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      insight: insight ?? this.insight,
    );
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

  ProfileProgressModel copyWith({
    double? current,
    double? goal,
  }) {
    return ProfileProgressModel(
      current: current ?? this.current,
      goal: goal ?? this.goal,
    );
  }
}
