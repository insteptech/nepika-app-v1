import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/widgets/index.dart';
import 'package:nepika/presentation/community/widgets/user_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/community/entities/community_entities.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';

class CreatePostPage extends StatefulWidget {
  final String token;
  final String userId;

  const CreatePostPage({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _contentController = TextEditingController();
  final List<XFile> _selectedMedia = [];
  final ImagePicker _picker = ImagePicker();

  // User profile data
  CommunityProfileEntity? _userProfile;
  bool _isLoadingProfile = true;
  
  // Word count tracking
  int _wordCount = 0;
  static const int _maxWords = 50;

  AuthorEntity get _author => AuthorEntity(
    id: widget.userId,
    fullName: _userProfile?.username ?? 'User',
    avatarUrl: _userProfile?.profileImageUrl ?? '',
  );

  bool get _canPost => _contentController.text.trim().isNotEmpty && _wordCount <= _maxWords;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _contentController.addListener(() {
      _updateWordCount();
      setState(() {}); // Update UI when text changes
    });
  }

  Future<void> _fetchUserProfile() async {
    try {
      context.read<CommunityBloc>().add(
        FetchMyProfile(token: widget.token, userId: widget.userId),
      );
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      // Fallback to SharedPreferences if profile fetch fails
      await _loadUserInfoFromPrefs();
    }
  }

  Future<void> _loadUserInfoFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userProfile = CommunityProfileEntity(
          id: widget.userId,
          userId: widget.userId,
          tenantId: null,
          username: prefs.getString('user_name') ?? 'User',
          bio: '',
          profileImageUrl: prefs.getString('avatar_url'),
          bannerImageUrl: null,
          isPrivate: false,
          isVerified: false,
          followersCount: 0,
          followingCount: 0,
          postsCount: 0,
          settings: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _isLoadingProfile = false;
      });
    }
  }

  void _updateWordCount() {
    final text = _contentController.text.trim();
    final words = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    setState(() {
      _wordCount = words;
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _createPost() {
    if (!_canPost) return;

    final postData = CreatePostEntity(
      content: _contentController.text.trim(),
      parentPostId: null,
    );

    context.read<CommunityBloc>().add(
      CreatePost(token: widget.token, postData: postData),
    );
  }

  void _pickMedia() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: const Text('Photo Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _selectFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam, color: Colors.red),
                  title: const Text('Video Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _selectVideoFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.green),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _takePhoto();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedMedia.addAll(images);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${images.length} image(s) selected from gallery'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedMedia.add(video);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video selected from gallery'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedMedia.add(photo);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo taken with camera'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  Color get _wordCountColor {
    if (_wordCount > _maxWords) return Colors.red;
    if (_wordCount > _maxWords * 0.8) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onTertiary,
      body: SafeArea(
        child: BlocListener<CommunityBloc, CommunityState>(
          listener: (context, state) {
            if (state is MyProfileLoaded) {
              setState(() {
                _userProfile = state.profile;
                _isLoadingProfile = false;
              });
            } else if (state is MyProfileError) {
              _loadUserInfoFromPrefs();
            } else if (state is CreatePostSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Post created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop(true);
            } else if (state is CreatePostError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: GestureDetector(
            onTap: () {
              // Remove focus from input field when tapping outside
              FocusScope.of(context).unfocus();
            },
            child: CustomScrollView(
              slivers: [
              // Initial spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 10),
              ),
              
              // Sticky header with close button and title
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  minHeight: 50,
                  maxHeight: 51,
                  showAnimatedCloseButton: true,
                  title: "New Thread",
                  child: Container(
                    color: Theme.of(context).colorScheme.onTertiary,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, size: 30),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'New Thread',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),


              // Word count indicator
              // SliverToBoxAdapter(
              //   child: Padding(
              //     padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.end,
              //       children: [
              //         Text(
              //           '$_wordCount/$_maxWords words',
              //           style: TextStyle(
              //             color: _wordCountColor,
              //             fontSize: 12,
              //             fontWeight: FontWeight.w500,
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),

              // Main content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      // Profile and text input
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          _isLoadingProfile
                              ? Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                )
                              : UserImageIcon(author: _author),
                          const SizedBox(width: 12),
                          // Username + TextField
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _isLoadingProfile
                                          ? 'Loading...'
                                          : (_userProfile?.username ?? 'User'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium!
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      '$_wordCount/$_maxWords words',
                                      style: TextStyle(
                                        color: _wordCountColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _contentController,
                                  maxLines: null,
                                  minLines: 3,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: "Start a thread...",
                                    hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 0.0,
                                    ),
                                  ),
                                  textCapitalization: TextCapitalization.sentences,
                                  enabled: !_isLoadingProfile,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Selected media display
                      if (_selectedMedia.isNotEmpty) ...[
                        _buildSelectedMedia(),
                        const SizedBox(height: 16),
                      ],

                      // Clip/Attach button
                      _buildThreadReplyUI(),

                      const SizedBox(height: 120), // Extra space for bottom button
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
      // Bottom Post Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onTertiary,
          border: Border(
            top: BorderSide(
              color: Colors.grey[300]!,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: BlocBuilder<CommunityBloc, CommunityState>(
              buildWhen: (previous, current) => 
                  current is CreatePostLoading || 
                  current is CreatePostSuccess || 
                  current is CreatePostError,
              builder: (context, state) {
                final isLoading = state is CreatePostLoading;
                return SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    isLoading: isLoading,
                    text: 'Post',
                    onPressed: _canPost && !isLoading ? _createPost : null,
                    isDisabled: !_canPost,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedMedia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 52), // Align with text content
            Text(
              'Selected Media:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 52), // Align with text content
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedMedia.asMap().entries.map((entry) {
                  final index = entry.key;
                  final media = entry.value;
                  final isVideo = media.path.toLowerCase().contains('.mp4') || 
                            media.path.toLowerCase().contains('.mov') ||
                            media.path.toLowerCase().contains('.avi');
                  
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: isVideo
                              ? Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: Colors.grey[400],
                                  child: const Icon(
                                    Icons.videocam,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                )
                              : Image.file(
                                  File(media.path),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color: Colors.grey[400],
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    );
                                  },
                                ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeMedia(index),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThreadReplyUI() {
    return GestureDetector(
      onTap: _pickMedia,
      child: Row(
        children: [
          const SizedBox(width: 55),
          Transform.rotate(
            angle: pi / 4,
            child: Icon(
              Icons.attach_file, 
              size: 22,
              color: Theme.of(context).colorScheme.primary,  
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Add media',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;
  final bool showAnimatedCloseButton;
  final String? title;
  final Color? backgroundColor;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
    this.showAnimatedCloseButton = false,
    this.title,
    this.backgroundColor,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    if (showAnimatedCloseButton && title != null) {
      final isStuckToTop = shrinkOffset > 0;
      
      return Container(
        color: backgroundColor ?? Theme.of(context).colorScheme.onTertiary,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            // Always visible close button with rotation animation
            AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              turns: isStuckToTop ? 0.25 : 0, // 90 degrees = 0.25 turns
              child: IconButton(
                splashRadius: 15,
                icon: Icon(
                  Icons.close, 
                  size: 24,
                  color: isStuckToTop 
                    ? Theme.of(context).colorScheme.primary
                    : null,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.headlineLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return SizedBox.expand(child: child);
    }
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child ||
        showAnimatedCloseButton != oldDelegate.showAnimatedCloseButton ||
        title != oldDelegate.title ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}