import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/widgets/custom_button.dart';
import '../../../domain/community/entities/community_entities.dart';
import '../bloc/blocs/profile_bloc.dart';
import '../bloc/events/profile_event.dart';
import '../bloc/states/profile_state.dart';
import '../components/community_page_header.dart';
import 'face_alignment_camera_screen.dart';

/// Edit Profile Screen for Community Feature
/// Allows users to edit username, bio, and profile image
class EditProfileScreen extends StatefulWidget {
  final String token;
  final String? currentUsername;
  final String? currentBio;
  final String? currentProfileImage;
  
  const EditProfileScreen({
    super.key,
    required this.token,
    this.currentUsername,
    this.currentBio,
    this.currentProfileImage,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  XFile? _selectedImage;
  String? _uploadedImageUrl;
  bool _isLoading = false;
  bool _isImageUploading = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize controllers with current values
    _usernameController.text = widget.currentUsername ?? '';
    _bioController.text = widget.currentBio ?? '';
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    try {
      // Show options for gallery or camera
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;
      
      if (source == ImageSource.camera && mounted) {
        // Open custom camera with face alignment guide
        final imagePath = await _openAlignmentCamera();
        if (imagePath != null) {
          _uploadSelectedImage(imagePath);
        }
      } else {
        // Use gallery picker for existing images
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        
        if (image != null && mounted) {
          _uploadSelectedImage(image.path);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        setState(() {
          _isImageUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<String?> _openAlignmentCamera() async {
    return await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => FaceAlignmentCameraScreen(),
        fullscreenDialog: true,
      ),
    );
  }
  
  void _uploadSelectedImage(String imagePath) {
    setState(() {
      _selectedImage = XFile(imagePath);
      _isImageUploading = true;
    });
    
    // Upload the selected image
    context.read<ProfileBloc>().add(
      UploadProfileImage(
        token: widget.token,
        imagePath: imagePath,
      ),
    );
  }
  
  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  
  Future<void> _saveProfile() async {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final profileData = UpdateProfileEntity(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        profileImageUrl: _uploadedImageUrl ?? widget.currentProfileImage, // Use uploaded URL or keep current
      );

      if (mounted) {
        // Image is already uploaded, just update profile with the URL
        context.read<ProfileBloc>().add(
          UpdateProfile(
            token: widget.token,
            profileData: profileData,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error preparing profile update: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onTertiary,
      body: SafeArea(
        child: BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileUpdateStarted) {
              setState(() {
                _isLoading = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Updating @${state.profileData.username ?? "profile"}...'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            } else if (state is ProfileUpdateSuccess) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Profile updated successfully!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
              Navigator.of(context).pop({
                'username': state.updatedProfile.username,
                'bio': state.updatedProfile.bio,
                'profileImage': state.updatedProfile.profileImageUrl,
              });
            } else if (state is ProfileUpdateError) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  duration: Duration(seconds: 3),
                ),
              );
            } else if (state is ProfileUpdateLoading) {
              setState(() {
                _isLoading = true;
              });
            } else if (state is ImageUploadInProgress) {
              setState(() {
                _isImageUploading = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(state.progress ?? 'Uploading image...'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.blue,
                ),
              );
            } else if (state is ImageUploadSuccess) {
              setState(() {
                _isImageUploading = false;
                _uploadedImageUrl = state.s3Url;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Image uploaded successfully!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            } else if (state is ImageUploadError) {
              setState(() {
                _isImageUploading = false;
                _selectedImage = null; // Clear the selected image on error
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('Image upload failed: ${state.message}')),
                    ],
                  ),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          },
          child: Column(
            children: [
              // Header with back button and Nepika logo
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: const CommunityPageHeader(
                showLogo: true,
              ),
              ),
              
              
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Profile Image Upload Section
                      _buildProfileImageSection(),
                      
                      const SizedBox(height: 40),
                      
                      // Username Field
                      _buildUsernameField(),
                      
                      const SizedBox(height: 20),
                      
                      // Bio Field
                      _buildBioField(),
                      
                      const SizedBox(height: 40),
                      
                      // Save Button
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileImageSection() {
    return Column(
      children: [
        // Profile Image
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image display logic
                  if (_uploadedImageUrl != null)
                    Image.network(
                      _uploadedImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar();
                      },
                    )
                  else if (_selectedImage != null)
                    Image.file(
                      File(_selectedImage!.path),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar();
                      },
                    )
                  else if (widget.currentProfileImage != null)
                    Image.network(
                      widget.currentProfileImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar();
                      },
                    )
                  else
                    _buildDefaultAvatar(),
                  
                  // Upload overlay
                  if (_isImageUploading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Uploading...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Change Photo Text
        GestureDetector(
          onTap: _isImageUploading ? null : _pickImage,
          child: Column(
            children: [
              Text(
                _isImageUploading 
                    ? 'Uploading image...' 
                    : _uploadedImageUrl != null 
                        ? 'Change Profile Photo' 
                        : 'Add Profile Photo',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _isImageUploading 
                      ? Colors.grey 
                      : Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!_isImageUploading)
                const SizedBox(height: 4),
              if (!_isImageUploading)
                Text(
                  'Tap to select image',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      ),
      child: Icon(
        Icons.person,
        size: 60,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
  
  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            hintText: 'Enter your username',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          maxLength: 30,
          buildCounter: (context, {required int currentLength, int? maxLength, required bool isFocused}) {
            return Text(
              '$currentLength/$maxLength',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bio',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bioController,
          decoration: InputDecoration(
            hintText: 'Tell us about yourself...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          maxLines: 4,
          maxLength: 150,
          buildCounter: (context, {required int currentLength, int? maxLength, required bool isFocused}) {
            return Text(
              '$currentLength/$maxLength',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: _isLoading ? 'Saving...' : 'Save Changes',
        onPressed: _isLoading ? null : _saveProfile,
        icon: _isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save, color: Colors.white),
      ),
    );
  }
}