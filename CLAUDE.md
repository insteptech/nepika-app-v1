# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NEPIKA is a modern Flutter application designed for beauty and skincare enthusiasts. It provides a community platform where users can share posts, interact with others, manage their profiles, access personalized content, and receive skin analysis through face scanning technology. The app integrates with a Node.js backend via RESTful APIs.

## Development Commands

### Core Flutter Commands
- `flutter run` - Run the app on connected device/emulator
- `flutter build apk` - Build APK for Android
- `flutter build ipa` - Build IPA for iOS
- `flutter clean` - Clean build artifacts
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies
- `flutter analyze` - Run static analysis (uses flutter_lints)
- `flutter test` - Run unit tests
- `flutter doctor` - Check Flutter installation and dependencies

### Development Workflow
- `flutter pub get` after any pubspec.yaml changes
- `flutter clean && flutter pub get` when facing dependency issues
- `flutter analyze` to check for linting issues before commits

## Architecture

The app follows **Clean Architecture** principles with clear separation of concerns:

### Layer Structure
```
lib/
├── core/                 # Shared utilities, config, DI
│   ├── api_base.dart    # Base HTTP client with Dio (handles token refresh)
│   ├── di/              # Custom dependency injection (ServiceLocator)
│   ├── config/          # App constants, routes, themes
│   ├── network/         # Network utilities
│   └── utils/           # Shared helpers (SecureStorage, SharedPrefsHelper)
├── data/                 # Data sources, models, repository implementations
├── domain/               # Entities, repositories (interfaces), use cases
└── features/            # Feature-based modular organization
    ├── auth/            # Phone + OTP authentication
    ├── community/       # Feed, posts, comments, user profiles, search
    ├── dashboard/       # Main dashboard with bottom navigation
    ├── face_scan/       # Face scanning with ML Kit
    ├── notifications/   # In-app notifications with SSE
    ├── onboarding/      # User onboarding flow
    ├── products/        # Product catalog and details
    ├── routine/         # Daily skincare routines
    ├── settings/        # App settings and preferences
    ├── splash/          # Splash screen
    └── welcome/         # Welcome screen
```

### Key Architectural Patterns
- **BLoC Pattern**: State management using flutter_bloc
- **Clean Architecture**: Domain-driven design with dependency inversion
- **Repository Pattern**: Data abstraction layer
- **Dependency Injection**: Custom service locator in `core/di/injection_container.dart`
- **Feature-based Structure**: Each feature is self-contained with its own screens, BLoCs, and logic

### Core Components

#### State Management
- Uses `flutter_bloc` for state management
- BLoCs handle business logic and emit states
- UI listens to BLoC states and dispatches events
- Some features use `provider` for theme management

#### Dependency Injection
- Custom `ServiceLocator` in `core/di/injection_container.dart`
- Lazy singletons for repositories and data sources
- Factory pattern for BLoCs
- **CRITICAL**: Must call `ServiceLocator.init()` in main.dart before app starts
- Register new dependencies following the pattern: data source → repository → use cases → BLoC

#### Navigation
- Named routes defined in `core/config/constants/routes.dart`
- Route classes: `AppRoutes`, `DashboardRoutes`, `CommunityRoutes`, `SettingsRoutes`, `OnboardingRoutes`
- Custom `NavigationService` for programmatic navigation
- Route generation in `main.dart`'s `onGenerateRoute`
- Bottom navigation in dashboard feature

#### API Integration
- `ApiBase` class in `core/api_base.dart` handles all HTTP requests with Dio
- Base URL configured in `core/config/env.dart`
- **Automatic token refresh**: Built-in interceptor detects 401 responses and refreshes tokens
- Token storage: Uses `SharedPreferences` for access/refresh tokens
- Request queuing: Queues requests during token refresh to prevent race conditions
- All API methods return Dio `Response` objects

## Key Features & Implementation

### Authentication Flow
- Phone number entry → OTP verification → Onboarding → Face scan → Dashboard
- JWT token management with automatic refresh via ApiBase interceptor
- Tokens stored in SharedPreferences using `AppConstants.accessTokenKey` and `AppConstants.refreshTokenKey`
- Auth BLoC handles state: `SendOtp`, `VerifyOtp`, `ResendOtp`

### Community Features
- Feed with posts, likes, comments
- User profiles and search functionality
- Post creation with media upload (multipart/form-data)
- Post detail screen with full comment threads
- HybridPostsBloc and PostsBloc for different community views
- UserSearchBloc for searching users

### Face Scan Technology
- Camera integration with `camera` package
- ML Kit face detection with `google_mlkit_face_detection`
- Onboarding flow with face analysis
- Skin condition detection and recommendations
- Results stored and displayed in dashboard

### Dashboard & Routines
- Bottom navigation with 4 tabs: Home, Explore, Scan, Profile
- Personalized skincare routines with RoutineBloc
- Product recommendations
- Scan result details
- Settings and profile management

### Notifications
- In-app notification system with NotificationBloc
- Real-time updates using Server-Sent Events (SSE) via `http` package
- Notification debug screen for testing

## Data Flow Pattern

**UI → BLoC → Use Case → Repository → ApiBase → Backend**

1. User interacts with UI (e.g., taps button, scrolls feed)
2. UI dispatches BLoC event (e.g., `FetchCommunityPosts`)
3. BLoC calls appropriate use case
4. Use case invokes repository method
5. Repository implementation uses `ApiBase` for HTTP requests
6. ApiBase automatically adds auth headers and handles token refresh
7. Backend processes and returns data
8. Repository deserializes response
9. BLoC emits new state (loading → success/error)
10. UI rebuilds based on state changes

## Important Development Notes

