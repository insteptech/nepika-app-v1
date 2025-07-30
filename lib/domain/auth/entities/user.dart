
class User {
  final String id;
  final String email;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final String? profileImage;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? height;
  final double? weight;
  final bool? isEmailVerified;
  final bool? isPhoneVerified;
  final bool? isOnboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    this.phone,
    this.firstName,
    this.lastName,
    this.profileImage,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.isEmailVerified,
    this.isPhoneVerified,
    this.isOnboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profileImage: json['profile_image'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      height: json['height'] != null
          ? (json['height'] as num).toDouble()
          : null,
      weight: json['weight'] != null
          ? (json['weight'] as num).toDouble()
          : null,
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
      isOnboardingCompleted: json['is_onboarding_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
