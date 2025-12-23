import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/widgets/custom_button.dart';
import 'package:nepika/core/widgets/custom_text_field.dart';
import 'package:nepika/core/widgets/selection_button.dart';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/core/di/injection_container.dart';
import 'package:nepika/core/services/local_notification_service.dart';
import 'package:nepika/features/reminders/bloc/reminder_bloc.dart';
import 'package:nepika/features/reminders/bloc/reminder_event.dart';
import 'package:nepika/features/reminders/bloc/reminder_state.dart';
import 'package:nepika/features/settings/widgets/settings_option_tile.dart';
import 'package:nepika/features/routine/widgets/sticky_header_delegate.dart';
import 'package:permission_handler/permission_handler.dart';

enum ReminderDays { daily, weekdays, weekends }
enum ReminderType { morning, night }

class ReminderSettings extends StatefulWidget {
  const ReminderSettings({super.key});

  @override
  State<ReminderSettings> createState() => _ReminderSettingsState();
}


class _ReminderSettingsState extends State<ReminderSettings> with WidgetsBindingObserver {
  ReminderDays? _selectedDay = ReminderDays.daily;
  ReminderType? _selectedType = ReminderType.morning;

  final _reminderNameController = TextEditingController();
  final _reminderTimeController = TextEditingController();

  bool _reminderEnabled = false;
  bool _isCheckingPermission = true; // Track if we're still checking permission
  bool _userHasToggledManually = false; // Track if user has manually changed the toggle
  Timer? _permissionCheckTimer; // Timer for periodic permission checks


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

    // Add app lifecycle observer to detect when user returns from settings
    WidgetsBinding.instance.addObserver(this);

    // Check notification permission status immediately before first build
    _checkNotificationPermissionSync();

