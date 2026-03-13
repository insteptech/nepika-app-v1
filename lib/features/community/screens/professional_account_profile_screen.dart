import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/domain/community/entities/community_entities.dart';
import 'package:nepika/features/community/bloc/blocs/profile_bloc.dart';
import 'package:nepika/features/community/bloc/events/profile_event.dart';
import 'package:nepika/features/community/bloc/states/profile_state.dart';
import 'package:nepika/features/community/widgets/user_avatar.dart';
import 'package:nepika/features/settings/screens/onboarding_data_screen.dart';

class ProfessionalAccountProfileScreen extends StatefulWidget {
  const ProfessionalAccountProfileScreen({super.key});

  @override
  State<ProfessionalAccountProfileScreen> createState() =>
      _ProfessionalAccountProfileScreenState();
}

class _ProfessionalAccountProfileScreenState
    extends State<ProfessionalAccountProfileScreen> {
  String? _currentUserId;
  String? _token;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.accessTokenKey);
    final userDataString = prefs.getString(AppConstants.userDataKey);

    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      _currentUserId = userData['id'];
    }

    if (_token != null && _currentUserId != null && mounted) {
      context.read<ProfileBloc>().add(
            GetCommunityProfile(token: _token!, userId: _currentUserId!),
          );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final userDataString = prefs.getString(AppConstants.userDataKey);

              bool isProfessional = true;
              if (userDataString != null) {
                try {
                  final userData = jsonDecode(userDataString);
                  isProfessional = userData['is_skincare_professional'] == true;
                } catch (_) {
                  // Keep fallback
                }
              }

              if (!context.mounted) return;

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => OnboardingDataScreen(
                        isSkincareProfessional: isProfessional,
                      ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileInitial || state is CommunityProfileLoading || _currentUserId == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CommunityProfileError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is CommunityProfileLoaded) {
            final profile = state.profile;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderCard(context, profile),
                  const SizedBox(height: 16),
                  _buildAboutCard(context, profile),
                  const SizedBox(height: 16),
                  _buildSpecializationsCard(context, profile),
                  const SizedBox(height: 16),
                  _buildCredentialsCard(context, profile),
                  const SizedBox(height: 40),
                ],
              ),
            );
          }

          return const Center(child: Text('No profile data available'));
        },
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildHeaderCard(BuildContext context, CommunityProfileEntity profile) {
    return _buildCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                author: AuthorEntity(
                  id: profile.userId,
                  fullName: profile.fullName ?? profile.username,
                  avatarUrl: profile.profileImageUrl ?? '',
                ),
                size: 72,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.fullName?.isNotEmpty == true
                                    ? profile.fullName!
                                    : profile.username,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              if (profile.fullName?.isNotEmpty == true && profile.username != profile.fullName)
                                Text(
                                  '@${profile.username}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.qualification ?? 'Skincare Professional',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (profile.country != null)
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            profile.cityTown != null 
                              ? '${profile.cityTown}, ${profile.country!}'
                              : profile.country!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn(_formatCount(profile.followersCount), 'Followers'),
              _buildStatColumn(_formatCount(profile.postsCount), 'Posts'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutCard(BuildContext context, CommunityProfileEntity profile) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.bio != null && profile.bio!.isNotEmpty
                ? profile.bio!
                : 'No bio provided.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializationsCard(BuildContext context, CommunityProfileEntity profile) {
    final List<String> specializations = profile.skinConcernsTreated ?? [];
    
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specializations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (specializations.isEmpty)
            Text('No specializations added', style: TextStyle(color: Colors.grey.shade500)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: specializations.map((spec) => _buildSpecializationChip(spec)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializationChip(String label) {
    // Format "oily_skin" to "Oily Skin"
    final formattedLabel = label.split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6B66FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        formattedLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCredentialsCard(BuildContext context, CommunityProfileEntity profile) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Credentials & Education',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (profile.qualification != null && profile.qualification!.isNotEmpty) ...[
            _buildCredentialItem(
              profile.qualification!,
              'Professional Qualification',
            ),
            const SizedBox(height: 16),
          ],
          if (profile.professionalRole != null && profile.professionalRole!.isNotEmpty) ...[
            _buildCredentialItem(
              profile.professionalRole!,
              'Professional Role',
            ),
            const SizedBox(height: 16),
          ],
          if (profile.yearsOfExperience != null && profile.yearsOfExperience!.isNotEmpty) ...[
            _buildCredentialItem(
              profile.yearsOfExperience!,
              'Years of Experience',
            ),
            const SizedBox(height: 16),
          ],
          if (profile.salonBusinessName != null && profile.salonBusinessName!.isNotEmpty) ...[
            _buildCredentialItem(
              profile.salonBusinessName!,
              profile.businessType != null && profile.businessType!.isNotEmpty 
                ? profile.businessType!
                : 'Clinic / Business Name',
            ),
            const SizedBox(height: 16),
          ],
          if ((profile.qualification == null || profile.qualification!.isEmpty) &&
              (profile.salonBusinessName == null || profile.salonBusinessName!.isEmpty))
            _buildCredentialItem(
              'Certified Skincare Professional',
              'Verified by Nepika',
            ),
        ],
      ),
    );
  }

  Widget _buildCredentialItem(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFF6B66FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.workspace_premium,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
