import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme.dart';
import '../../../domain/community/entities/community_entities.dart';

class ProfileInfo extends StatelessWidget {
  final CommunityProfileEntity? profileData;
  final VoidCallback onEditProfile;
  final VoidCallback onShareProfile;

  const ProfileInfo({
    super.key,
    required this.profileData,
    required this.onEditProfile,
    required this.onShareProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.language,
                size: 20,
                color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
              ),
              
              const Spacer(),
              
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(42),
                  child: (profileData?.profileImageUrl != null && profileData?.profileImageUrl?.isNotEmpty == true)
                      ? Image.network(
                          profileData?.profileImageUrl ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text(
            profileData?.username ?? 'User',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            '${profileData?.username ?? 'username'} • threads.net',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
            ),
          ),
          
          const SizedBox(height: 12),
          
          if (profileData?.bio != null && profileData!.bio!.isNotEmpty) ...[
            Text(
              profileData!.bio!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          Text(
            '${profileData?.followersCount ?? 0} ${(profileData?.followersCount ?? 0) == 1 ? 'follower' : 'followers'}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
            ),
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  'Edit profile',
                  true,
                  onEditProfile,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  'Share profile',
                  false,
                  onShareProfile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE5E7EB),
      ),
      child: const Icon(
        Icons.person,
        size: 40,
        color: Color(0xFF6B7280),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    bool isPrimary,
    VoidCallback? onPressed,
  ) {
    return SizedBox(
      height: 36,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onSurface,
                foregroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}