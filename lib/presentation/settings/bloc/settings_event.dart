import '../../../domain/settings/entities/settings.dart';

abstract class SettingsEvent {}

class GetUserSettingsRequested extends SettingsEvent {
  final String token;

  GetUserSettingsRequested({required this.token});
}

class UpdateSettingRequested extends SettingsEvent {
  final String token;
  final String settingId;
  final bool isEnabled;

  UpdateSettingRequested({
    required this.token,
    required this.settingId,
    required this.isEnabled,
  });
}

class GetUserProfileRequested extends SettingsEvent {
  final String token;

  GetUserProfileRequested({required this.token});
}

class UpdateUserProfileRequested extends SettingsEvent {
  final String token;
  final UserProfile profile;

  UpdateUserProfileRequested({
    required this.token,
    required this.profile,
  });
}

class DeleteAccountRequested extends SettingsEvent {
  final String token;

  DeleteAccountRequested({required this.token});
}
