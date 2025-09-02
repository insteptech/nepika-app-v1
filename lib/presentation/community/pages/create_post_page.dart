import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/theme.dart';
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
  final String communityId;

  const CreatePostPage({
    super.key,
    required this.token,
    required this.userId,
    required this.communityId,
  });

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _contentController = TextEditingController();
  final List<String> _mediaUrls = [];
  final List<XFile> _selectedMedia = []; // Store actual XFile objects
  final List<String> _tags = [];
  final ImagePicker _picker = ImagePicker();

  String? userName;
  String? avatarUrl;


  AuthorEntity get _author => AuthorEntity(
    id: widget.userId,
    fullName: userName ?? 'User',
    avatarUrl: avatarUrl!,
  );

  bool get _canPost => _contentController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _contentController.addListener(() {
      setState(() {}); // Update UI when text changes
    });
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'User';
      avatarUrl = prefs.getString('avatar_url');
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
      userId: widget.userId,
      communityId: widget.communityId,
      content: _contentController.text.trim(),
      mediaUrls: _mediaUrls.isNotEmpty ? _mediaUrls : null,
      tags: _tags.isNotEmpty ? _tags : null,
    );

    context.read<CommunityBloc>().add(
      CreatePost(token: widget.token, postData: postData),
    );
  }

  void _pickMedia() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _selectFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Video Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _selectVideoFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePhoto();
                },
              ),
            ],
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${images.length} image(s) selected from gallery'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selectVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedMedia.add(video);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video selected from gallery'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedMedia.add(photo);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo taken with camera'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onTertiary,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with close icon, title, and Post button
            Padding(
              padding: const EdgeInsets.all(16),
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
                  // Post button - only visible when text length > 0
                  if (_canPost)
                    BlocConsumer<CommunityBloc, CommunityState>(
                      listener: (context, state) {
                        if (state is CreatePostSuccess) {
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
                      builder: (context, state) {
                        final isLoading = state is CreatePostLoading;
                        return isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : TextButton(
                                onPressed: _createPost,
                                style: TextButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  'Post',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              );
                      },
                    ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile and text input
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        UserImageIcon(author: _author),
                        // Username + TextField
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName ?? 'User',
                                style: Theme.of(context).textTheme.headlineMedium!
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _contentController,
                                maxLines: null,
                                style: Theme.of(context).textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  hintText: "Start a thread...",
                                  hintStyle: Theme.of(context).textTheme.bodyLarge,
                                  border: InputBorder.none,
                                ),
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

                    const SizedBox(height: 100), // Extra space at bottom
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Image.asset(
        'assets/images/nepika_logo_image.png',
        height: 10,
        color: Theme.of(context).colorScheme.onSecondary,
        fit: BoxFit.scaleDown,
      ),
    );
  }

  Widget _buildSelectedMedia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected Media:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedMedia.asMap().entries.map((entry) {
            final index = entry.key;
            final media = entry.value;
            final isVideo = media.path.toLowerCase().contains('.mp4') || 
                          media.path.toLowerCase().contains('.mov') ||
                          media.path.toLowerCase().contains('.avi');
            
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: isVideo
                        ? Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.grey[400],
                            child: const Icon(
                              Icons.videocam,
                              color: Colors.white,
                              size: 32,
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
                                  size: 32,
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
                          size: 14,
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
              size: 25,
              color: Theme.of(context).textTheme.bodyLarge!.secondary(context).color,  
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Add media',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge!.secondary(context).color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
