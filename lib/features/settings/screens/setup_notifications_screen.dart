import 'package:flutter/material.dart';
import 'package:nepika/core/utils/shared_prefs_helper.dart';
import 'package:nepika/core/services/local_notification_service.dart';
import 'package:nepika/core/di/injection_container.dart';
import 'package:nepika/features/reminders/bloc/reminder_bloc.dart';
import 'package:nepika/features/reminders/bloc/reminder_event.dart';
import 'dart:convert';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nepika/domain/auth/usecases/get_notification_settings.dart';
import 'package:nepika/domain/auth/usecases/update_notification_settings.dart';
import 'package:nepika/domain/auth/entities/notification_settings.dart';

import '../components/settings_options_list.dart';
import '../models/settings_option_data.dart';
import '../widgets/settings_header.dart';

class SetupNotificationsScreen extends StatefulWidget {
  const SetupNotificationsScreen({super.key});

  @override
  State<SetupNotificationsScreen> createState() => 
      _SetupNotificationsScreenState();
}

class _SetupNotificationsScreenState extends State<SetupNotificationsScreen> {
  // Toggle states
  bool _reminderEnabled = false;
  bool _communityEnabled = false;
  bool _marketingEnabled = true;
  bool _isLoading = true;
  bool _isProfessional = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final helper = SharedPrefsHelper();
    
    // 0. Check User Role
    try {
      _isProfessional = SharedPrefsHelper().isSkincareProfessionalSync();
    } catch (_) {}

    // 1. Optimistic load from local prefs
    final reminder = await helper.getBool('Reminder notification');
    final community = await helper.getBool('Community notification');

    if (mounted) {
      setState(() {
        _reminderEnabled = reminder;
        _communityEnabled = community;
        // Keep loading true until API responds
      });
    }

    // 2. Fetch from API
    try {
      final result = await sl<GetNotificationSettings>().call();
      result.fold(
        (failure) {
          if (mounted) setState(() => _isLoading = false);
        },
        (settings) {
          if (mounted) {
            setState(() {
              _reminderEnabled = settings.remindersEnabled;
              _communityEnabled = settings.communityEnabled;
              _marketingEnabled = settings.marketingEnabled;
              _isLoading = false;
            });
            // Sync local prefs
            helper.setBool('Reminder notification', settings.remindersEnabled);
            helper.setBool('Community notification', settings.communityEnabled);
          }
        },
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSettings({bool? reminder, bool? community}) async {
    final oldReminder = _reminderEnabled;
    final oldCommunity = _communityEnabled;

    // 1. Optimistic UI Update
    setState(() {
      if (reminder != null) _reminderEnabled = reminder;
      if (community != null) _communityEnabled = community;
    });

    // 2. Handle Local Side Effects
    if (reminder != null) {
      await SharedPrefsHelper().setBool('Reminder notification', reminder);
      if (reminder) {
        sl<ReminderBloc>().add(GetAllRemindersEvent(forceRefresh: true));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminders scheduled')),
          );
        }
      } else {
        await LocalNotificationService.instance.cancelAllReminders();
      }
    }
    if (community != null) {
      await SharedPrefsHelper().setBool('Community notification', community);
    }

    // 3. Call API
    final settings = NotificationSettings(
      remindersEnabled: _reminderEnabled,
      communityEnabled: _communityEnabled,
      marketingEnabled: _marketingEnabled,
    );

    final result = await sl<UpdateNotificationSettings>().call(settings);
    result.fold(
      (failure) {
        // Revert on failure
        if (mounted) {
          setState(() {
            _reminderEnabled = oldReminder;
            _communityEnabled = oldCommunity;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to sync settings')),
          );
        }
      },
      (success) {
        // Success - already updated locally
      },
    );
  }

  List<SettingsOptionData> _buildOptions() {
    if (_isLoading) return [];

    return [
      if (!_isProfessional)
        SettingsOptionData.toggle(
          'Reminder notification',
          toggleValue: _reminderEnabled,
          onToggle: (value) => _updateSettings(reminder: value),
        ),
      SettingsOptionData.toggle(
        'Community notification',
        toggleValue: _communityEnabled,
        onToggle: (value) => _updateSettings(community: value),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = _buildOptions();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  const SettingsHeader(
                    title: 'Notifications & Settings',
                    showBackButton: true,
                  ),
                  SliverToBoxAdapter(
                    child: SettingsOptionsList(options: options),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
      ),
    );
  }
}