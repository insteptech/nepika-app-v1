import 'package:json_annotation/json_annotation.dart';
import '../../../domain/auth/entities/user.dart';

// part 'user_model.g.dart'; // Commented until code generation

@JsonSerializable()
class UserModel extends User {
  const UserModel({
    required super.id,
    super.email,
    super.phone,
    super.firstName,
    super.lastName,
    super.profileImage,
    super.dateOfBirth,
    super.gender,
    super.height,
    super.weight,
    super.isEmailVerified,
    super.isPhoneVerified,
    required super.onboardingCompleted,
    required super.activeStep,
    super.createdAt,
    super.updatedAt,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
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
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      activeStep: json['active_step'] as int ? ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'first_name': firstName,
      'last_name': lastName,
      'profile_image': profileImage,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'height': height,
      'weight': weight,
      'is_email_verified': isEmailVerified,
      'is_phone_verified': isPhoneVerified,
      'onboarding_completed': onboardingCompleted,
      'active_step': activeStep,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
  
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      phone: user.phone,
      firstName: user.firstName,
      lastName: user.lastName,
      profileImage: user.profileImage,
      dateOfBirth: user.dateOfBirth,
      gender: user.gender,
      height: user.height,
      weight: user.weight,
      isEmailVerified: user.isEmailVerified,
      isPhoneVerified: user.isPhoneVerified,
      onboardingCompleted: user.onboardingCompleted,
      activeStep: user.activeStep,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }
  
  User toEntity() {
    return User(
      id: id,
      email: email,
      phone: phone,
      firstName: firstName,
      lastName: lastName,
      profileImage: profileImage,
      dateOfBirth: dateOfBirth,
      gender: gender,
      height: height,
      weight: weight,
      isEmailVerified: isEmailVerified,
      isPhoneVerified: isPhoneVerified,
      onboardingCompleted: onboardingCompleted,
      activeStep: activeStep,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
  
  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    String? profileImage,
    DateTime? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? onboardingCompleted,
    int? activeStep,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImage: profileImage ?? this.profileImage,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      activeStep: activeStep ?? this.activeStep,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
