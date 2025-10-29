import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nepika/domain/community/entities/community_entities.dart';
import 'package:nepika/features/community/utils/community_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nepika/core/widgets/back_button.dart';
import '../../../core/config/constants/routes.dart';
import '../../../core/config/constants/theme.dart';
import '../../../core/config/constants/app_constants.dart';

class CommunitySettingsScreen extends StatefulWidget {
  const CommunitySettingsScreen({super.key});

  @override
  State<CommunitySettingsScreen> createState() => _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState extends State<CommunitySettingsScreen> {
  bool _isPrivateProfile = false;
  String? _token;
  CommunityProfileEntity? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.accessTokenKey);
      final userDataString = prefs.getString(AppConstants.userDataKey);
      
      if (token != null && mounted) {
        setState(() {
          _token = token;
        });
        
        // Parse user data if available
        if (userDataString != null) {
          try {
            final userData = json.decode(userDataString);
            if (mounted) {
              setState(() {
                _currentUserProfile = CommunityProfileEntity(
                  id: userData['id']?.toString() ?? userData['user_id']?.toString() ?? '',
                  userId: userData['user_id']?.toString() ?? '',
                  username: userData['username']?.toString() ?? '',
                  bio: userData['bio']?.toString(),
                  profileImageUrl: userData['profile_image']?.toString(),
                  isPrivate: userData['is_private'] as bool? ?? false,
                  isVerified: userData['is_verified'] as bool? ?? false,
                  postsCount: userData['posts_count'] as int? ?? 0,
                  followersCount: userData['followers_count'] as int? ?? 0,
                  followingCount: userData['following_count'] as int? ?? 0,
                  createdAt: userData['created_at'] != null 
                      ? DateTime.parse(userData['created_at'].toString())
                      : DateTime.now(),
                  isFollowing: false,
                  isSelf: true,
                );
              });
            }
          } catch (e) {
            debugPrint('Error parsing user data: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 10),
              child: Row(
              children: [
                CustomBackButton(),
              ],
            ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    
                    // Community Settings Section
                    _buildSectionHeader('Community Settings'),
                    _buildDivider(),
                    _buildCommunitySettingsSection(),
                    
                    const SizedBox(height: 10),
                    
                    // App Settings Section
                    _buildSectionHeader('App Settings'),
                    _buildDivider(),
                    _buildAppSettingsSection(),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.brightness == Brightness.dark 
              ? AppTheme.textSecondaryDark 
              : AppTheme.textSecondaryLight,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    final theme = Theme.of(context);
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 0,vertical: 10),
      color: theme.brightness == Brightness.dark 
          ? AppTheme.textSecondaryDark.withValues(alpha: 0.2)
          : AppTheme.textSecondaryLight.withValues(alpha: 0.2),
    );
  }

  Widget _buildCommunitySettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
                    const SizedBox(height: 16),
          _buildPrivateProfileOption(),
          const SizedBox(height: 16),
          _buildOptionItem(
            icon: Icons.people_outline,
            title: 'Profiles you Follow',
            onTap: () => _navigateToFollowingSettings(),
          ),
          const SizedBox(height: 16),
          _buildOptionItem(
            icon: Icons.block_outlined,
            title: 'Blocked Users',
            onTap: () => _navigateToBlockedAccounts(),
          ),
          // const SizedBox(height: 16),
          // _buildOptionItem(
          //   icon: Icons.edit_outlined,
          //   title: 'Edit Profile',
          //   onTap: () => _navigateToEditProfile(),
          // ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAppSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildOptionItem(
            icon: Icons.settings_outlined,
            title: 'Other Setting',
            onTap: () => _navigateToAdvancedSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateProfileOption() {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark 
                ? AppTheme.surfaceColorDark 
                : AppTheme.surfaceColorLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.lock_outline,
            size: 20,
            color: theme.brightness == Brightness.dark 
                ? AppTheme.textPrimaryDark 
                : AppTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Private Profile',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.brightness == Brightness.dark 
                  ? AppTheme.textPrimaryDark 
                  : AppTheme.textPrimaryLight,
            ),
          ),
        ),
        SizedBox(
          width: 58,
          height: 35,
          child: Switch(
            value: _isPrivateProfile,
            onChanged: (value) {
              setState(() {
                _isPrivateProfile = value;
              });
            },
            activeColor: AppTheme.whiteBlack,
            activeTrackColor: AppTheme.primaryColor,
            inactiveThumbColor: AppTheme.whiteBlack,
            inactiveTrackColor: (theme.brightness == Brightness.dark 
                ? AppTheme.textSecondaryDark 
                : AppTheme.textSecondaryLight).withValues(alpha: 0.3),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }


  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark 
                  ? AppTheme.surfaceColorDark 
                  : AppTheme.surfaceColorLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.brightness == Brightness.dark 
                  ? AppTheme.textPrimaryDark 
                  : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.brightness == Brightness.dark 
                    ? AppTheme.textPrimaryDark 
                    : AppTheme.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }



  void _navigateToFollowingSettings() {
    // TODO: Implement following settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Following settings - Coming soon')),
    );
  }

  void _navigateToBlockedAccounts() {
    // Navigate to blocked users screen
    Navigator.of(context).pushNamed(AppRoutes.blockedUsers);
  }


  void _navigateToAdvancedSettings() {
    // Navigate to main app settings
    Navigator.of(context).pushNamed(AppRoutes.dashboardSettings);
  }

  void _navigateToEditProfile() async {
    Navigator.of(context).pop(); // Close drawer

    if (_token != null) {
      // Navigate to edit profile screen using CommunityNavigation
      await CommunityNavigation.navigateToEditProfile(
        context,
        token: _token!,
        currentUsername: _currentUserProfile?.username,
        currentBio: _currentUserProfile?.bio,
        currentProfileImage: _currentUserProfile?.profileImageUrl,
      );
    } else {
      // Show error if token is not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to edit profile. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
   }
}