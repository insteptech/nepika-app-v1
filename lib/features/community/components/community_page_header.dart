import 'package:flutter/material.dart';
import '../../../core/widgets/back_button.dart';

/// Community page header component matching original design
/// Features: Logo in center, back button on left, search/action on right
class CommunityPageHeader extends StatelessWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onActionTap;
  final Widget? actionIcon;
  final bool showLogo;
  final String? title;
  
  const CommunityPageHeader({
    super.key,
    this.onSearchTap,
    this.onActionTap,
    this.actionIcon,
    this.showLogo = true,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center Logo or Title
          if (showLogo && title == null)
            Image.asset(
              'assets/images/nepika_logo_image.png',
              height: 30,
              color: Theme.of(context).colorScheme.primary,
            )
          else if (title != null)
            Text(
              title!,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

          // Left and Right Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomBackButton(
                onPressed: () => Navigator.of(context).pop(),
              ),

              if (onSearchTap != null)
                GestureDetector(
                  onTap: onSearchTap,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/icons/search_icon.png',
                      height: 25,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                )
              else if (actionIcon != null)
                GestureDetector(
                  onTap: onActionTap,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: actionIcon!,
                  ),
                )
              else
                const SizedBox(width: 48), // Balance the back button
            ],
          ),
        ],
      ),
    );
  }
}

/// Animated profile header delegate matching original design
class CommunityProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String userName;
  final Animation<double> nameOpacity;
  final VoidCallback onBackPressed;
  final VoidCallback onMenuPressed;

  CommunityProfileHeaderDelegate({
    required this.userName,
    required this.nameOpacity,
    required this.onBackPressed,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: onBackPressed,
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).iconTheme.color,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              
              Expanded(
                child: AnimatedBuilder(
                  animation: nameOpacity,
                  builder: (context, child) {
                    return Opacity(
                      opacity: nameOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - nameOpacity.value) * 10),
                        child: Text(
                          userName,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              IconButton(
                onPressed: onMenuPressed,
                icon: Image.asset(
                  'assets/icons/menu_icon.png',
                  width: 24,
                  height: 24,
                  color: Theme.of(context).iconTheme.color,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 56.0;

  @override
  double get minExtent => 56.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate is! CommunityProfileHeaderDelegate ||
           oldDelegate.userName != userName ||
           oldDelegate.nameOpacity != nameOpacity;
  }
}