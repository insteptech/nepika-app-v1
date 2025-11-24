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
    debugPrint('🔍 NAVBAR: Tapped index $index, route: ${_navRoutes[index]}');
    widget.onNavBarTap(index, _navRoutes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final navBarHeight = (widget.height ?? kNavBarHeight).clamp(60.0, 120.0); // Ensure reasonable bounds
    
    return Container(
      height: navBarHeight,
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Ensure proper height distribution
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
                    constraints: BoxConstraints(
                      minHeight: 60.0, // Minimum height for nav items
                      maxHeight: navBarHeight,
                    ),
                    child: index == 2 
                      ? _buildScanItem(context, iconPath, navBarHeight)
                      : _buildRegularItem(context, iconPath, isActive, index, navBarHeight),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildScanItem(BuildContext context, String iconPath, double navBarHeight) {
    // Ensure scan button doesn't exceed available space
    final maxScanSize = navBarHeight * 0.8;
    final minScanSize = 40.0;
    final scanSize = maxScanSize.clamp(minScanSize, 56.0);
    
    return Center(
      child: Container(
        width: scanSize,
        height: scanSize,
        constraints: BoxConstraints(
          maxWidth: scanSize,
          maxHeight: scanSize,
          minWidth: minScanSize,
          minHeight: minScanSize,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Responsive icon size based on container size
              final iconSize = (scanSize * 0.45).clamp(16.0, 28.0); // Responsive with bounds
              
              return Image.asset(
                iconPath,
                width: iconSize,
                height: iconSize,
                color: Theme.of(context).colorScheme.onTertiary,
                fit: BoxFit.contain,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRegularItem(BuildContext context, String iconPath, bool isActive, int index, double navBarHeight) {
    // Ensure minimum sizes and proper scaling
    final minIconSize = 16.0;
    final minTextSize = 8.0;
    final maxIconSize = 24.0;
    final maxTextSize = 12.0;
    
    // Calculate sizes with bounds checking
    final iconSize = (navBarHeight * 0.25).clamp(minIconSize, maxIconSize);
    final textSize = (navBarHeight * 0.14).clamp(minTextSize, maxTextSize);
    
    // Calculate available space for content
    final spacing = 2.0;
    final totalContentHeight = iconSize + spacing + (textSize * 1.2); // Include line height
    
    // Use LayoutBuilder to get actual constraints
    return LayoutBuilder(
      builder: (context, constraints) {
        // If content won't fit, use Flexible layout
        if (constraints.maxHeight < totalContentHeight) {
          return _buildCompactItem(context, iconPath, isActive, index, constraints);
        }
        
        // Normal layout when space is available
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10), // 10px space at the top
            Flexible(
              child: Image.asset(
                iconPath,
                width: iconSize,
                height: iconSize,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: spacing),
            Flexible(
              child: Text(
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildCompactItem(BuildContext context, String iconPath, bool isActive, int index, BoxConstraints constraints) {
    // Compact layout for very small spaces
    final availableHeight = constraints.maxHeight;
    final compactIconSize = (availableHeight * 0.6).clamp(12.0, 20.0);
    final compactTextSize = (availableHeight * 0.25).clamp(6.0, 10.0);
    
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8), // Reduced spacing for compact layout
          Image.asset(
            iconPath,
            width: compactIconSize,
            height: compactIconSize,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fit: BoxFit.contain,
          ),
          if (availableHeight > compactIconSize + 16) // Adjusted for top spacing
            Text(
              _navRoutesName[index],
              style: TextStyle(
                fontSize: compactTextSize,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.0,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
        ],
      ),
    );
  }
}
