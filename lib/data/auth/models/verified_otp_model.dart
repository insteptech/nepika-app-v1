// import 'package:json_annotation/json_annotation.dart';
// import '../../../domain/auth/entities/user.dart';

// // part 'user_model.g.dart'; // Commented until code generation

// @JsonSerializable()
// class OtpResponseModel {
//   const OtpResponseModel({
//     required this.userId,
//     required this.email,
//   });

//   final String userId;
//   final String email;

//   factory OtpResponseModel.fromJson(Map<String, dynamic> json) {
//     return OtpResponseModel(
//       userId: json['userId'] as String,
//       email: json['email'] as String,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'userId': userId,
//       'email': email,
//     };
//   }
// }

//     super.lastName,
//     super.profileImage,
//     super.dateOfBirth,
//     super.gender,
//     super.height,
//     super.weight,
//     super.isEmailVerified,
//     super.isPhoneVerified,
//     super.isOnboardingCompleted,
//     required super.createdAt,
//     required super.updatedAt,
//   });
  
//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     return UserModel(
//       id: json['id'] as String,
//       email: json['email'] as String,
//       phone: json['phone'] as String?,
//       firstName: json['first_name'] as String?,
//       lastName: json['last_name'] as String?,
//       profileImage: json['profile_image'] as String?,
//       dateOfBirth: json['date_of_birth'] != null 
//           ? DateTime.parse(json['date_of_birth'] as String)
//           : null,
//       gender: json['gender'] as String?,
//       height: json['height'] != null 
//           ? (json['height'] as num).toDouble()
//           : null,
//       weight: json['weight'] != null 
//           ? (json['weight'] as num).toDouble()
//           : null,
//       isEmailVerified: json['is_email_verified'] as bool? ?? false,
//       isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
//       isOnboardingCompleted: json['is_onboarding_completed'] as bool? ?? false,
//       createdAt: DateTime.parse(json['created_at'] as String),
//       updatedAt: DateTime.parse(json['updated_at'] as String),
//     );
//   }
  
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'email': email,
//       'phone': phone,
//       'first_name': firstName,
//       'last_name': lastName,
//       'profile_image': profileImage,
//       'date_of_birth': dateOfBirth?.toIso8601String(),
//       'gender': gender,
//       'height': height,
//       'weight': weight,
//       'is_email_verified': isEmailVerified,
//       'is_phone_verified': isPhoneVerified,
//       'is_onboarding_completed': isOnboardingCompleted,
//       'created_at': createdAt.toIso8601String(),
//       'updated_at': updatedAt.toIso8601String(),
//     };
//   }
  
//   factory UserModel.fromEntity(User user) {
//     return UserModel(
//       id: user.id,
//       email: user.email,
//       phone: user.phone,
//       firstName: user.firstName,
//       lastName: user.lastName,
//       profileImage: user.profileImage,
//       dateOfBirth: user.dateOfBirth,
//       gender: user.gender,
//       height: user.height,
//       weight: user.weight,
//       isEmailVerified: user.isEmailVerified,
//       isPhoneVerified: user.isPhoneVerified,
//       isOnboardingCompleted: user.isOnboardingCompleted,
//       createdAt: user.createdAt,
//       updatedAt: user.updatedAt,
//     );
//   }
  
//   User toEntity() {
//     return User(
//       id: id,
//       email: email,
//       phone: phone,
//       firstName: firstName,
//       lastName: lastName,
//       profileImage: profileImage,
//       dateOfBirth: dateOfBirth,
//       gender: gender,
//       height: height,
//       weight: weight,
//       isEmailVerified: isEmailVerified,
//       isPhoneVerified: isPhoneVerified,
//       isOnboardingCompleted: isOnboardingCompleted,
//       createdAt: createdAt,
//       updatedAt: updatedAt,
//     );
//   }
  
//   UserModel copyWith({
//     String? id,
//     String? email,
//     String? phone,
//     String? firstName,
//     String? lastName,
//     String? profileImage,
//     DateTime? dateOfBirth,
//     String? gender,
//     double? height,
//     double? weight,
//     bool? isEmailVerified,
//     bool? isPhoneVerified,
//     bool? isOnboardingCompleted,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//   }) {
//     return UserModel(
//       id: id ?? this.id,
//       email: email ?? this.email,
//       phone: phone ?? this.phone,
//       firstName: firstName ?? this.firstName,
//       lastName: lastName ?? this.lastName,
//       profileImage: profileImage ?? this.profileImage,
//       dateOfBirth: dateOfBirth ?? this.dateOfBirth,
//       gender: gender ?? this.gender,
//       height: height ?? this.height,
//       weight: weight ?? this.weight,
//       isEmailVerified: isEmailVerified ?? this.isEmailVerified,
//       isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
//       isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//     );
//   }
// }
