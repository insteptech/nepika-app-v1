import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/back_button.dart';
import '../../../core/api_base.dart';
import '../../../data/community/repositories/community_repository_impl.dart';
import '../../../data/community/datasources/community_local_datasource.dart';
import '../../../domain/community/entities/community_entities.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';
import 'home.dart';

class CreateCommunityProfilePage extends StatefulWidget {
  final String token;
  final String? userId;

  const CreateCommunityProfilePage({
    super.key,
    required this.token,
    this.userId,
  });

  @override
  State<CreateCommunityProfilePage> createState() => _CreateCommunityProfilePageState();
}

class _CreateCommunityProfilePageState extends State<CreateCommunityProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isPrivate = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  bool get _canCreate => _usernameController.text.trim().isNotEmpty;

  void _createProfile() {
    if (!_formKey.currentState!.validate()) return;

    final profileData = CreateProfileEntity(
      username: _usernameController.text.trim(),
      bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
      isPrivate: _isPrivate,
    );

    try {
      final bloc = context.read<CommunityBloc>();
      if (!bloc.isClosed) {
        bloc.add(
          CreateProfile(
            token: widget.token,
            profileData: profileData,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error accessing CommunityBloc: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to create profile. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: BlocListener<CommunityBloc, CommunityState>(
          listener: (context, state) {
            if (state is ProfileCreateSuccess) {
              // Profile created successfully, navigate to community feed
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome to the community, ${state.profile.username}!'),
                  backgroundColor: Colors.green,
                ),
              );
              
              // Navigate to community feed
              Future.microtask(() {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => CommunityBloc(
                          CommunityRepositoryImpl(ApiBase(), CommunityLocalDataSourceImpl()),
                        ),
                        child: CommunityHomePage(
                          token: widget.token,
                          userId: widget.userId ?? 'user_001',
                        ),
                      ),
                    ),
                  );
                }
              });
            } else if (state is ProfileCreateError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: Row(
                  children: [
                    CustomBackButton(
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Create Community Profile',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: BlocBuilder<CommunityBloc, CommunityState>(
                  builder: (context, state) {
                    if (state is ProfileCreateLoading) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Creating your community profile...'),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            
                            // Welcome message
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '👋 Welcome to the Community!',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Let\'s create your community profile to get started. You can share your thoughts, connect with others, and be part of our growing community.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),
                            
                            // Username field
                            Text(
                              'Username *',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                hintText: 'Choose a unique username',
                                prefixText: '@',
                                prefixStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Username is required';
                                }
                                if (value.trim().length < 3) {
                                  return 'Username must be at least 3 characters';
                                }
                                if (value.trim().length > 30) {
                                  return 'Username must be less than 30 characters';
                                }
                                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                                  return 'Username can only contain letters, numbers, and underscores';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),

                            const SizedBox(height: 24),
                            
                            // Bio field
                            Text(
                              'Bio (Optional)',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _bioController,
                              maxLines: 4,
                              maxLength: 160,
                              decoration: InputDecoration(
                                hintText: 'Tell us a bit about yourself...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              ),
                              validator: (value) {
                                if (value != null && value.trim().length > 160) {
                                  return 'Bio must be less than 160 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),
                            
                            // Privacy setting
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isPrivate ? Icons.lock : Icons.public,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Private Account',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          _isPrivate 
                                            ? 'Only approved followers can see your posts'
                                            : 'Anyone can see your posts and follow you',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _isPrivate,
                                    onChanged: (value) {
                                      setState(() {
                                        _isPrivate = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Create button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: BlocBuilder<CommunityBloc, CommunityState>(
                    builder: (context, state) {
                      return CustomButton(
                        text: 'Create Profile',
                        onPressed: _canCreate ? _createProfile : null,
                        isDisabled: !_canCreate,
                        isLoading: state is ProfileCreateLoading,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}