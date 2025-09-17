import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/utils/debug_logger.dart';

class GreetingSection extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isCollapsed;
  
  const GreetingSection({
    required this.user, 
    this.isCollapsed = false,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    final String userName = user['name']?.toString().trim() ?? '';
    final String greeting = user['greeting']?.toString().trim() ?? '';

    final String? avatarUrl = user['avatarUrl'];
    final ImageProvider avatarImage =
        (avatarUrl != null && avatarUrl.trim().isNotEmpty)
        ? NetworkImage(avatarUrl)
        : const AssetImage('assets/icons/horizontal_lines_with_dots.png');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        crossAxisAlignment: isCollapsed ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
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
            child: Column(
                  key: const ValueKey('expanded'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hey, ${userName.isNotEmpty ? userName.split(' ')[0] : 'User'}',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    !isCollapsed ? AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: isCollapsed ? 0.0 : 1.0,
                      child: Text(
                        greeting.isNotEmpty ? greeting : 'welcome back!',
                        style: Theme.of(context).textTheme.bodyLarge!.secondary(context),
                      ),
                    ) : SizedBox(height: 0)
                  ],
                ),
          ),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: IconButton(
              onPressed: () => {},
              padding: EdgeInsets.all(0),
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: 34,
                height: 34,
                margin: EdgeInsets.all(0),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isCollapsed 
                    ? null 
                    : Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.0,
                      ),
                ),
                child: Image(
                  image: avatarImage,
                  height: 18,
                  width: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
