# Post Detail Comment Input User Avatar Implementation

## Overview
This implementation enhances the post detail screen's comment input section to display the current user's profile avatar by fetching their actual profile data instead of relying only on cached SharedPreferences data.

## Changes Made

### 1. Updated PostDetailScreen (`lib/features/community/screens/post_detail_screen.dart`)

#### Added Profile BLoC Integration:
```dart
// New imports
import '../bloc/blocs/profile_bloc.dart';
import '../bloc/events/profile_event.dart';
import '../bloc/states/profile_state.dart';

// Added state variable
CommunityProfileEntity? _currentUserProfile;
```

#### Added Profile Loading Method:
```dart
void _loadUserProfile() {
  if (_token != null && _userId != null) {
    context.read<ProfileBloc>().add(
      GetCommunityProfile(token: _token!, userId: _userId!),
    );
  }
}
```

#### Added Profile to Author Conversion Helper:
```dart
/// Get the current user's AuthorEntity, prioritizing profile data over cached user data
AuthorEntity? get _getCurrentUserAuthor {
  if (_currentUserProfile != null) {
    return AuthorEntity(
      id: _currentUserProfile!.userId,
      fullName: _currentUserProfile!.username,
      avatarUrl: _currentUserProfile!.profileImageUrl ?? '',
    );
  }
  return _currentUser;
}
```

#### Updated Initialization Flow:
```dart
// Step 2: Load current user data for profile picture
await _loadCurrentUser();
_loadUserProfile(); // Added profile loading

// Step 3: Load post and comments with guaranteed token availability
await _loadPostWithToken();
await _loadCommentsWithToken();
```

#### Added Profile State Listening:
```dart
MultiBlocListener(
  listeners: [
    BlocListener<PostsBloc, PostsState>(
      listener: (context, state) {
        _handleBlocStateChanges(state);
      },
    ),
    BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is CommunityProfileLoaded && state.profile.isSelf) {
          setState(() {
            _currentUserProfile = state.profile;
          });
        } else if (state is CommunityProfileError) {
          debugPrint('Error loading user profile: ${state.message}');
        }
      },
    ),
  ],
  child: _buildBody(),
)
```

#### Updated Comment Input Avatar Display:
```dart
// Current user's profile picture
Padding(
  padding: const EdgeInsets.all(6.0),
  child: _getCurrentUserAuthor != null 
      ? UserImageIcon(author: _getCurrentUserAuthor!, padding: 0)
      : Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Icon(
            Icons.person,
            size: 24,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
),
```

## Data Flow

1. **Post Detail Screen Load**: Screen initializes with user data from SharedPreferences
2. **Profile Fetch**: Triggers `GetCommunityProfile` event with user's token and ID
3. **Profile Response**: ProfileBloc emits `CommunityProfileLoaded` state
4. **State Update**: BlocListener updates `_currentUserProfile` state variable
5. **Avatar Display**: Comment input uses `_getCurrentUserAuthor` helper method
6. **Priority Logic**: Profile data takes precedence over cached SharedPreferences data

## Key Features

### ✅ Enhanced Avatar Display
- Shows user's actual profile image in comment input
- Fetches fresh profile data automatically when screen loads
- Maintains backward compatibility with existing cached user data

### ✅ Smart Data Prioritization
- Uses profile data when available (most up-to-date)
- Falls back to cached SharedPreferences data if profile loading fails
- Graceful fallback to default icon if no data available

### ✅ Performance Optimizations
- Profile fetched once when screen loads
- Uses existing ProfileBloc infrastructure
- No blocking UI during profile loading

### ✅ Error Handling
- Handles profile loading errors gracefully
- Maintains existing `_loadCurrentUser()` as fallback
- No impact on comment functionality if profile fails

## Comparison with Previous Implementation

### Before:
```dart
// Only used cached SharedPreferences data
child: _currentUser != null 
    ? UserImageIcon(author: _currentUser!, padding: 0)
    : Container(/* default icon */),
```

### After:
```dart
// Uses fresh profile data with fallback to cached data
child: _getCurrentUserAuthor != null 
    ? UserImageIcon(author: _getCurrentUserAuthor!, padding: 0)
    : Container(/* default icon */),
```

## Benefits

### 🎯 **User Experience**
- Users see their current profile image in comment input
- Consistent avatar display across all community screens
- Real-time reflection of profile changes

### 🏗 **Technical Benefits**
- Reuses existing ProfileBloc architecture
- Clean separation of concerns
- Backward compatibility maintained
- Consistent with community home screen implementation

### 🔧 **Maintainability**
- Single helper method for user data access
- Easy to extend for additional profile features
- Follows established app patterns

## Usage

The implementation works automatically when:
1. User navigates to any post detail screen
2. User has valid authentication token
3. ProfileBloc is available in the widget tree

No additional configuration needed - the avatar will automatically display the user's current profile image in the comment input section.

## Integration Notes

This implementation follows the same pattern as the community home screen's create post widget, ensuring consistency across the app. Both screens now:
- Fetch current user profile on load
- Use profile data for avatar display
- Maintain fallback to cached data
- Handle errors gracefully

The comment input now provides a more personalized and up-to-date user experience while maintaining the robust error handling and performance characteristics of the original implementation.