import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/constants/routes.dart';
import 'package:nepika/core/constants/theme.dart';
import 'package:nepika/core/widgets/custom_button.dart';
import 'package:nepika/core/widgets/custom_text_field.dart';
import 'package:nepika/core/widgets/selection_button.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/data/dashboard/repositories/dashboard_repository.dart';
import 'package:nepika/presentation/bloc/dashboard/dashboard_bloc.dart';
import 'package:nepika/presentation/bloc/dashboard/dashboard_event.dart';
import 'package:nepika/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:nepika/presentation/settings/widgets/settings_option_tile.dart';

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

  bool _reminderEnabled = true;


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
    } else {
      setState(() {
        _timeError = null;
      });
    }
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
            }
          });
        },
      ),
    );
  }

  void _onDonePressed() {
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

    final reminderData = {
      'reminder_name': _reminderNameController.text,
      'reminder_time': _reminderTimeController.text,
      'reminder_days': _selectedDay!.toString().split('.').last,
      'reminder_type': _selectedType!.toString().split('.').last,
      'reminder_enabled': _reminderEnabled,
    };

    // context.read<DashboardBloc>().add(
    //       SaveReminderEvent(reminderData: reminderData, token: ''),
    //     );

    print('Reminder Data: $reminderData');

    // Show success message

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder saved successfully!')),
    );

    Navigator.of(context).pushNamed(
      AppRoutes.dashboardHome,
      // (route) => false,
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
      final hour = picked.hour % 12 == 0 ? 12 : picked.hour % 12;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.hour >= 12 ? 'PM' : 'AM';
      setState(() {
        _reminderTimeController.text = '$hour:$minute $period';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final token = '';

    return BlocProvider(
      create: (context) =>
          DashboardBloc(DashboardRepositoryImpl(ApiBase()))
            ..add(FetchTodaysRoutine(token, 'add')),
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            Text(
                              "Set Your Reminders",
                              style: theme.textTheme.displaySmall,
                            ),
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      isDisabled: !_isFormValid,
                      text: 'Done', 
                      onPressed: _onDonePressed
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
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