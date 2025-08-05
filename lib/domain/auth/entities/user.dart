class User {
  final String id;
  final String? email;
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
  final bool onboardingCompleted;
  final String activeStep;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    this.email,
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
    required this.onboardingCompleted,
    required this.activeStep,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profileImage: json['profile_image'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      height: json['height'] != null
          ? (json['height'] as num).toDouble()
          : null,
      weight: json['weight'] != null
          ? (json['weight'] as num).toDouble()
          : null,
      isEmailVerified: json['is_email_verified'] as bool?,
      isPhoneVerified: json['is_phone_verified'] as bool?,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      activeStep: json['active_step'] as String? ?? 'user_info',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

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
}

class AuthResponse {
  final String otp;
  final String phone;
  final User user;
  final String token;
  final String refreshToken;

  AuthResponse({
    required this.otp,
    required this.phone,
    required this.user,
    required this.token,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // The API response has the actual data nested under 'data' key
    final data = json['data'] as Map<String, dynamic>? ?? json;
    
    // Handle user data safely
    final userData = data['user'];
    User user;
    print('Parsing user data: $userData');
    
    if (userData != null && userData is Map<String, dynamic>) {
      user = User.fromJson(userData);
      print('User active step: ${user.activeStep}');
    } else {
      // Create a default user if user data is missing
      user = User(
        id: data['id'] as String? ?? '',
        email: data['email'] as String?,
        phone: data['phone'] as String?,
        onboardingCompleted: data['onboarding_completed'] as bool? ?? false,
        activeStep: data['active_step'] as String? ?? 'user_info',
      );
    }
    
    return AuthResponse(
      otp: data['otp'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      user: user,
      token: data['token'] as String? ?? json['token'] as String? ?? '',
      refreshToken: data['refresh_token'] as String? ?? json['refresh_token'] as String? ?? '',
    );
  }
}