### Authentication & Token Management
- All API requests automatically include Bearer token via ApiBase interceptor
- Token refresh is handled transparently by ApiBase on 401 responses
- Access token key: `AppConstants.accessTokenKey`
- Refresh token key: `AppConstants.refreshTokenKey`
- Use `SharedPrefsHelper` for user session management
- Force logout occurs only when refresh token itself is invalid (401 during refresh)

### API Request Patterns
- Use `ApiBase().request()` for standard JSON requests
- Use `ApiBase().uploadMultipart()` for file uploads
- Query params passed via `query` parameter
- Headers passed via `headers` parameter
- Body passed via `body` parameter for POST/PUT
- All requests return Dio `Response` objects

### Asset Management
- Images: `assets/images/`
- App assets: `assets/app/`
- Icons: `assets/icons/` and `assets/icons/filled/`
- Custom font: HelveticaNowDisplay (weights: 400, 500, 600, 700, 900)

### Theme Support
- Light and dark themes via `ThemeNotifier` (provider-based)
- Theme persistence with SharedPreferences
- Themes defined in `core/config/constants/theme.dart`
- Custom color palette in `core/widgets/color_palette.dart`

### Testing Setup
- Unit tests with `mockito` and `bloc_test`
- Test files follow `_test.dart` naming convention
- Mock data sources and repositories for isolated testing

### Build Configuration
- Portrait-only orientation (locked in main.dart)
- Flutter SDK: ^3.8.1
- Uses `flutter_lints` for code quality
- `injectable` for dependency injection annotations (with `build_runner`)

## Common Patterns

### Creating New Features
1. Create feature folder structure under `lib/features/your_feature/`
2. Add domain entities and repository interfaces in `lib/domain/your_feature/`
3. Implement data models and repository in `lib/data/your_feature/`
4. Create use cases for business logic in `lib/domain/your_feature/usecases/`
5. Build BLoC/Cubit with events and states in `lib/features/your_feature/bloc/`
6. Design UI pages and widgets in `lib/features/your_feature/screens/` or `pages/`
7. Register dependencies in `ServiceLocator.init()` following pattern:
   - Data source (singleton)
   - Repository (singleton)
   - Use cases (singleton)
   - BLoC (factory)
8. Add routes to `core/config/constants/routes.dart`
9. Add route generation case in `main.dart`'s `onGenerateRoute`

### API Integration Example
```dart
// In repository implementation:
final response = await ApiBase().request(
  path: '/community/post',
  method: 'POST',
  body: {'text': 'Hello world'},
);

// For multipart uploads:
final formData = FormData.fromMap({
  'text': 'Hello',
  'image': await MultipartFile.fromFile(imagePath),
});
final response = await ApiBase().uploadMultipart(
  path: '/community/post',
  formData: formData,
);
```

### BLoC State Management Pattern
- Events: Define user actions (e.g., `FetchPosts`, `CreatePost`)
- States: Define UI states (e.g., `PostsLoading`, `PostsLoaded`, `PostsError`)
- Handle loading, success, and error states in BLoCs
- Emit states sequentially: loading → success/error
- Use Equatable for state comparison

### Widget Development
- Follow existing component patterns in `core/widgets/`
- Use theme-aware styling via `Theme.of(context)`
- Access theme colors through `Theme.of(context).colorScheme` or custom ColorPalette
- Implement responsive design principles
- Create reusable components when patterns repeat

## Firebase & Notifications

### Firebase Integration
- Firebase Core and Messaging configured for push notifications
- `firebase.json` configuration file for deployment settings
- FCM tokens managed via `UnifiedFcmService.instance` (singleton pattern)
- Background message handler in `core/services/fcm_background_handler.dart`
- Local notification service integrated with `flutter_local_notifications`

### Push Notification Architecture
- **UnifiedFcmService**: Main FCM service handling token management and message processing
- **LocalNotificationService**: Handles local notification display and scheduling
- **FcmTokenService**: Legacy service (use UnifiedFcmService instead)
- **ReminderBloc**: Manages scheduled reminders with local notifications
- Background message handling configured in `main.dart`

### Notification Flow
1. FCM token obtained and saved to backend via `SaveFcmTokenUseCase`
2. Backend sends push notifications to FCM
3. `firebaseMessagingBackgroundHandler` processes background messages
4. `LocalNotificationService` displays notifications to user
5. Foreground message handling via `UnifiedFcmService`

### Server-Sent Events (SSE)
- Real-time notification system documented in `FLUTTER_SSE_INTEGRATION_GUIDE.md`
- NotificationBloc handles SSE connections for live updates
- Supports notification types: like, reply, follow, mention
- Auto-deletion when actions are reversed (unlike, unfollow, etc.)

### Reminders System
- Daily skincare routine reminders with `ReminderBloc`
- Local notification scheduling via `LocalNotificationService`
- Time zone support with `timezone` package
- User-configurable reminder settings in dashboard

## Advanced Architecture

### Hybrid Community State Management
- Three-layer architecture documented in `HYBRID_COMMUNITY_ARCHITECTURE.md`:
  - **L1 RAM State Manager**: In-memory state for instant updates
  - **L2 Database Layer**: Persistent local storage with SharedPreferences
  - **L3 Server Sync**: Delta sync and real-time events
- `HybridPostsBloc` provides optimistic updates and offline support
- Centralized state management via `CommunityStateManager`

### Additional Implementation Notes

#### Firebase Setup Requirements
- Ensure `GoogleService-Info.plist` (iOS) and `google-services.json` (Android) are properly configured
- Initialize Firebase in `main.dart` before app starts
- FCM token management is handled automatically by `UnifiedFcmService`

#### Notification Best Practices
- Use `LocalNotificationService.instance` for local notifications
- Handle notification permissions properly
- Process background messages in `fcm_background_handler.dart`
- Test notifications on both iOS and Android devices

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.