    // Start periodic permission check (every 1 second) - only runs while this screen is active
    _permissionCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkNotificationPermission();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Permission checking handled in initState and lifecycle changes
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Re-check permission when app resumes (user might have changed it in settings)
    if (state == AppLifecycleState.resumed) {
      print('=== APP RESUMED - Rechecking permission ===');
      _checkNotificationPermissionSync();
    }
  }

  /// Synchronous wrapper to immediately check permission without waiting
  void _checkNotificationPermissionSync() {
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    // If user has manually toggled, don't override their choice
    if (_userHasToggledManually) {
      if (_isCheckingPermission && mounted) {
        setState(() {
          _isCheckingPermission = false;
        });
      }
      return;
    }

    try {
      print('=== PERMISSION CHECK START ===');
      print('Platform: ${Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Unknown'}');

      final notificationService = LocalNotificationService.instance;

      // Check 1: Native plugin (flutter_local_notifications)
      final nativeEnabled = await notificationService.areNotificationsEnabled();
      print('Check 1 - Native plugin areNotificationsEnabled: $nativeEnabled');

      // Check 2: permission_handler
      final permissionStatus = await Permission.notification.status;
      print('Check 2 - Permission handler status: $permissionStatus');
      print('  - isGranted: ${permissionStatus.isGranted}');
      print('  - isDenied: ${permissionStatus.isDenied}');
      print('  - isPermanentlyDenied: ${permissionStatus.isPermanentlyDenied}');
      print('  - isLimited: ${permissionStatus.isLimited}');
      print('  - isRestricted: ${permissionStatus.isRestricted}');

      // Determine final state with platform-specific logic
      bool isGranted = false;

      if (Platform.isAndroid) {
        // On Android, native plugin is most reliable
        isGranted = nativeEnabled;
        print('Android: Using native plugin result: $isGranted');
      } else if (Platform.isIOS) {
        // On iOS, there's a known issue where permission_handler doesn't reflect
        // permissions granted outside the app or on first install
        // If native plugin says enabled, trust it over permission_handler
        if (nativeEnabled) {
          isGranted = true;
          print('iOS: Native plugin says enabled, trusting it: $isGranted');
          if (!permissionStatus.isGranted) {
            print('iOS Note: permission_handler disagrees but native is more accurate');
          }
        } else {
          // If native says disabled, double-check with permission_handler
          isGranted = permissionStatus.isGranted;
          print('iOS: Native says disabled, checking permission_handler: $isGranted');
        }
      } else {
        // Fallback for other platforms - trust native plugin first
        isGranted = nativeEnabled;
        print('Other platform: Using native plugin result: $isGranted');
      }

      print('Final toggle state: $isGranted');
      print('========================');

      if (mounted) {
        setState(() {
          _reminderEnabled = isGranted;
          _isCheckingPermission = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error checking notification permission: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _reminderEnabled = false;
          _isCheckingPermission = false;
        });
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      print('=== PERMISSION REQUEST ===');

      // First check current status
      final currentStatus = await Permission.notification.status;
      print('Current permission status: $currentStatus');

      PermissionStatus newStatus;

      // If permanently denied, go directly to settings
      if (currentStatus.isPermanentlyDenied) {
        print('Permission permanently denied, need to open settings');

        if (!mounted) return;

        final shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                'Notification permission is required for reminders.\n\n'
                'You previously denied this permission. Please enable it in app settings to receive reminders.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Open Settings'),
                ),
              ],
            );
          },
        );

        if (shouldOpenSettings == true) {
          await openAppSettings();
          // Don't check immediately, wait for app resume lifecycle
        }
        return;
      }

      // Request permission
      print('Requesting notification permission...');
      newStatus = await Permission.notification.request();
      print('Permission request result: $newStatus');

      if (!mounted) return;

      // Handle the result
      if (newStatus.isGranted) {
        // Permission granted - verify with native plugin and enable toggle
        final nativeEnabled = await LocalNotificationService.instance.areNotificationsEnabled();

        if (mounted) {
          setState(() {
            _reminderEnabled = nativeEnabled;
          });

          if (nativeEnabled) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification permission granted!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            print('Permission granted, toggle enabled');
          } else {
            // Edge case: permission_handler says granted but native says not enabled
            print('Permission mismatch - granted but not enabled natively');
          }
        }
      } else if (newStatus.isDenied || newStatus.isPermanentlyDenied) {
        // Permission denied - show dialog
        print('Permission denied, showing settings dialog');

        final shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                'Reminders need notification permission to work.\n\n'
                'Please enable notifications in app settings to receive reminders for your skincare routine.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Open Settings'),
                ),
              ],
            );
          },
        );

        if (shouldOpenSettings == true) {
          await openAppSettings();
          // Permission will be rechecked when app resumes via lifecycle callback
        } else {
          // Keep toggle disabled
          setState(() {
            _reminderEnabled = false;
          });
        }
      }

      print('==========================');
    } catch (e) {
      print('Error requesting notification permission: $e');

      if (mounted) {
        setState(() {
          _reminderEnabled = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        return 'Weekends';
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

    // Permission is now handled by the toggle - no need to check here again

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

      // Check notification service status only if reminder is enabled
      if (_reminderEnabled) {
        final notifService = LocalNotificationService.instance;
        final isInitialized = notifService.getStatus()['isInitialized'] ?? false;
        final canSchedule = await notifService.canScheduleNotifications();
        print('Notification Service Initialized: $isInitialized');
        print('Can Schedule Notifications: $canSchedule');

        if (!canSchedule) {
          print('WARNING: Cannot schedule notifications but reminder is enabled!');
          if (mounted) {
            ScaffoldMessenger.of(blocContext).showSnackBar(
              const SnackBar(
                content: Text('Notification permission is required to enable reminders'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      } else {
        print('Reminder is disabled, skipping notification permission check');
      }

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
        ScaffoldMessenger.of(blocContext).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext parentContext) {
    return BlocProvider(
      create: (_) => sl<ReminderBloc>(),
      child: Builder(
        builder: (blocContext) {
          return BlocListener<ReminderBloc, ReminderState>(
            listener: (_, state) {
              print('=== BLoC State Change ===');
              print('State: ${state.runtimeType}');

              if (state is ReminderAdded) {
                print('Reminder added successfully: ${state.reminder.id}');
                print('Attempting to pop screen...');

                // Show snackbar and navigate back
                ScaffoldMessenger.of(parentContext).clearSnackBars();
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('Reminder saved successfully!')),
                );
                Navigator.of(parentContext).pop();
                print('Pop called');
              } else if (state is ReminderError) {
                print('Reminder error: ${state.message}');
                ScaffoldMessenger.of(parentContext).clearSnackBars();
                ScaffoldMessenger.of(parentContext).showSnackBar(
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
                            _isCheckingPermission
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      Text('Enable Reminders'),
                                      Spacer(),
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ],
                                  ),
                                )
                              : SettingsOptionTile(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 8,
                                  ),
                                  text: 'Enable Reminders',
                                  showToggle: true,
                                  showDivider: false,
                                  toggleValue: _reminderEnabled,
                                  onToggleChanged: (value) async {
                                    // Mark that user has manually changed the toggle
                                    _userHasToggledManually = true;

                                    if (value) {
                                      // User wants to enable reminders - check permission first
                                      await _requestNotificationPermission();
                                    } else {
                                      // User wants to disable reminders - allow it
                                      setState(() {
                                        _reminderEnabled = false;
                                      });
                                    }
                                  },
                                ),
                             const SizedBox(height: 20),

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
    // Cancel the periodic permission check timer
    _permissionCheckTimer?.cancel();

    // Remove app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    _reminderNameController.dispose();
    _reminderTimeController.dispose();
    super.dispose();
  }
}