import 'package:flutter/material.dart';
import '../mixins/widget_behaviors.dart';

/// Responsive Card Layout following SOLID principles
class ResponsiveCard extends StatelessWidget with ThemeAwareBehavior {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? elevation;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final double? maxWidth;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.backgroundColor,
    this.borderRadius,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      constraints: maxWidth != null 
          ? BoxConstraints(maxWidth: maxWidth!)
          : null,
      child: Card(
        elevation: elevation ?? 4,
        color: backgroundColor ?? getBackgroundColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}

/// Section Header with consistent styling
class SectionHeader extends StatelessWidget with ThemeAwareBehavior {
  final String title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsets? padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: getTextTheme(context).headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: getTextTheme(context).bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Progress Indicator Layout
class ProgressLayout extends StatelessWidget 
    with ThemeAwareBehavior, ProgressBehavior {
  @override
  final int currentStep;
  @override
  final int totalSteps;
  final String title;
  final String? subtitle;
  final Widget child;
  final bool showStepNumbers;

  const ProgressLayout({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.child,
    this.subtitle,
    this.showStepNumbers = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showStepNumbers)
                Text(
                  'Step $currentStep of $totalSteps',
                  style: getTextTheme(context).bodySmall?.copyWith(
                    color: getPrimaryColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  getPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: getTextTheme(context).headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: getTextTheme(context).bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Content
        Expanded(child: child),
      ],
    );
  }
}

/// Form Layout with consistent spacing and validation
class FormLayout extends StatelessWidget with ThemeAwareBehavior {
  final List<Widget> children;
  final EdgeInsets? padding;
  final double? spacing;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  const FormLayout({
    super.key,
    required this.children,
    this.padding,
    this.spacing,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisAlignment: mainAxisAlignment,
        children: _buildChildrenWithSpacing(),
      ),
    );
  }

  List<Widget> _buildChildrenWithSpacing() {
    if (children.isEmpty) return [];
    
    final List<Widget> spacedChildren = [];
    final spacingValue = spacing ?? 16.0;
    
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(height: spacingValue));
      }
    }
    
    return spacedChildren;
  }
}

/// Two Column Layout for larger screens
class ResponsiveTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double breakpoint;
  final double? spacing;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveTwoColumn({
    super.key,
    required this.left,
    required this.right,
    this.breakpoint = 768,
    this.spacing,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          // Two column layout for larger screens
          return Row(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              Expanded(child: left),
              SizedBox(width: spacing ?? 24),
              Expanded(child: right),
            ],
          );
        } else {
          // Single column layout for smaller screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              SizedBox(height: spacing ?? 16),
              right,
            ],
          );
        }
      },
    );
  }
}

/// Safe Area Layout with consistent padding
class SafeLayout extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final EdgeInsets? additionalPadding;

  const SafeLayout({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.additionalPadding,
  });

  @override
  Widget build(BuildContext context) {
    Widget result = SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );

    if (additionalPadding != null) {
      result = Padding(
        padding: additionalPadding!,
        child: result,
      );
    }

    return result;
  }
}
