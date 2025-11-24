import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/widgets/custom_button.dart';
import 'package:nepika/core/widgets/custom_text_field.dart';
import 'package:nepika/core/widgets/selection_button.dart';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/core/di/injection_container.dart';
import 'package:nepika/core/services/local_notification_service.dart';
import 'package:nepika/core/services/unified_fcm_service.dart';
import 'package:nepika/features/reminders/bloc/reminder_bloc.dart';
import 'package:nepika/features/reminders/bloc/reminder_event.dart';
import 'package:nepika/features/reminders/bloc/reminder_state.dart';
import 'package:nepika/features/settings/widgets/settings_option_tile.dart';
import 'package:nepika/features/routine/widgets/sticky_header_delegate.dart';

enum ReminderDays { daily, weekdays, weekends }
enum ReminderType { morning, night }

class ReminderSettings extends StatefulWidget {
  const ReminderSettings({super.key});

  @override
  State<ReminderSettings> createState() => _ReminderSettingsState();
}


class _ReminderSettingsState extends State<ReminderSettings> {
  ReminderDays? _selectedDay = ReminderDays.daily;
  ReminderType? _selectedType = ReminderType.morning;

  final _reminderNameController = TextEditingController();
  final _reminderTimeController = TextEditingController();

  bool _reminderEnabled = false;


bool get _isFormValid {
  return _reminderNameController.text.trim().isNotEmpty &&
      _timeError == null &&
      _selectedDay != null &&
      _selectedType != null;
}

  String? _timeError;

  @override
  void initState() {
    super.initState();
    // Set default time (e.g., current time in HH:MM AM/PM format)
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    _reminderTimeController.text = '$hour:$minute $period';
    
    // Add listener for time validation
    _reminderTimeController.addListener(_validateTime);
  }

  void _validateTime() {
    final timeText = _reminderTimeController.text.trim();
    final timeRegex = RegExp(r'^(1[0-2]|0?[1-9]):[0-5][0-9] (AM|PM)$');
    
    if (!timeRegex.hasMatch(timeText)) {
      setState(() {
        _timeError = 'Invalid time format (use HH:MM AM/PM)';
      });
      return;
    }

    // Validate time based on routine type
    final validationError = _validateTimeForRoutineType(timeText);
    setState(() {
      _timeError = validationError;
    });
  }

  String? _validateTimeForRoutineType(String timeText) {
    if (_selectedType == null) return null;

    final timeRegex = RegExp(r'^(\d{1,2}):(\d{2}) (AM|PM)$');
    final match = timeRegex.firstMatch(timeText);
    if (match == null) return 'Invalid time format';

    // Remove time range restrictions - users can set reminders for any time
    // Morning and Night are just labels, not time restrictions
    
    return null; // No time restrictions
  }

  Widget _buildReminderButton(
    String text,
    ReminderDays? day,
    ReminderType? type,
    IconData? icon,
    String? asset,
  ) {
    final bool isSelected = (day != null && _selectedDay == day) ||
        (type != null && _selectedType == type);

    return Expanded(
      child: SelectionButton(
        text: text,
        prefixIcon: icon,
        isSelected: isSelected,
        prefixIconAsset: asset,
        onPressed: () {
          setState(() {
            if (day != null) {
              _selectedDay = day;
            }
            if (type != null) {
              _selectedType = type;
              // Re-validate time when routine type changes
              if (_reminderTimeController.text.isNotEmpty) {
                _validateTime();
              }
            }
          });
        },
      ),
    );
  }

  String _convertTo24HourFormat(String time12Hour) {
    final timeRegex = RegExp(r'^(\d{1,2}):(\d{2}) (AM|PM)$');
    final match = timeRegex.firstMatch(time12Hour);
    
    if (match == null) {
      throw FormatException('Invalid time format: $time12Hour');
    }
    
    int hour = int.parse(match.group(1)!);
    final minute = match.group(2)!;
    final period = match.group(3)!;
    
    if (period == 'AM') {
      if (hour == 12) hour = 0;
    } else {
      if (hour != 12) hour += 12;
    }
    
    return '${hour.toString().padLeft(2, '0')}:$minute:00';
  }

