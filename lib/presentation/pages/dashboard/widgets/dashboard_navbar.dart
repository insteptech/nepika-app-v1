import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/theme.dart';

const double kNavBarIconSize = 22.0;
const double kScanIconSize = 24.0;

class DashboardNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int index, String route) onNavBarTap;

  const DashboardNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onNavBarTap,
  }) : super(key: key);

  @override
  State<DashboardNavBar> createState() => _DashboardNavBarState();
}

class _DashboardNavBarState extends State<DashboardNavBar> {
  static const _icons = [
    'assets/icons/home_icon.png',
    'assets/icons/2_people.png',
    'assets/icons/scan_icon.png',
    'assets/icons/box_icon.png',
    'assets/icons/person_icon.png',
  ];
  static const _filledIcons = [
    'assets/icons/filled/home_icon.png',
    'assets/icons/filled/community_icon.png',
    'assets/icons/scan_icon.png',
    'assets/icons/filled/box_icon.png',
    'assets/icons/filled/person_icon.png',
  ];

  static const _navRoutes = [
    AppRoutes.dashboardHome,
    AppRoutes.communityHome,
    AppRoutes.cameraScanGuidence,
    AppRoutes.notFound,
    AppRoutes.dashboardSettings,
  ];

  static const _navRoutesName = [
    'Home',
    'Community',
    'Scan',
    'Products',
    'Settings',
  ];

  void _onTabTapped(int index) {
    if (widget.selectedIndex == index && _navRoutes[index] != AppRoutes.cameraScanGuidence) {
      return;
    }
    
    
    if (index == 1) { 
      Navigator.of(context, rootNavigator: true).pushNamed(_navRoutes[index]);
      return;
    }
    
    widget.onNavBarTap(index, _navRoutes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 25, left: 10, right: 10),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_icons.length, (index) {
          final isActive = index == widget.selectedIndex;
          final iconPath = isActive ? _filledIcons[index] : _icons[index];
          
          return GestureDetector(
            onTap: () => _onTabTapped(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (index == 2) ...[
                  // Scan icon larger and no label
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
                  SizedBox(
                    width: kNavBarIconSize,
                    height: kNavBarIconSize,
                    child: Image.asset(
                      iconPath,
                      width: kNavBarIconSize,
                      height: kNavBarIconSize,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _navRoutesName[index],
                    style: isActive
                        ? Theme.of(context).textTheme.bodySmall!.hint(context)
                        : Theme.of(context).textTheme.bodySmall!.secondary(context),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}
