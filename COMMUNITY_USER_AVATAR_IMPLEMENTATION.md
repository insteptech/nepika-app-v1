# Community User Avatar Implementation

## Overview
This implementation adds user avatar display in the community home screen's create post widget by fetching the current user's profile and displaying their profile image.

## Changes Made

### 1. Updated CommunityHomeScreen (`lib/features/community/screens/community_home_screen.dart`)

#### Added Profile BLoC Integration:
```dart
// New imports
import '../bloc/blocs/profile_bloc.dart';
import '../bloc/events/profile_event.dart';
import '../bloc/states/profile_state.dart';

// Added state variable
CommunityProfileEntity? _currentUserProfile;
```

#### Added Profile Loading:
```dart
void _loadUserProfile() {
  if (_token != null && _userId != null) {
    context.read<ProfileBloc>().add(
      GetCommunityProfile(token: _token!, userId: _userId!),
    );
  }
}
```

#### Added Profile State Listening:
```dart
MultiBlocListener(
  listeners: [
    BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is CommunityProfileLoaded && state.profile.isSelf) {
          setState(() {
            _currentUserProfile = state.profile;
          });
        }
      },
    ),
  ],
  // ... rest of the widget
)
```

#### Updated Create Post Section:
```dart
delegate: _CreatePostSection(
  onCreatePostTap: _navigateToCreatePost,
  token: _token!,
  userId: _userId!,
  currentUserProfile: _currentUserProfile, // Pass profile data
),
```

### 2. Updated CreatePostWidget (`lib/features/community/widgets/create_post_widget.dart`)

#### Added Profile Parameter:
```dart
class CreatePostWidget extends StatelessWidget {
  final VoidCallback? onCreatePostTap;
  final AuthorEntity? currentUser;
  final CommunityProfileEntity? currentUserProfile; // New parameter
  
  const CreatePostWidget({
    super.key,
    this.onCreatePostTap,
    this.currentUser,
    this.currentUserProfile, // New parameter
  });
```

#### Added Profile to Author Conversion:
```dart
/// Convert CommunityProfileEntity to AuthorEntity for UserImageIcon
AuthorEntity? get _getAuthor {
  if (currentUserProfile != null) {
    return AuthorEntity(
      id: currentUserProfile!.userId,
      fullName: currentUserProfile!.username,
      avatarUrl: currentUserProfile!.profileImageUrl ?? '',
    );
  }
  return currentUser;
}
```

#### Updated Avatar Display Logic:
```dart
@override
Widget build(BuildContext context) {
  final author = _getAuthor;
  
  return GestureDetector(
    // ... gesture handling
    child: Row(
      children: [
        // User Avatar or Default Logo
        if (author != null)
          UserImageIcon(author: author) // Shows user's actual avatar
        else
          Container(
            // ... default avatar fallback
          ),
        // ... rest of the widget
      ],
    ),
  );
}
```

## Data Flow

1. **App Launch**: CommunityHomeScreen loads user data from SharedPreferences
2. **Profile Fetch**: Triggers `GetCommunityProfile` event with user's token and ID
3. **Profile Response**: ProfileBloc emits `CommunityProfileLoaded` state
4. **State Update**: BlocListener updates `_currentUserProfile` state variable
5. **Widget Rebuild**: CreatePostWidget receives profile data as parameter
6. **Avatar Display**: UserImageIcon shows user's profile image or fallback icon

## Features

### ✅ Profile Image Display
- Shows user's actual profile image in create post widget
- Fetches profile data automatically when community screen loads
- Graceful fallback to default icon if no profile image exists

### ✅ Error Handling
- Handles profile loading errors gracefully
- Shows default icon if profile fetch fails
- No UI blocking during profile loading

### ✅ Performance Optimizations
- Profile only fetched once when screen loads
- Uses existing ProfileBloc infrastructure
- Minimal state management overhead

### ✅ User Experience
- Immediate visual feedback with user's avatar
- Consistent with rest of the app's profile displays
- Maintains responsive UI during loading

## Usage

The implementation automatically works when:
1. User has completed authentication
2. Community home screen is loaded
3. User has a valid profile (profile image is optional)

No additional configuration required - the avatar will display automatically based on the user's current profile data.

## Technical Benefits

- **Reusability**: Uses existing ProfileBloc and UserImageIcon components
- **Maintainability**: Clean separation of concerns with BLoC pattern
- **Scalability**: Can easily extend to show additional profile information
- **Consistency**: Follows app's established patterns and architecture