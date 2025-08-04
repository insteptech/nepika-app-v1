import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final ButtonType type;
  final ButtonSize size;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final bool? iconOnLeft;
  
  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.type = ButtonType.primary,
    this.size = ButtonSize.large,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.iconOnLeft = true,  
  });

  @override
  Widget build(BuildContext context) {

    return  SizedBox(
        width: width ?? (size == ButtonSize.large ? double.infinity : null),
        height: _getHeight(),
        child: _buildButton(context),
      );
  }


  
  Widget _buildButton(BuildContext context) {
    final isEnabled = !isDisabled && !isLoading && onPressed != null;
    
    switch (type) {
      case ButtonType.primary:
        return ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
            foregroundColor: textColor ?? Theme.of(context).colorScheme.surface,
            disabledBackgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            disabledForegroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            elevation: 0,
            padding: _getPadding(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          child: _buildButtonContent(context),
        );
        
      case ButtonType.secondary:
        return OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
           foregroundColor: textColor ?? Theme.of(context).colorScheme.surface,
            disabledBackgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            side: BorderSide(
              color: isEnabled 
                  ? (backgroundColor ?? Theme.of(context).colorScheme.primary)
                  : Theme.of(context).colorScheme.primary,
            ),
            padding: _getPadding(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _buildButtonContent(context),
        );
        
      case ButtonType.text:
        return TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
 disabledBackgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8), 
            padding: _getPadding(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _buildButtonContent(context),
        );
    }
  }
  
Widget _buildButtonContent(BuildContext context) {
if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == ButtonType.primary 
                ?  Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    
    if (icon != null) {
      return iconOnLeft == true ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(
            text,
            style: _getTextStyle(),
          ),
        ],
      ) : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: _getTextStyle(),
          ),
          const SizedBox(width: 8),
          icon!,
        ],
      );
    }
    
    return Text(
      text,
      style: _getTextStyle(),
    );
  }
  
  TextStyle _getTextStyle() {
    switch (size) {
      case ButtonSize.small:
        return const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white
        );
      case ButtonSize.medium:
        return const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white
        );
      case ButtonSize.large:
        return const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white
        );
    }
  }
  
  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
  }
  
  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 36;
      case ButtonSize.medium:
        return 44;
      case ButtonSize.large:
        return 56;
    }
  }
}

enum ButtonType { primary, secondary, text }
enum ButtonSize { small, medium, large }
