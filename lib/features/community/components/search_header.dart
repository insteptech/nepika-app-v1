import 'package:flutter/material.dart';
import '../../../core/config/constants/theme.dart';
import '../../../core/widgets/back_button.dart';

/// Search header component with back button, title, and search input
/// Follows Single Responsibility Principle - only handles search header UI
class SearchHeader extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;

  SearchHeader({required this.searchController});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isStuckToTop = shrinkOffset > 0;
    
    return Container(
      color: Theme.of(context).colorScheme.onTertiary,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: isStuckToTop ? 15 : 0,
        bottom: 10,
      ),
      child: Column(
        children: [
          SizedBox(height: 10),
          // Header with back button and title
          Row(
            children: [
              CustomBackButton(
                label: '',
                iconSize: 24,
                iconColor: Theme.of(context).colorScheme.primary,
              ),
              Expanded(
                child: Text(
                  'Search',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 40), // Balance the back button width
            ],
          ),
          
          const SizedBox(height: 15),
          
          // Search Input Field
          Container(
            height: 53,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onTertiary,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Theme.of(context).textTheme.headlineMedium!
                    .secondary(context)
                    .color!,
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.only(right: 3),
            child: TextField(
              controller: searchController,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: Theme.of(
                  context,
                ).textTheme.bodyLarge!.secondary(context),
                fillColor: Colors.transparent,
                prefixIcon: SizedBox(
                  width: 10,
                  height: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Image.asset(
                      'assets/icons/search_icon.png',
                      height: 10,
                      width: 10,
                    ),
                  ),
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 120.0;
  
  @override
  double get minExtent => 120.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}