import 'package:flutter/material.dart';
import 'package:nepika/features/community/widgets/user_icon.dart';
import '../../../../domain/community/entities/community_entities.dart';

/// Create post widget for initiating new posts
/// Follows Single Responsibility Principle - only handles create post UI
class CreatePostWidget extends StatelessWidget {
  final VoidCallback? onCreatePostTap;
  final AuthorEntity? currentUser;
  final CommunityProfileEntity? currentUserProfile;
  
  const CreatePostWidget({
    super.key,
    this.onCreatePostTap,
    this.currentUser,
    this.currentUserProfile,
  });

  /// Convert CommunityProfileEntity to AuthorEntity for UserImageIcon
  AuthorEntity? get _getAuthor {
    if (currentUserProfile != null) {
      return AuthorEntity(
        id: currentUserProfile!.userId,
        fullName: currentUserProfile!.username,
        avatarUrl: currentUserProfile!.profileImageUrl ?? '',
      );
    }
    return currentUser;
  }

  @override
  Widget build(BuildContext context) {
    final author = _getAuthor;
    
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onCreatePostTap ?? () {
        FocusScope.of(context).unfocus(); // Dismiss keyboard
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // User Avatar or Default Logo
          if (author != null)
            UserImageIcon(author: author)
          else
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.person,
                size: 24,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
          
          const SizedBox(width: 15),
          
          // Create Post Text
          Expanded(
            child: Text(
              'Create a new Post...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          
          const SizedBox(width: 10),
          
          // Share Icon
          GestureDetector(
            onTap: onCreatePostTap,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Image.asset(
                'assets/icons/share_icon.png',
                height: 20,
              ),
            ),
          ), 
        ],
      ),
    );
  }
}