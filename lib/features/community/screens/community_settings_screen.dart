import 'package:flutter/material.dart';
import '../../../core/config/constants/routes.dart';

class CommunitySettingsScreen extends StatefulWidget {
  const CommunitySettingsScreen({super.key});

  @override
  State<CommunitySettingsScreen> createState() => _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState extends State<CommunitySettingsScreen> {
  bool _isPrivateProfile = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    
                    // Private Profile Section
                    _buildPrivateProfileSection(),
                    
                    const SizedBox(height: 16),
                    
                    // Main Options
                    _buildMainOptions(),
                    
                    const SizedBox(height: 16),
                    
                    // Additional Options  
                    _buildAdditionalOptions(),
                    
                    const SizedBox(height: 16),
                    
                    // Other Privacy Settings
                    _buildOtherPrivacySettings(),
                    
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Privacy',
            style: TextStyle(
              fontFamily: 'SF Pro',
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateProfileSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 20,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Private profile',
              style: TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
          Container(
            width: 58,
            height: 35,
            child: Switch(
              value: _isPrivateProfile,
              onChanged: (value) {
                setState(() {
                  _isPrivateProfile = value;
                });
              },
              activeColor: Colors.white,
              activeTrackColor: Colors.grey[600],
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey[300],
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildOptionItem(
            icon: Icons.alternate_email,
            title: 'Mentions',
            onTap: () => _navigateToMentionSettings(),
          ),
          const SizedBox(height: 16),
          _buildOptionItem(
            icon: Icons.volume_off_outlined,
            title: 'Muted',
            onTap: () => _navigateToMutedAccounts(),
          ),
          const SizedBox(height: 16),
          _buildOptionItem(
            icon: Icons.visibility_off_outlined,
            title: 'Hidden Words',
            onTap: () => _navigateToHiddenWords(),
          ),
          const SizedBox(height: 16),
          _buildOptionItem(
            icon: Icons.language,
            title: 'Profiles you follow',
            onTap: () => _navigateToFollowingSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildOptionItemWithArrow(
            icon: Icons.block_outlined,
            title: 'Blocked',
            onTap: () => _navigateToBlockedAccounts(),
          ),
          const SizedBox(height: 16),
          _buildOptionItemWithArrow(
            icon: Icons.favorite_border,
            title: 'Hide likes',
            onTap: () => _navigateToHideLikesSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherPrivacySettings() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOptionItemWithArrow(
            icon: Icons.settings_outlined,
            title: 'Other privacy settings',
            onTap: () => _navigateToAdvancedSettings(),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 0),
            child: Text(
              'Some settings, like restricting, apply to both\nthreads and Instagram and can be managed\non instagram.',
              style: TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: Color(0xFFB8B8B8),
                height: 1.19,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'SF Pro',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItemWithArrow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'SF Pro',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    bool hasToggle = false,
    bool toggleValue = false,
    ValueChanged<bool>? onToggleChanged,
    VoidCallback? onTap,
    bool showArrow = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasToggle ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Toggle or Arrow
              if (hasToggle)
                Switch(
                  value: toggleValue,
                  onChanged: onToggleChanged,
                  activeColor: Theme.of(context).colorScheme.primary,
                )
              else if (showArrow)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
    );
  }

  // Navigation methods (placeholder implementations)
  void _navigateToMentionSettings() {
    // TODO: Implement mention settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mention settings - Coming soon')),
    );
  }

  void _navigateToMutedAccounts() {
    // TODO: Implement muted accounts screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Muted accounts - Coming soon')),
    );
  }

  void _navigateToHiddenWords() {
    // TODO: Implement hidden words screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hidden words - Coming soon')),
    );
  }

  void _navigateToFollowingSettings() {
    // TODO: Implement following settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Following settings - Coming soon')),
    );
  }

  void _navigateToBlockedAccounts() {
    // TODO: Implement blocked accounts screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Blocked accounts - Coming soon')),
    );
  }

  void _navigateToHideLikesSettings() {
    // TODO: Implement hide likes settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hide likes settings - Coming soon')),
    );
  }

  void _navigateToAdvancedSettings() {
    // Navigate to main app settings
    Navigator.of(context).pushNamed(AppRoutes.dashboardSettings);
  }
}