  String _mapReminderDays(ReminderDays days) {
    switch (days) {
      case ReminderDays.daily:
        return 'Daily';
      case ReminderDays.weekdays:
        return 'Weekdays';
      case ReminderDays.weekends:
        return 'Weekly'; // Using Weekly as closest match to weekends
    }
  }

  String _mapReminderType(ReminderType type) {
    switch (type) {
      case ReminderType.morning:
        return 'Morning Routine';
      case ReminderType.night:
        return 'Night Routine';
    }
  }


  TimeOfDay _getInitialTimeForRoutineType() {
    // Use current time as default, or provide sensible defaults based on routine type
    if (_selectedType == null) return TimeOfDay.now();
    
    switch (_selectedType!) {
      case ReminderType.morning:
        // Suggest 8:00 AM for morning routine (but user can change to any time)
        return const TimeOfDay(hour: 8, minute: 0);
      case ReminderType.night:
        // Suggest 10:00 PM for night routine (but user can change to any time)
        return const TimeOfDay(hour: 22, minute: 0);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _getInitialTimeForRoutineType(),
      builder: (context, child) {
        return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).colorScheme.primary,
            secondary: Theme.of(context).colorScheme.onTertiary,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Theme.of(context).textTheme.bodyMedium!.color!,
            surface: Theme.of(context).scaffoldBackgroundColor,
            onSurfaceVariant: Theme.of(context).textTheme.bodyMedium!.secondary(context).color,
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor:  Theme.of(context).scaffoldBackgroundColor,
            headerBackgroundColor:  Theme.of(context).colorScheme.primary,
            headerForegroundColor: Colors.white,
          ),
        ),
        child: child!,
      );
      },
      
    );
    if (picked != null) {
      // Accept any time - no validation restrictions
      final hour = picked.hour % 12 == 0 ? 12 : picked.hour % 12;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.hour >= 12 ? 'PM' : 'AM';
      setState(() {
        _reminderTimeController.text = '$hour:$minute $period';
      });
    }
  }


  void _onDonePressed(BuildContext blocContext) async {
    // Validate inputs
    if (_reminderNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reminder name')),
      );
      return;
    }

    if (_timeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid time')),
      );
      return;
    }

    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select reminder days')),
      );
      return;
    }

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select routine type')),
      );
      return;
    }

    // Check for notification permissions (Android only)
    if (_reminderEnabled) {
      try {
        final notificationService = LocalNotificationService.instance;
        final hasExactAlarmPermission = await notificationService.requestExactAlarmPermission();
        
        if (!hasExactAlarmPermission) {
          if (!mounted) return;
          
          // Show permission dialog
          final bool? shouldContinue = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Notification Permission Required'),
                content: const Text(
                  'To schedule reminders, this app needs permission to set exact alarms. '
                  'Please enable "Alarms & reminders" permission in settings.\n\n'
                  'You can continue without notifications, but reminders won\'t work.'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Continue without notifications'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Try again'),
                  ),
                ],
              );
            },
          );
          
          if (shouldContinue == true) {
            // User wants to try again, call this method recursively
            if (mounted) {
              _onDonePressed(blocContext);
            }
            return;
          } else if (shouldContinue == false) {
            // User wants to continue without notifications
            setState(() {
              _reminderEnabled = false;
            });
          } else {
            // User dismissed dialog
            return;
          }
        }
      } catch (e) {
        print('Permission check error: $e');
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to check notification permissions. Saving reminder without notifications.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _reminderEnabled = false;
        });
      }
    }

    try {
      final time24Hour = _convertTo24HourFormat(_reminderTimeController.text);
      
      // Debug logging
      print('=== Reminder Save Debug ===');
      print('Reminder Name: ${_reminderNameController.text.trim()}');
      print('Reminder Time (12h): ${_reminderTimeController.text}');
      print('Reminder Time (24h): $time24Hour');
      print('Reminder Days: ${_mapReminderDays(_selectedDay!)}');
      print('Reminder Type: ${_mapReminderType(_selectedType!)}');
      print('Reminder Enabled: $_reminderEnabled');
      print('========================');
      
      if (mounted) {
        blocContext.read<ReminderBloc>().add(
          AddReminderEvent(
            reminderName: _reminderNameController.text.trim(),
            reminderTime: time24Hour,
            reminderDays: _mapReminderDays(_selectedDay!),
            reminderType: _mapReminderType(_selectedType!),
            reminderEnabled: _reminderEnabled,
          ),
        );
      }
    } catch (e) {
      print('Error in _onDonePressed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _testImmediateNotification() async {
    try {
      print('=== IMMEDIATE NOTIFICATION TEST ===');
      
      final localService = LocalNotificationService.instance;
      print('Testing immediate notification...');
      
      final success = await localService.showImmediateNotification(
        title: 'NEPIKA Immediate Test',
        body: 'This notification should appear instantly!',
      );
      
      print('Immediate notification result: $success');
      print('==================================');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? 'Immediate notification sent! Should appear now.'
              : 'Failed to send immediate notification. Check console for details.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error in immediate notification test: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _runDiagnostics() async {
    try {
      print('=== COMPREHENSIVE NOTIFICATION DIAGNOSTICS ===');
      
      final localService = LocalNotificationService.instance;
      final diagnostics = await localService.runDiagnostics();
      
      print('Diagnostic Results:');
      diagnostics.forEach((key, value) {
        print('  $key: $value');
      });
      print('==============================================');
      
      if (!mounted) return;
      
      // Show results in a dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notification Diagnostics'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: diagnostics.entries.map((entry) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${entry.key}: ${entry.value}', 
                    style: const TextStyle(fontSize: 12)),
                )
              ).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error in diagnostics: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Diagnostics error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _testNotifications() async {
    try {
      print('=== NOTIFICATION DIAGNOSTIC TEST ===');
      
      // 1. Test Local Notification Service
      final localService = LocalNotificationService.instance;
      print('Local Notification Service Status: ${localService.getStatus()}');
      
      // 2. Test exact alarm permission
      final hasExactAlarmPermission = await localService.requestExactAlarmPermission();
      print('Exact Alarm Permission: $hasExactAlarmPermission');
      
      // 3. Test notifications enabled
      final notificationsEnabled = await localService.areNotificationsEnabled();
      print('Notifications Enabled: $notificationsEnabled');
      
      // 4. Test FCM Service
      final fcmService = UnifiedFcmService.instance;
      print('FCM Service Status: ${fcmService.getStatus()}');
      
      // 5. Schedule a test notification for 10 seconds from now using immediate scheduling
      print('Scheduling immediate test notification for 10 seconds from now...');
      
      final success = await localService.testNotification(
        title: 'NEPIKA Test Notification',
        body: 'This is a test notification scheduled 10 seconds ago',
        delaySeconds: 10,
      );
      
      // 6. Also test a 30-second delayed reminder using the reminder scheduling system
      print('Also testing 30-second scheduled reminder...');
      final now = DateTime.now().add(const Duration(seconds: 30));
      final timeString30s = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      
      final success30s = await localService.scheduleReminder(
        reminderId: 'test_30s_${DateTime.now().millisecondsSinceEpoch}',
        reminderName: 'Test 30s Scheduled',
        time24Hour: timeString30s,
        reminderDays: 'Daily',
        reminderType: 'Test',
        isEnabled: true,
      );
      
      print('30-second scheduled reminder result: $success30s');
      
      print('Test notification scheduled: $success');
      print('====================================');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? 'Test notification scheduled for 10 seconds from now. Check console for diagnostic info.'
              : 'Failed to schedule test notification. Check console for details.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      
    } catch (e) {
      print('Error in notification test: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ReminderBloc>(),
      child: Builder(
        builder: (blocContext) {
          return BlocListener<ReminderBloc, ReminderState>(
            listener: (context, state) {
              print('=== BLoC State Change ===');
              print('State: ${state.runtimeType}');
              
              if (state is ReminderAdded) {
                print('Reminder added successfully: ${state.reminder.id}');
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder saved successfully!')),
                );
                Navigator.of(context).pushNamed(AppRoutes.dashboardHome);
              } else if (state is ReminderError) {
                print('Reminder error: ${state.message}');
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save reminder: ${state.message}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              } else if (state is ReminderLoading) {
                print('Reminder loading...');
              }
              print('=====================');
            },
            child: BlocBuilder<ReminderBloc, ReminderState>(
              builder: (context, state) {
                final isLoading = state is ReminderLoading;
                final theme = Theme.of(context);
                
                return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: SafeArea(
                child: GestureDetector(
                  onTap: () {
                    // Unfocus any focused input field when tapping outside
                    FocusScope.of(context).unfocus();
                  },
                  child: CustomScrollView(
                  slivers: [
                    // Static top content (back button, spacing)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20,right:14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const CustomBackButton(),
                                Opacity(
                                  opacity: (!_isFormValid || isLoading) ? 0.5 : 1.0,
                                  child: TextButton(
                                    onPressed: (!_isFormValid || isLoading) ? null : () => _onDonePressed(blocContext),
                                    child: Text(
                                      isLoading ? 'Saving...' : 'Done',
                                      style: TextStyle(
                                        fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),

                    // Sticky header
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: StickyHeaderDelegate(
                        minHeight: 40,
                        maxHeight: 40,
                        isFirstHeader: true,
                        title: "Set Your Reminders",
                        child: Container(
                          color: theme.scaffoldBackgroundColor,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Set Your Reminders",
                            style: theme.textTheme.displaySmall,
                          ),
                        ),
                      ),
                    ),
                    
                    // Main content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Get gentle reminders to stay consistent with your skincare routine.',
                              style: theme.textTheme.headlineMedium!.secondary(
                                context,
                              ),
                            ),
                            const SizedBox(height: 40),
                            Text(
                              'Reminder Name',
                              style: theme.textTheme.headlineMedium,
                            ),
                            UnderlinedTextField(
                              controller: _reminderNameController,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Reminder Time',
                              style: theme.textTheme.headlineMedium,
                            ),
                            GestureDetector(
                              onTap: () => _selectTime(context),
                              child: AbsorbPointer(
                                child: UnderlinedTextField(
                                  controller: _reminderTimeController,
                                  keyboardType: TextInputType.datetime,
                                  errorText: _timeError,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9: AMPMampm]+'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Reminder Days',
                              style: theme.textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildReminderButton(
                                  'Daily',
                                  ReminderDays.daily,
                                  null,
                                  null,
                                  null,
                                ),
                                const SizedBox(width: 12),
                                _buildReminderButton(
                                  'Weekdays',
                                  ReminderDays.weekdays,
                                  null,
                                  null,
                                  null,
                                ),
                                const SizedBox(width: 12),
                                _buildReminderButton(
                                  'Weekends',
                                  ReminderDays.weekends,
                                  null,
                                  null,
                                  null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Text(
                              'Routine Type',
                              style: theme.textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildReminderButton(
                                  'Morning Routine',
                                  null,
                                  ReminderType.morning,
                                  null,
                                  null,
                                ),
                                const SizedBox(width: 12),
                                _buildReminderButton(
                                  'Night Routine',
                                  null,
                                  ReminderType.night,
                                  null,
                                  null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SettingsOptionTile(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 8,
                              ),
                              text: 'Enable Reminders',
                              showToggle: true,
                              showDivider: false,
                              toggleValue: _reminderEnabled,
                              onToggleChanged: (value) {
                                setState(() {
                                  _reminderEnabled = value;
                                });
                              },
                            ),
                             const SizedBox(height: 10),
                             
                             // Debug: Test Notification Buttons
                            //  Row(
                            //    children: [
                            //      Expanded(
                            //        child: CustomButton(
                            //          isDisabled: false,
                            //          text: 'Immediate Test',
                            //          onPressed: () => _testImmediateNotification(),
                            //        ),
                            //      ),
                            //      const SizedBox(width: 4),
                            //      Expanded(
                            //        child: CustomButton(
                            //          isDisabled: false,
                            //          text: 'Scheduled Test',
                            //          onPressed: () => _testNotifications(),
                            //        ),
                            //      ),
                            //      const SizedBox(width: 4),
                            //      Expanded(
                            //        child: CustomButton(
                            //          isDisabled: false,
                            //          text: 'Diagnostics',
                            //          onPressed: () => _runDiagnostics(),
                            //        ),
                            //      ),
                            //    ],
                            //  ),
                            //  const SizedBox(height: 10),
                             
                             CustomButton(
                               isDisabled: !_isFormValid || isLoading,
                               text: isLoading ? 'Saving...' : 'Done',
                               onPressed: () => _onDonePressed(blocContext),
                             ),
                             const SizedBox(height: 10),

                           ],
                         ),
                      ),
                    ),
                  ],
                ),
                ),
              ),
            );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _reminderNameController.dispose();
    _reminderTimeController.dispose();
    super.dispose();
  }
}