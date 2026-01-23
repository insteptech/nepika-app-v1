import 'package:flutter/material.dart';
import 'package:nepika/core/utils/shared_prefs_helper.dart';

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
  bool _allChannelEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final helper = SharedPrefsHelper();
    
    // Load saved values
    final reminder = await helper.getBool('Reminder notification');
    final community = await helper.getBool('Community notification');
    final allChannel = await helper.getBool('Turn on all channel notification');

    if (mounted) {
      setState(() {
        _reminderEnabled = reminder;
        _communityEnabled = community;
        _allChannelEnabled = allChannel;
        _isLoading = false;
      });
    }
  }

  List<SettingsOptionData> _buildOptions() {
    if (_isLoading) return [];

    return [
      SettingsOptionData.toggle(
        'Reminder notification',
        toggleValue: _reminderEnabled,
        onToggle: (value) async {
          setState(() {
            _reminderEnabled = value;
          });
          await SharedPrefsHelper().setBool('Reminder notification', value);
        },
      ),
      SettingsOptionData.toggle(
        'Community notification',
        toggleValue: _communityEnabled,
        onToggle: (value) async {
          setState(() {
            _communityEnabled = value;
          });
          await SharedPrefsHelper().setBool('Community notification', value);
        },
      ),
      SettingsOptionData.toggle(
        'All Channel Notification',
        toggleValue: _allChannelEnabled,
        onToggle: (value) async {
          setState(() {
            _allChannelEnabled = value;
          });
          await SharedPrefsHelper().setBool('Turn on all channel notification', value);
        },
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