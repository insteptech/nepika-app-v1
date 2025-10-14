import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/theme.dart';

const double kNavBarIconSize = 22.0;
const double kScanIconSize = 24.0;

class DashboardNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int index, String route) onNavBarTap;

  const DashboardNavBar({
    super.key,
    required this.selectedIndex,
    required this.onNavBarTap,
  });

  @override
  State<DashboardNavBar> createState() => _DashboardNavBarState();
}

class _DashboardNavBarState extends State<DashboardNavBar> {
  static const _icons = [
    'assets/icons/home_icon.png',
    'assets/icons/2_people.png',
    'assets/icons/scan_icon.png',
    'assets/icons/history_icon.png',
    'assets/icons/person_icon.png',
  ];
  static const _filledIcons = [
    'assets/icons/filled/home_icon.png',
    'assets/icons/filled/2_people.png',
    'assets/icons/scan_icon.png',
    'assets/icons/filled/history_icon.png',
    'assets/icons/filled/person_icon.png',
  ];

  static const _navRoutes = [
    AppRoutes.dashboardHome,
    AppRoutes.communityHome,
    AppRoutes.cameraScanGuidence,
    AppRoutes.dashboardHistory,
    AppRoutes.dashboardSettings,
  ];

  static const _navRoutesName = [
    'Home',
    'Community',
    'Scan',
    'History',
    'Settings',
  ];

  void _onTabTapped(int index) {
    if (widget.selectedIndex == index && _navRoutes[index] != AppRoutes.cameraScanGuidence) {
      return;
    }


    // if (index == 1) {
    //   Navigator.of(context, rootNavigator: true).pushNamed(_navRoutes[index]);
    //   return;
    // }

    widget.onNavBarTap(index, _navRoutes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth / _icons.length;
    
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 25),
      color: Colors.transparent,
      child: Row(
        children: List.generate(_icons.length, (index) {
          final isActive = index == widget.selectedIndex;
          final iconPath = isActive ? _filledIcons[index] : _icons[index];
          
          return SizedBox(
            width: buttonWidth,
            child: IconButton(
              onPressed: () => _onTabTapped(index),
              padding: const EdgeInsets.symmetric(vertical: 8),
              splashRadius: 100,
              iconSize: index == 2 ? 55 : kNavBarIconSize + 8,
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (index == 2) ...[
                    // Scan icon - larger with circular background
                    Container(
                      width: 55,
                      height: 55,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        iconPath,
                        width: kScanIconSize,
                        height: kScanIconSize,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                  ] else ...[
                    // Regular tab icon
                    Image.asset(
                      iconPath,
                      width: kNavBarIconSize,
                      height: kNavBarIconSize,
                      color: Theme.of(context).
                      colorScheme.primary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _navRoutesName[index],
                      style: isActive
                          ? Theme.of(context).textTheme.bodySmall!.hint(context)
                          : Theme.of(context).textTheme.bodySmall!.secondary(context),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
