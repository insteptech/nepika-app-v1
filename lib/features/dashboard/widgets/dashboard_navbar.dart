import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/utils/trial_gate_helper.dart';

const double kNavBarHeight = 80.0; // Configurable navbar height

class DashboardNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int index, String route) onNavBarTap;
  final double? height; // Optional height parameter
  final double? scanButtonSize; // Optional scan button size
  final bool isProfessional; // Added to distinguish user roles

  const DashboardNavBar({
    super.key,
    required this.selectedIndex,
    required this.onNavBarTap,
    this.height,
    this.scanButtonSize,
    this.isProfessional = false,
  });

  @override
  State<DashboardNavBar> createState() => _DashboardNavBarState();
}

class _DashboardNavBarState extends State<DashboardNavBar> {
  // --- Regular User Configuration (5 Tabs) ---
  static const _regularIcons = [
    'assets/icons/home_icon.png',
    'assets/icons/2_people.png',
    'assets/icons/scan_icon.png',
    'assets/icons/history_icon.png',
    'assets/icons/person_icon.png',
  ];
  static const _regularFilledIcons = [
    'assets/icons/filled/home_icon.png',
    'assets/icons/filled/2_people.png',
    'assets/icons/scan_icon.png',
    'assets/icons/filled/history_icon.png',
    'assets/icons/filled/person_icon.png',
  ];
  static const _regularRoutes = [
    AppRoutes.dashboardHome,
    AppRoutes.communityHome,
    AppRoutes.cameraScanGuidence,
    AppRoutes.dashboardHistory,
    AppRoutes.dashboardSettings,
  ];
  static const _regularNames = [
    'Home',
    'Community',
    'Scan',
    'History',
    'Settings',
  ];

  // --- Professional User Configuration (4 Tabs) ---
  // Using a mix of assets and Material icons where assets are missing
  static const _professionalRoutes = [
    AppRoutes.communityHome,
    AppRoutes.dashboardClients,
    AppRoutes.dashboardProfile,
    AppRoutes.dashboardSettings,
  ];
  static const _professionalNames = [
    'Community',
    'Clients',
    'Profile',
    'Settings',
  ];

  // Gets the current configuration based on role
  List<String> get _currentRoutes => widget.isProfessional ? _professionalRoutes : _regularRoutes;
  int get tabCount => widget.isProfessional ? 4 : 5;

  void _onTabTapped(int index) async {
    final routes = _currentRoutes;
    if (widget.selectedIndex == index && routes[index] != AppRoutes.cameraScanGuidence) {
      return;
    }

    if (routes[index] == AppRoutes.cameraScanGuidence) {
      if (await TrialGateHelper.shouldBlockScan(context)) {
        debugPrint('🚨 Trial limit reached. Showing Trial Expired Sheet.');
        TrialGateHelper.showTrialExpiredSheet(context);
        return;
      }
    }

    debugPrint('🔍 NAVBAR: Tapped index $index, route: ${routes[index]}');
    widget.onNavBarTap(index, routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final navBarHeight = (widget.height ?? kNavBarHeight).clamp(60.0, 120.0);
    
    return Container(
      height: navBarHeight,
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(tabCount, (index) {
            final isActive = index == widget.selectedIndex;
            
            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onTabTapped(index),
                  splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  highlightColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.zero,
                  child: Container(
                    height: navBarHeight,
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: 60.0,
                      maxHeight: navBarHeight,
                    ),
                    child: Builder(
                      builder: (context) {
                        if (!widget.isProfessional && index == 2) {
                          // Regular user Face Scan item
                          return _buildScanItem(context, _regularIcons[index], navBarHeight);
                        } else {
                          // Standard item
                          final name = widget.isProfessional ? _professionalNames[index] : _regularNames[index];
                          return _buildRegularItem(context, isActive, index, navBarHeight, name);
                        }
                      }
                    ),
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
              final iconSize = (scanSize * 0.45).clamp(16.0, 28.0);
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

  // A helper dynamic icon resolver
  Widget _buildIcon(BuildContext context, bool isActive, int index, double iconSize) {
    final color = isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    if (widget.isProfessional) {
      String iconPath;
      if (index == 0) {
        iconPath = isActive ? 'assets/icons/filled/2_people.png' : 'assets/icons/2_people.png';
      } else if (index == 1) {
        iconPath = isActive ? 'assets/icons/filled/box_icon.png' : 'assets/icons/box_icon.png';
      } else if (index == 2) {
        iconPath = isActive ? 'assets/icons/filled/person_icon.png' : 'assets/icons/person_icon.png';
      } else {
        iconPath = 'assets/icons/horizontal_lines_with_dots.png'; // settings menu equivalent
      }
      return Image.asset(
        iconPath,
        width: iconSize,
        height: iconSize,
        color: color,
        fit: BoxFit.contain,
      );
    } else {
      final iconPath = isActive ? _regularFilledIcons[index] : _regularIcons[index];
      return Image.asset(
        iconPath,
        width: iconSize,
        height: iconSize,
        color: color,
        fit: BoxFit.contain,
      );
    }
  }

  Widget _buildRegularItem(BuildContext context, bool isActive, int index, double navBarHeight, String name) {
    final minIconSize = 16.0;
    final minTextSize = 8.0;
    final maxIconSize = 24.0;
    final maxTextSize = 12.0;
    
    final iconSize = (navBarHeight * 0.25).clamp(minIconSize, maxIconSize);
    final textSize = (navBarHeight * 0.14).clamp(minTextSize, maxTextSize);
    
    final spacing = 2.0;
    final totalContentHeight = iconSize + spacing + (textSize * 1.2);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight < totalContentHeight) {
          return _buildCompactItem(context, isActive, index, constraints, name);
        }
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Flexible(child: _buildIcon(context, isActive, index, iconSize)),
            SizedBox(height: spacing),
            Flexible(
              child: Text(
                name,
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
  
  Widget _buildCompactItem(BuildContext context, bool isActive, int index, BoxConstraints constraints, String name) {
    final availableHeight = constraints.maxHeight;
    final compactIconSize = (availableHeight * 0.6).clamp(12.0, 20.0);
    final compactTextSize = (availableHeight * 0.25).clamp(6.0, 10.0);
    
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          _buildIcon(context, isActive, index, compactIconSize),
          if (availableHeight > compactIconSize + 16)
            Text(
              name,
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

