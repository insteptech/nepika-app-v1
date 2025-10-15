import 'package:equatable/equatable.dart';

class FcmTokenEntity extends Equatable {
  final String fcmToken;
  final String? fcmRefreshToken;
  final DateTime? lastUpdated;
  final bool isActive;

  const FcmTokenEntity({
    required this.fcmToken,
    this.fcmRefreshToken,
    this.lastUpdated,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        fcmToken,
        fcmRefreshToken,
        lastUpdated,
        isActive,
      ];

  FcmTokenEntity copyWith({
    String? fcmToken,
    String? fcmRefreshToken,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return FcmTokenEntity(
      fcmToken: fcmToken ?? this.fcmToken,
      fcmRefreshToken: fcmRefreshToken ?? this.fcmRefreshToken,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'FcmTokenEntity(fcmToken: ${fcmToken.substring(0, 20)}..., isActive: $isActive)';
  }
}