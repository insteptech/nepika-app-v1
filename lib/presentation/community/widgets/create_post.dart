import 'package:flutter/material.dart';

class CreatePostWidget extends StatelessWidget {
  final VoidCallback? onCreatePostTap;
  
  const CreatePostWidget({
    super.key,
    this.onCreatePostTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onCreatePostTap ?? () {
        FocusScope.of(context).unfocus(); // Dismiss keyboard
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
            Container(
              height: 50,
              width: 50,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                'assets/images/nepika_logo_image.png',
                height: 10,
                color: Theme.of(context).colorScheme.onSecondary,
                fit: BoxFit.scaleDown,
              ),
              )
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 15,
              ),
              child: Text(
                'Create a new Post...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onCreatePostTap,
            child: Image.asset(
              'assets/icons/share_icon.png',
              height: 20,
            ),
          ), 
        ],
      ),
    );
  }
}
