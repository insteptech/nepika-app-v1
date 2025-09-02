NEPIKA is a modern Flutter application designed for beauty and skincare enthusiasts. It provides a vibrant community platform where users can share posts, interact with others, manage their profiles, and access personalized content. The app is built with clean architecture, BLoC state management, and integrates with a Node.js backend via RESTful APIs for seamless, real-time interaction.

## Key Features

- **Community Feed:** Users can view, like, comment, and create posts with text, images, and videos. Posts are fetched from the backend and displayed in a paginated, scrollable feed.
- **User Profiles:** Each user has a profile with avatar, bio, and their posts. Profiles can be updated and viewed by others.
- **Search:** Users can search for other users in the community using a responsive search page.
- **Post Detail Screen:** Users can tap on any post to view detailed information including all comments and engagement metrics. Includes comment input functionality.
- **Face Scan (Onboarding):** The app includes a face scan feature using the device camera and ML Kit for onboarding and personalized recommendations.
- **Authentication:** Secure login and onboarding flow with token-based authentication.

## Project Architecture

- **Presentation Layer:** UI pages and widgets, BLoC for state management, event-driven updates.
- **Domain Layer:** Entities and repository interfaces defining business logic and data contracts.
- **Data Layer:** Repository implementations, API clients, and data models for network and local storage.
- **Core:** API client, constants, error handling, and configuration.

## API Flow: UI to Backend

### 1. **UI Layer (Presentation)**
  - User interacts with UI (e.g., scrolls feed, creates post, searches users).
  - UI dispatches BLoC events (e.g., `FetchCommunityPosts`, `CreatePost`, `SearchUsers`).

### 2. **BLoC Layer**
  - BLoC receives events and triggers repository methods.
  - Emits loading, success, or error states to update the UI reactively.

### 3. **Repository Layer (Domain/Data)**
  - Repository interface (domain) defines contract (e.g., `fetchCommunityPosts`, `createPost`).
  - Implementation (data) uses `ApiBase` or `ApiClient` to make HTTP requests to backend endpoints.
  - Handles serialization/deserialization of data models and error handling.

### 4. **API Client (Core)**
  - Uses Dio for HTTP requests.
  - Adds authentication headers (Bearer token) and handles timeouts, errors, and logging.
  - Endpoints are defined in `api_endpoints.dart` for consistency.

### 5. **Backend (Node.js)**
  - Receives RESTful requests (e.g., `/user/community`, `/community/post`, `/user/search`).
  - Authenticates requests, processes data, and returns JSON responses.
  - Handles business logic, database operations, and media uploads.

## Example API Flow: Creating a Community Post

1. **User Action:** User writes a post, attaches images/videos, and taps "Post".
2. **UI Event:** `CreatePost` event is dispatched to the BLoC.
3. **BLoC:** Calls `CommunityRepository.createPost(token, postData)`.
4. **Repository:** Serializes post data, attaches media, and sends a POST request to `/community/post` with authentication token.
5. **API Client:** Handles the HTTP request, adds headers, and manages errors.
6. **Backend:** Validates, saves post, uploads media, and returns success or error response.
7. **BLoC:** Emits success or error state; UI updates accordingly (shows new post or error message).

## Example API Flow: Fetching Community Feed

1. **UI loads feed** (e.g., on app start or pull-to-refresh).
2. **BLoC dispatches** `FetchCommunityPosts(token, page, limit)`.
3. **Repository** calls GET `/user/community` with pagination params and token.
4. **API Client** sends request, handles response.
5. **Backend** returns paginated list of posts.
6. **BLoC** emits loaded state; UI displays posts.

## Example API Flow: Viewing Post Details

1. **User Action:** User taps on a post in the community feed.
2. **Navigation:** App navigates to `PostDetailPage` with the post ID.
3. **UI Event:** `FetchSinglePost` event is dispatched to the BLoC.
4. **Repository:** Calls GET `/community/post/{postId}` with authentication token.
5. **API Client:** Sends request and handles response.
6. **Backend:** Returns detailed post data including comments.
7. **BLoC:** Emits loaded state; UI displays post details with comments.

## Technologies Used

- **Flutter** (UI, state management, navigation)
- **Dio** (networking)
- **BLoC** (state management)
- **SharedPreferences** (local storage)
- **image_picker, camera, google_mlkit_face_detection** (media & ML)
- **Node.js** (backend, not included in this repo)

## Folder Structure (Key Parts)

- `lib/presentation/community/pages/` — UI pages (feed, create post, search, post detail, etc.)
- `lib/presentation/community/bloc/` — BLoC, events, and states
- `lib/domain/community/` — Entities and repository interfaces
- `lib/data/community/` — Repository implementations
- `lib/core/` — API client, endpoints, config

## Notes

- All API requests require a valid authentication token.
- Media uploads are handled via multipart/form-data.
- Error handling is robust at every layer (UI, BLoC, repository, API client).
- The app is modular and scalable for future features (e.g., notifications, chat, analytics).

---
**This file is for Copilot and developers to understand the NEPIKA app context, architecture, and API flow.**

# Completed Features:

✅ **Post Detail Screen** - A comprehensive post detail view that shows:
    - Complete post information with user details
    - All comments with user avatars and verification badges
    - Like and comment counts
    - Interactive comment input
    - Pixel-perfect design matching the provided Figma
    - Uses API endpoint `GET /community/post/{postId}`
    - Full BLoC architecture integration
    - Responsive design with proper error handling

Location: `lib/presentation/community/pages/post_detail_page.dart`
Integration: `lib/presentation/community/pages/post_detail_page_integration.dart`

Usage:
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => PostDetailPageIntegration(
      token: userToken,
      postId: postId,
      userId: currentUserId,
    ),
  ),
);
```

---
**This file is for Copilot and developers to understand the NEPIKA app context, architecture, and API flow.**
