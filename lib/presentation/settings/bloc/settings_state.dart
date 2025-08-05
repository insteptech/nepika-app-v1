import '../../../domain/settings/entities/settings.dart';

abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class UserSettingsLoaded extends SettingsState {
  final List<Settings> settings;

  UserSettingsLoaded({required this.settings});
}

class UserProfileLoading extends SettingsState {}

class UserProfileLoaded extends SettingsState {
  final UserProfile profile;

  UserProfileLoaded({required this.profile});
}

class SettingUpdated extends SettingsState {
  final String settingId;
  final bool isEnabled;

  SettingUpdated({required this.settingId, required this.isEnabled});
}

class UserProfileUpdated extends SettingsState {}

class AccountDeleted extends SettingsState {}

class SettingsError extends SettingsState {
  final String message;

  SettingsError({required this.message});
}
