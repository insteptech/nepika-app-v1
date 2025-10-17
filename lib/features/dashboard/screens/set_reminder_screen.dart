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

    final hour = int.parse(match.group(1)!);
    final period = match.group(3)!;
    
    // Convert to 24-hour format for easier validation
    int hour24 = hour;
    if (period == 'AM' && hour == 12) {
      hour24 = 0;
    } else if (period == 'PM' && hour != 12) {
      hour24 = hour + 12;
    }

    switch (_selectedType!) {
      case ReminderType.morning:
        // Morning routine: 5 AM to 12 PM (5-12 in 24-hour format)
        if (hour24 < 5 || hour24 > 12) {
          return 'Morning routine reminders should be between 5:00 AM and 12:00 PM';
        }
        break;
      case ReminderType.night:
        // Night routine: 6 PM to 11 PM (18-23 in 24-hour format)
        if (hour24 < 18 || hour24 > 23) {
          return 'Night routine reminders should be between 6:00 PM and 11:00 PM';
        }
        break;
    }
    
    return null; // No error
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
    if (_selectedType == null) return TimeOfDay.now();
    
    switch (_selectedType!) {
      case ReminderType.morning:
        // Default to 8:00 AM for morning routine
        return const TimeOfDay(hour: 8, minute: 0);
      case ReminderType.night:
        // Default to 10:00 PM for night routine
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
      // Validate the picked time against routine type
      if (_selectedType != null && !_isTimeValidForRoutineType(picked)) {
        _showTimeValidationError(picked);
        return;
      }

      final hour = picked.hour % 12 == 0 ? 12 : picked.hour % 12;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.hour >= 12 ? 'PM' : 'AM';
      setState(() {
        _reminderTimeController.text = '$hour:$minute $period';
      });
    }
  }

  bool _isTimeValidForRoutineType(TimeOfDay time) {
    if (_selectedType == null) return true;

    switch (_selectedType!) {
      case ReminderType.morning:
        // Morning routine: 5 AM to 12 PM (5-12 in 24-hour format)
        return time.hour >= 5 && time.hour <= 12;
      case ReminderType.night:
        // Night routine: 6 PM to 11 PM (18-23 in 24-hour format)
        return time.hour >= 18 && time.hour <= 23;
    }
  }

  void _showTimeValidationError(TimeOfDay selectedTime) {
    String routineTypeText = _selectedType == ReminderType.morning ? 'morning' : 'night';
    String timeRange = _selectedType == ReminderType.morning 
        ? '5:00 AM and 12:00 PM' 
        : '6:00 PM and 11:00 PM';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Invalid time for $routineTypeText routine. Please select a time between $timeRange.',
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _onDonePressed(BuildContext blocContext) {
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
      
      blocContext.read<ReminderBloc>().add(
        AddReminderEvent(
          reminderName: _reminderNameController.text.trim(),
          reminderTime: time24Hour,
          reminderDays: _mapReminderDays(_selectedDay!),
          reminderType: _mapReminderType(_selectedType!),
          reminderEnabled: _reminderEnabled,
        ),
      );
    } catch (e) {
      print('Error in _onDonePressed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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