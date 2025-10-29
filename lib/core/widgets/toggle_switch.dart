import 'package:flutter/material.dart';
import '../config/constants/theme.dart'; // adjust import path as per your structure

class ToggleSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<ToggleSwitch> createState() => _ToggleSwitchState();
}

class _ToggleSwitchState extends State<ToggleSwitch> {
  late bool isOn;

  @override
  void initState() {
    super.initState();
    isOn = widget.value;
  }


  @override
  void didUpdateWidget(covariant ToggleSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != isOn) {
      isOn = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: 58,
      height: 35,
      child: Switch(
        value: isOn,
        onChanged: (value) {
          setState(() {
            isOn = value;
          });
          widget.onChanged(value);
        },
        activeColor: AppTheme.whiteBlack,
        activeTrackColor: AppTheme.primaryColor,
        inactiveThumbColor: AppTheme.whiteBlack,
        inactiveTrackColor: (theme.brightness == Brightness.dark 
            ? AppTheme.textSecondaryDark 
            : AppTheme.textSecondaryLight).withValues(alpha: 0.3),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
