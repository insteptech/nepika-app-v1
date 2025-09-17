import 'package:flutter/material.dart';
import '../../../core/widgets/back_button.dart';

class TodayRoutineHeader extends StatelessWidget {
  final bool isCollapsed;
  
  const TodayRoutineHeader({
    this.isCollapsed = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.2),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: isCollapsed
            ? Row(
                key: const ValueKey('collapsed'),
                children: [
                  // Back button icon only (no text)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Today's Routine text
                  Text(
                    "Today's Routine",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              )
            : Column(
                key: const ValueKey('expanded'),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const CustomBackButton(),
                  const SizedBox(height: 12),
                  Text(
                    "Today's Routine",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Stay consistent. Mark each step as you complete it.',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .color!
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
        ),
      ),
    );
  }
}