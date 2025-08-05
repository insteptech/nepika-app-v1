import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/settings/usecases/get_user_settings.dart';
import '../../../domain/settings/usecases/update_setting.dart';
import '../../../domain/settings/usecases/get_user_profile.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetUserSettings getUserSettings;
  final UpdateSetting updateSetting;
  final GetUserProfile getUserProfile;

  SettingsBloc({
    required this.getUserSettings,
    required this.updateSetting,
    required this.getUserProfile,
  }) : super(SettingsInitial()) {
    on<GetUserSettingsRequested>(_onGetUserSettingsRequested);
    on<UpdateSettingRequested>(_onUpdateSettingRequested);
    on<GetUserProfileRequested>(_onGetUserProfileRequested);
  }

  Future<void> _onGetUserSettingsRequested(
    GetUserSettingsRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    final result = await getUserSettings(GetUserSettingsParams(token: event.token));
    result.fold(
      (failure) => emit(SettingsError(message: failure.message)),
      (settings) => emit(UserSettingsLoaded(settings: settings)),
    );
  }

  Future<void> _onUpdateSettingRequested(
    UpdateSettingRequested event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await updateSetting(UpdateSettingParams(
      token: event.token,
      settingId: event.settingId,
      isEnabled: event.isEnabled,
    ));
    result.fold(
      (failure) => emit(SettingsError(message: failure.message)),
      (_) => emit(SettingUpdated(
        settingId: event.settingId,
        isEnabled: event.isEnabled,
      )),
    );
  }

  Future<void> _onGetUserProfileRequested(
    GetUserProfileRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(UserProfileLoading());
    final result = await getUserProfile(GetUserProfileParams(token: event.token));
    result.fold(
      (failure) => emit(SettingsError(message: failure.message)),
      (profile) => emit(UserProfileLoaded(profile: profile)),
    );
  }
}
