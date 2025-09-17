import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme.dart';

class ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String userName;
  final Animation<double> nameOpacity;
  final VoidCallback onBackPressed;
  final VoidCallback onMenuPressed;

  ProfileHeaderDelegate({
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
        color: Theme.of(context).scaffoldBackgroundColor,
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
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).iconTheme.color,
                  size: 24,
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
    return oldDelegate is! ProfileHeaderDelegate ||
           oldDelegate.userName != userName ||
           oldDelegate.nameOpacity != nameOpacity;
  }
}

class ProfileHeaderWidget extends StatelessWidget {
  final String userName;
  final Animation<double> nameOpacity;
  final VoidCallback onBackPressed;
  final VoidCallback onMenuPressed;

  const ProfileHeaderWidget({
    super.key,
    required this.userName,
    required this.nameOpacity,
    required this.onBackPressed,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: nameOpacity,
                  builder: (context, child) {
                    return Opacity(
                      opacity: nameOpacity.value,
                      child: Text(
                        userName,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                onPressed: onMenuPressed,
                icon: Icon(
                  Icons.more_vert, 
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}