import 'package:flutter/material.dart';
import 'package:nepika/core/widgets/back_button.dart';

class PageHeader extends StatelessWidget {
  final VoidCallback? onSearchTap;
  
  const PageHeader({
    super.key,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/nepika_logo_image.png',
            height: 30,
            color: Theme.of(context).colorScheme.primary,
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomBackButton(onPressed: () => Navigator.of(context).pop()),

              GestureDetector(
                onTap: onSearchTap,
                child: Image.asset(
                  'assets/icons/search_icon.png',
                  height: 25,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
