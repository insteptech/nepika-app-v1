import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api_base.dart';
import '../../../data/community/repositories/community_repository_impl.dart';
import '../../../data/community/datasources/community_local_datasource.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';
import 'create_community_profile_page.dart';
import 'home.dart';

/// Gateway page that checks if user has a community profile
/// If not, redirects to profile creation, otherwise shows community feed
class CommunityGatewayPage extends StatefulWidget {
  final String token;
  final String userId;

  const CommunityGatewayPage({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  State<CommunityGatewayPage> createState() => _CommunityGatewayPageState();
}

class _CommunityGatewayPageState extends State<CommunityGatewayPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CommunityBloc(
        CommunityRepositoryImpl(ApiBase(), CommunityLocalDataSourceImpl()),
      ),
      child: _CommunityGatewayContent(
        token: widget.token,
        userId: widget.userId,
      ),
    );
  }
}

class _CommunityGatewayContent extends StatefulWidget {
  final String token;
  final String userId;

  const _CommunityGatewayContent({
    required this.token,
    required this.userId,
  });

  @override
  State<_CommunityGatewayContent> createState() => _CommunityGatewayContentState();
}

class _CommunityGatewayContentState extends State<_CommunityGatewayContent> {
  late CommunityBloc _communityBloc;

  @override
  void initState() {
    super.initState();
    _communityBloc = context.read<CommunityBloc>();
    
    // Check if user has a community profile
    Future.microtask(() {
      if (mounted && !_communityBloc.isClosed) {
        _communityBloc.add(
          FetchMyProfile(
            token: widget.token,
            userId: widget.userId,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocConsumer<CommunityBloc, CommunityState>(
        listener: (context, state) {
          if (state is MyProfileError) {
            // Profile doesn't exist or error fetching it
            debugPrint('Community profile error: ${state.message}');
            
            // Navigate to profile creation page
            _navigateToCreateProfile();
          } else if (state is MyProfileLoaded) {
            // Profile exists, navigate to community feed
            debugPrint('Community profile found: ${state.profile.username}');
            
            _navigateToCommunityFeed();
          } else if (state is ProfileCreateSuccess) {
            // Profile just created, navigate to community feed
            debugPrint('Community profile created: ${state.profile.username}');
            
            _navigateToCommunityFeed();
          }
        },
        builder: (context, state) {
          if (state is MyProfileLoading || state is CommunityInitial) {
            return _buildLoadingState();
          }
          
          // For other states, show loading while navigation happens
          return _buildLoadingState();
        },
      ),
    );
  }

  void _navigateToCreateProfile() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => CommunityBloc(
              CommunityRepositoryImpl(ApiBase(), CommunityLocalDataSourceImpl()),
            ),
            child: CreateCommunityProfilePage(
              token: widget.token,
              userId: widget.userId,
            ),
          ),
        ),
      );
    }
  }

  void _navigateToCommunityFeed() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => CommunityBloc(
              CommunityRepositoryImpl(ApiBase(), CommunityLocalDataSourceImpl()),
            ),
            child: CommunityHomePage(
              token: widget.token,
              userId: widget.userId,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildLoadingState() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Icon(
                  Icons.groups,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Community',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Loading content
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Custom loading animation
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.groups,
                      size: 40,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Setting up your community experience...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Please wait while we prepare everything for you',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Bottom space
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

/// Integration wrapper for easy use in navigation
class CommunityPageIntegration extends StatelessWidget {
  final String token;
  final String userId;
  
  const CommunityPageIntegration({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return CommunityGatewayPage(
      token: token,
      userId: userId,
    );
  }
}