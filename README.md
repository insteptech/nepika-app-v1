# NEPIKA App

A modern Flutter application designed for beauty and skincare enthusiasts. NEPIKA provides a community platform where users can share posts, interact with others, manage their profiles, access personalized content, and receive skin analysis through face scanning technology.

## Features

- **Face Scan & Skin Analysis**: AI-powered skin analysis using device camera and ML Kit
- **Personalized Recommendations**: Product and routine suggestions based on skin analysis
- **Community Feed**: Share posts, like, comment, and interact with other users
- **User Profiles**: Customizable profiles with avatar, bio, and posts
- **Daily Routines**: Personalized skincare routine management
- **Progress Tracking**: Monitor skin health improvements over time
- **Push Notifications**: Real-time updates via FCM
- **In-App Purchases**: Subscription management via Stripe

## Tech Stack

- **Framework**: Flutter 3.8.1+
- **State Management**: BLoC (flutter_bloc)
- **Networking**: Dio with automatic token refresh
- **Local Storage**: SharedPreferences, SecureStorage
- **Push Notifications**: Firebase Cloud Messaging
- **ML/AI**: Google ML Kit Face Detection
- **Payments**: Stripe

## Architecture

The app follows **Clean Architecture** principles:

```
lib/
├── core/                 # Shared utilities, config, DI
│   ├── api_base.dart    # Base HTTP client with Dio
│   ├── di/              # Dependency injection (ServiceLocator)
│   ├── config/          # Constants, routes, themes
│   └── utils/           # Helpers
├── data/                 # Data sources, models, repositories
├── domain/               # Entities, repository interfaces, use cases
└── features/            # Feature-based modules
    ├── auth/            # Phone + OTP authentication
    ├── community/       # Feed, posts, comments, profiles
    ├── dashboard/       # Main dashboard with widgets
    ├── face_scan/       # Face scanning with ML Kit
    ├── notifications/   # Push & in-app notifications
    ├── products/        # Product catalog
    ├── routine/         # Daily skincare routines
    └── settings/        # App settings
```

## Getting Started

### Prerequisites

- Flutter SDK ^3.8.1
- Dart SDK
- Xcode (for iOS)
- Android Studio (for Android)

### Installation

```bash
# Clone the repository
git clone <repository-url>

# Install dependencies
flutter pub get

# Generate code (injectable, etc.)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Build Commands

```bash
# Android APK
flutter build apk

# iOS IPA
flutter build ipa

# Run tests
flutter test

# Analyze code
flutter analyze
```

## Key Components

### Dashboard Widgets

#### ConditionsListSection
Displays skin condition results in an expandable vertical list format.

**Location**: `lib/features/dashboard/widgets/conditions_list_section.dart`

**Features**:
- Row format: `[Name] [Percentage] [Details >]`
- Color-coded severity (Red ≥70%, Orange 40-69%, Green <40%)
- Expandable with "View More" / "View Less"
- Animated transitions

```dart
ConditionsListSection(
  latestConditionResult: {'acne': 75, 'dry': 45, 'wrinkle': 30},
  onConditionTap: (conditionName) {
    // Navigate to condition details
  },
  initialVisibleCount: 3,
)
```

### API Integration

All API requests use `ApiBase` class with automatic token refresh:

```dart
// Standard JSON request
final response = await ApiBase().request(
  path: '/endpoint',
  method: 'POST',
  body: {'key': 'value'},
);

// Multipart upload
final formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(path),
});
final response = await ApiBase().uploadMultipart(
  path: '/upload',
  formData: formData,
);
```

## Data Privacy & Face Data

### What We Collect
- Single facial image for skin-analysis scan
- No biometric identifiers, face geometry, or facial recognition data

### How We Use It
- Skin type prediction
- Condition classifications
- Personalized recommendations

### Storage & Retention
- Raw uploaded image: Processed in memory only, never stored
- Annotated image: Securely stored in AWS S3 (encrypted)
- Scan results: Stored in AWS RDS (encrypted)
- Retention: Up to 2 years or deleted immediately upon account deletion

### Privacy Policy
Accessible in-app at: Settings > Privacy Policy

## Account Deletion

Full account deletion available at: Settings > Delete Account

Deletion removes:
- User account
- All scan results
- All annotated face images from S3
- All linked database records

## Contributing

1. Follow Clean Architecture patterns
2. Use BLoC for state management
3. Register dependencies in `ServiceLocator.init()`
4. Run `flutter analyze` before commits

## License

Proprietary - All rights reserved
