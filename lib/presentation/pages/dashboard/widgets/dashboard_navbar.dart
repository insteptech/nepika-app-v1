import 'package:flutter/material.dart';
import 'package:nepika/core/constants/routes.dart';

const double kNavBarIconSize = 24.0;
const double kScanIconSize = 28.0;

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
    'assets/icons/clock_icon.png',
    'assets/icons/scan_icon.png',
    'assets/icons/box_icon.png',
    'assets/icons/person_icon.png',
  ];

  static const _navRoutes = [
    AppRoutes.dashboardHome,
    AppRoutes.dashboardExplore,
    AppRoutes.cameraScan,
    AppRoutes.dashboardAllProducts,
    AppRoutes.dashboardSettings,
  ];

  void _onTabTapped(int index) {
    if (widget.selectedIndex == index && _navRoutes[index] != AppRoutes.cameraScan) {
      // Don't navigate if same tab is tapped (except for camera scan)
      return;
    }

    final route = _navRoutes[index];

    print('\n\n\n\n\n');
    print('============ Tapped index: $index, route: $route ============');
    print('\n\n\n\n\n');

    // Call the parent's navigation handler
    widget.onNavBarTap(index, route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 15, bottom: 35, left: 10, right: 10),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_icons.length, (index) {
          final isActive = index == widget.selectedIndex;

          return GestureDetector(
            onTap: () => _onTabTapped(index),
            child: index == 2
                ? Container(
                    width: 65,
                    height: 65,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        // BoxShadow(
                        //   color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        //   blurRadius: 12,
                        //   offset: const Offset(0, 4),
                        // ),
                      ],
                    ),
                    child: Image.asset(
                      _icons[index],
                      width: kScanIconSize,
                      height: kScanIconSize,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  )
                : SizedBox(
                    width: 22,
                    height: 22,
                    child: Image.asset(
                      _icons[index],
                      width: 12,
                      height: 12,
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).iconTheme.color,
                    ),
                  ),
          );
        }),
      ),
    );
  }
}