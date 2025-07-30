import 'package:flutter/material.dart';
import '../mixins/widget_behaviors.dart';
import '../buttons/action_buttons.dart';

/// Navigation Bar for questionnaire flow
class QuestionnaireNavigation extends StatelessWidget 
    with ThemeAwareBehavior, NavigableBehavior {
  final bool showBackButton;
  final bool showSkipButton;
  final bool showNextButton;
  final String? backLabel;
  final String? skipLabel;
  final String? nextLabel;
  final VoidCallback? onBackPressed;
  final VoidCallback? onSkipPressed;
  final VoidCallback? onNextPressed;
  final bool isNextEnabled;
  final EdgeInsets? padding;

  const QuestionnaireNavigation({
    super.key,
    this.showBackButton = true,
    this.showSkipButton = true,
    this.showNextButton = true,
    this.backLabel,
    this.skipLabel,
    this.nextLabel,
    this.onBackPressed,
    this.onSkipPressed,
    this.onNextPressed,
    this.isNextEnabled = true,
    this.padding,
  });

  @override
  void goBack() {
    onBackPressed?.call();
  }

  @override
  void goNext() {
    onNextPressed?.call();
  }

  @override
  void skip() {
    onSkipPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: getBackgroundColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          if (showBackButton)
            TextActionButton(
              text: backLabel ?? 'Back',
              icon: Icons.arrow_back,
              onPressed: onBackPressed,
            )
          else
            const SizedBox(width: 80), // Placeholder for alignment
          
          // Spacer
          const Spacer(),
          
          // Skip Button
          if (showSkipButton)
            TextActionButton(
              text: skipLabel ?? 'Skip',
              onPressed: onSkipPressed,
            ),
          
          const SizedBox(width: 12),
          
          // Next Button
          if (showNextButton)
            PrimaryButton(
              text: nextLabel ?? 'Next',
              icon: Icons.arrow_forward,
              onPressed: isNextEnabled ? onNextPressed : null,
              isDisabled: !isNextEnabled,
            ),
        ],
      ),
    );
  }
}

/// Bottom Navigation with consistent styling
class CustomBottomNavigation extends StatelessWidget with ThemeAwareBehavior {
  final int currentIndex;
  final List<BottomNavigationBarItem> items;
  final void Function(int)? onTap;
  final BottomNavigationBarType? type;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.items,
    this.onTap,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      items: items,
      onTap: onTap,
      type: type ?? BottomNavigationBarType.fixed,
      selectedItemColor: getPrimaryColor(context),
      unselectedItemColor: Colors.grey.shade600,
      backgroundColor: getBackgroundColor(context),
      elevation: 8,
    );
  }
}

/// Drawer Navigation
class CustomDrawer extends StatelessWidget with ThemeAwareBehavior {
  final Widget? header;
  final List<DrawerItem> items;
  final int? selectedIndex;
  final void Function(int)? onItemTap;

  const CustomDrawer({
    super.key,
    this.header,
    required this.items,
    this.selectedIndex,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: getBackgroundColor(context),
      child: Column(
        children: [
          if (header != null) header!,
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == index;
                
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: isSelected 
                        ? getPrimaryColor(context) 
                        : Colors.grey.shade600,
                  ),
                  title: Text(
                    item.title,
                    style: getTextTheme(context).bodyMedium?.copyWith(
                      color: isSelected 
                          ? getPrimaryColor(context) 
                          : Colors.grey.shade800,
                      fontWeight: isSelected 
                          ? FontWeight.w600 
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: getPrimaryColor(context).withOpacity(0.1),
                  onTap: () => onItemTap?.call(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Drawer Item Model
class DrawerItem {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const DrawerItem({
    required this.title,
    required this.icon,
    this.onTap,
  });
}

/// App Bar with consistent styling
class CustomAppBar extends StatelessWidget with ThemeAwareBehavior 
    implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double? elevation;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.elevation,
    this.backgroundColor,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null 
          ? Text(
              title!,
              style: getTextTheme(context).titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: elevation ?? 2,
      backgroundColor: backgroundColor ?? getPrimaryColor(context),
      foregroundColor: Colors.white,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}

/// Tab Navigation
class CustomTabBar extends StatelessWidget with ThemeAwareBehavior {
  final List<Tab> tabs;
  final TabController? controller;
  final void Function(int)? onTap;
  final bool isScrollable;

  const CustomTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.onTap,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      tabs: tabs,
      controller: controller,
      onTap: onTap,
      isScrollable: isScrollable,
      indicatorColor: getPrimaryColor(context),
      labelColor: getPrimaryColor(context),
      unselectedLabelColor: Colors.grey.shade600,
      labelStyle: getTextTheme(context).titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: getTextTheme(context).titleSmall,
    );
  }
}
