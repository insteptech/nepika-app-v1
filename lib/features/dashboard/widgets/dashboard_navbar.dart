import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/routes.dart';

const double kNavBarIconSize = 22.0;
const double kScanIconSize = 24.0;
const double kNavBarHeight = 80.0; // Configurable navbar height
const double kScanButtonSize = 48.0; // Configurable scan button size
const double kIconTextSpacing = 3.0; // Configurable spacing

class DashboardNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int index, String route) onNavBarTap;
  final double? height; // Optional height parameter
  final double? scanButtonSize; // Optional scan button size

  const DashboardNavBar({
    super.key,
    required this.selectedIndex,
    required this.onNavBarTap,
    this.height,
    this.scanButtonSize,
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
    final navBarHeight = widget.height ?? kNavBarHeight;
    
    return Container(
      height: navBarHeight,
      color: Colors.transparent,
      child: Row(
        children: List.generate(_icons.length, (index) {
          final isActive = index == widget.selectedIndex;
          final iconPath = isActive ? _filledIcons[index] : _icons[index];
          
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onTabTapped(index),
                // Custom splash color that covers full height and width/5 with no radius
                splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                highlightColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.zero, // No radius as requested
                child: Container(
                  height: navBarHeight,
                  width: double.infinity,
                  child: index == 2 
                    ? _buildScanItem(context, iconPath, navBarHeight)
                    : _buildRegularItem(context, iconPath, isActive, index, navBarHeight),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScanItem(BuildContext context, String iconPath, double navBarHeight) {
    final scanSize = navBarHeight * 0.7;
    return Center(
      child: Container(
        width: scanSize,
        height: scanSize,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Image.asset(
            iconPath,
            width: scanSize * 0.5,
            height: scanSize * 0.5,
            color: Theme.of(context).colorScheme.onTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildRegularItem(BuildContext context, String iconPath, bool isActive, int index, double navBarHeight) {
    final iconSize = navBarHeight * 0.25;
    final textSize = navBarHeight * 0.14;
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            iconPath,
            width: iconSize,
            height: iconSize,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          SizedBox(height: 2),
          Text(
            _navRoutesName[index],
            style: TextStyle(
              fontSize: textSize,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
