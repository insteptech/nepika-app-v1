import 'package:flutter/material.dart';
import '../mixins/widget_behaviors.dart';

/// Loading Indicator with consistent styling
class LoadingIndicator extends StatelessWidget 
    with ThemeAwareBehavior, LoadingStateBehavior {
  final String? message;
  final double? size;
  final Color? color;
  final bool overlay;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size,
    this.color,
    this.overlay = false,
  });

  @override
  bool get isLoading => true;

  @override
  void setLoading(bool loading) {
    // Implementation handled by parent widget
  }

  @override
  Widget build(BuildContext context) {
    final indicator = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size ?? 40,
          height: size ?? 40,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? getPrimaryColor(context),
            ),
            strokeWidth: 3,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: getTextTheme(context).bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (overlay) {
      return Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(child: indicator),
      );
    }

    return Center(child: indicator);
  }
}

/// Error Display Widget
class ErrorDisplay extends StatelessWidget 
    with ThemeAwareBehavior, ErrorStateBehavior {
  @override
  final String? errorMessage;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool centered;

  const ErrorDisplay({
    super.key,
    required this.errorMessage,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.centered = true,
  });

  @override
  void setError(String? error) {
    // Implementation handled by parent widget
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon ?? Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          errorMessage ?? 'An error occurred',
          style: getTextTheme(context).bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
        if (onAction != null && actionLabel != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(actionLabel!),
          ),
        ],
      ],
    );

    return centered ? Center(child: content) : content;
  }
}

/// Empty State Widget
class EmptyState extends StatelessWidget with ThemeAwareBehavior {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? illustration;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.illustration,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null)
              illustration!
            else if (icon != null)
              Icon(
                icon!,
                size: 64,
                color: Colors.grey.shade400,
              ),
            const SizedBox(height: 24),
            Text(
              title,
              style: getTextTheme(context).headlineSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: getTextTheme(context).bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: getPrimaryColor(context),
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Divider with consistent styling
class CustomDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final Color? color;
  final double? indent;
  final double? endIndent;

  const CustomDivider({
    super.key,
    this.height,
    this.thickness,
    this.color,
    this.indent,
    this.endIndent,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height ?? 32,
      thickness: thickness ?? 1,
      color: color ?? Colors.grey.shade300,
      indent: indent,
      endIndent: endIndent,
    );
  }
}

/// Badge Widget
class CustomBadge extends StatelessWidget with ThemeAwareBehavior {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const CustomBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? getPrimaryColor(context),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: getTextTheme(context).bodySmall?.copyWith(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Avatar Widget with consistent styling
class CustomAvatar extends StatelessWidget with ThemeAwareBehavior {
  final String? imageUrl;
  final String? initials;
  final double radius;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const CustomAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.radius = 20,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? getPrimaryColor(context),
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null && initials != null
          ? Text(
              initials!,
              style: getTextTheme(context).titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );

    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}

/// Shimmer Loading Effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
  });

  @override
  ShimmerLoadingState createState() => ShimmerLoadingState();
}

class ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin, ThemeAwareBehavior {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isLoading && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor ?? Colors.grey.shade300,
                widget.highlightColor ?? Colors.grey.shade100,
                widget.baseColor ?? Colors.grey.shade300,
              ],
              stops: [
                (_animation.value - 1) / 2,
                _animation.value / 2,
                (_animation.value + 1) / 2,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
