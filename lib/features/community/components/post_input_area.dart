import 'package:flutter/material.dart';
import '../../../../domain/community/entities/community_entities.dart';

/// Post input area component with text editor and word count
/// Follows Single Responsibility Principle - only handles post content input
class PostInputArea extends StatelessWidget {
  final TextEditingController controller;
  final int wordCount;
  final int maxWords;
  final CommunityProfileEntity? userProfile;
  final VoidCallback onMediaTap;

  const PostInputArea({
    super.key,
    required this.controller,
    required this.wordCount,
    required this.maxWords,
    required this.userProfile,
    required this.onMediaTap,
  });

  Color get _wordCountColor {
    if (wordCount > maxWords) return Colors.red;
    if (wordCount > maxWords * 0.8) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Row
          Row(
            children: [
              // User Avatar
              CircleAvatar(
                radius: 20,
                backgroundImage: userProfile?.profileImageUrl != null &&
                        userProfile!.profileImageUrl!.isNotEmpty
                    ? NetworkImage(userProfile!.profileImageUrl!)
                    : null,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                child: userProfile?.profileImageUrl == null ||
                        userProfile!.profileImageUrl!.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userProfile?.username ?? 'Loading...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Public post',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Media Button
              IconButton(
                onPressed: onMediaTap,
                icon: const Icon(Icons.photo_library),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[700],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Text Input
          TextField(
            controller: controller,
            maxLines: null,
            minLines: 3,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: "What's happening?",
              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[500],
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          
          const SizedBox(height: 16),
          
          // Word Count
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$wordCount/$maxWords words',
                style: TextStyle(
                  color: _wordCountColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}