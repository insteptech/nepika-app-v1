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
├── data/                 # Data sources, models, repository implementations
├── domain/               # Entities, repositories (interfaces), use cases
├── presentation/         # UI, BLoCs, pages, widgets
└── features/            # Feature-based modular organization
```

### Key Architectural Patterns
- **BLoC Pattern**: State management using flutter_bloc
- **Clean Architecture**: Domain-driven design with dependency inversion
- **Repository Pattern**: Data abstraction layer
- **Dependency Injection**: Custom service locator in `core/di/injection_container.dart`
- **Feature-based Structure**: Modular organization by feature domains

### Core Components

#### State Management
- Uses `flutter_bloc` for state management
- BLoCs handle business logic and emit states
- UI listens to BLoC states and dispatches events

#### Dependency Injection
- Custom `ServiceLocator` in `core/di/injection_container.dart`
- Lazy singletons for repositories and data sources
- Factory pattern for BLoCs
- Must call `ServiceLocator.init()` in main.dart

#### Navigation
- Named routes defined in `core/config/constants/routes.dart`
- Custom `NavigationService` for programmatic navigation
- Route generation in main.dart's `onGenerateRoute`

#### API Integration
- `ApiBase` class handles HTTP requests with Dio
- Token-based authentication with automatic refresh
- Endpoints defined in `core/network/api_endpoints.dart`
- Secure token storage using `flutter_secure_storage`

## Key Features & Implementation

### Authentication Flow
- Phone number entry → OTP verification → Onboarding
- JWT token management with automatic refresh
- Secure storage for sensitive data

### Community Features
- Feed with posts, likes, comments
- User profiles and search
- Post creation with media upload
- Real-time interaction through REST APIs

### Face Scan Technology
- Camera integration with `google_mlkit_face_detection`
- Onboarding flow with face analysis
- Skin condition detection and recommendations

### Dashboard & Routines
- Personalized skincare routines
- Product recommendations
- Progress tracking
- Settings and profile management

## Data Flow Pattern

**UI → BLoC → Repository → API Client → Backend**

1. User interacts with UI
2. UI dispatches BLoC events
3. BLoC calls repository methods
4. Repository uses ApiBase for HTTP requests
5. Backend processes and returns data
6. BLoC emits new states
7. UI rebuilds based on state changes

## Important Development Notes

### Authentication Requirements
- All API requests require valid JWT tokens
- Token refresh handled automatically by `token_refresh_interceptor.dart`
- Use `SharedPrefsHelper` for user session management

### Asset Management
- Images: `assets/images/`
- Icons: `assets/icons/` (including filled variants)
- Custom font: HelveticaNowDisplay (Regular, Medium, SemiBold, Bold, Black)

### Theme Support
- Light and dark themes via `ThemeNotifier`
- Theme persistence with SharedPreferences
- Custom color palette in `core/widgets/color_palette.dart`

### Testing Setup
- Unit tests with `mockito` and `bloc_test`
- Test files follow `_test.dart` naming convention
- Mock data sources and repositories for isolated testing

### Build Configuration
- Portrait-only orientation (locked in main.dart)
- Flutter version: 3.32.8
- Dart version: 3.8.1
- Uses `flutter_lints` for code quality

## Common Patterns

### Creating New Features
1. Add domain entities and repository interfaces
2. Implement data models and repository
3. Create use cases for business logic
4. Build BLoC for state management
5. Design UI pages and widgets
6. Register dependencies in ServiceLocator
7. Add routes to routes.dart

### API Integration
- Extend existing repository patterns
- Use `ApiBase` for consistent HTTP handling
- Handle loading, success, and error states in BLoCs
- Implement proper error handling at each layer

### Widget Development
- Follow existing component patterns in `core/widgets/`
- Use theme-aware styling
- Implement responsive design principles
- Create reusable components when possible