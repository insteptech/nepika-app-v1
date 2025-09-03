# Face Scan Domain Layer

This directory contains the complete domain layer implementation for the face scanning feature following Clean Architecture principles. The domain layer is the heart of the application and contains all business logic without any external dependencies.

## Architecture Overview

The face scan domain layer consists of four main components:

### 1. Entities (`entities/`)

Pure business objects that represent core concepts:

- **`FaceScanResult`** - Main aggregate root containing complete scan results
- **`SkinAnalysis`** - Detailed skin condition analysis with predictions and scores  
- **`ScanImage`** - Image data including original and AI-processed images
- **`CameraScanSession`** - Camera session state and configuration management

### 2. Use Cases (`usecases/`)

Single-responsibility business operations:

- **`AnalyzeFaceImageUseCase`** - Core AI analysis of captured face images
- **`InitializeCameraSessionUseCase`** - Camera setup and session initialization
- **`CaptureFaceImageUseCase`** - Image capture with quality validation
- **`ValidateFaceAlignmentUseCase`** - Face positioning and alignment validation
- **`ProcessScanResultsUseCase`** - Enhanced result processing with insights

### 3. Repository Interface (`repositories/`)

- **`FaceScanRepository`** - Abstract interface defining data access contracts

### 4. Value Objects (`value_objects/`)

Type-safe, validated data structures:

- **`ScanSessionId`** - Unique session identifier
- **`UserId`** - Type-safe user identifier  
- **`ConfidenceScore`** - Validated confidence values (0.0-1.0)
- **`SkinScore`** - Validated skin health scores (0-100)

## Key Design Principles

### Clean Architecture Compliance

- **No External Dependencies** - Domain layer depends on nothing outside itself
- **Dependency Inversion** - Abstracts data access through repository interfaces
- **Single Responsibility** - Each use case handles one business operation
- **Immutability** - All entities are immutable with `copyWith` methods
- **Type Safety** - Value objects prevent primitive obsession

### Business Logic Focus

The domain layer encapsulates all face scanning business rules:

- Face alignment validation algorithms
- Skin condition analysis processing
- Session state management
- Quality assessment criteria
- User guidance generation

### Error Handling

Consistent error handling using the project's `Either<Failure, Success>` pattern:

- Custom failure types for different error categories
- Descriptive error messages with user guidance
- Retryable vs non-retryable failure classification

## Usage Examples

### Analyzing a Face Image

```dart
import 'package:nepika/domain/face_scan/face_scan_domain.dart';

final analyzeUseCase = AnalyzeFaceImageUseCase(repository);

final params = AnalyzeFaceImageParams(
  imageBytes: imageData,
  userId: 'user123',
  sessionId: 'session456',
  includeAnnotatedImage: true,
);

final result = await analyzeUseCase.call(params);

result.fold(
  (failure) => debugPrint('Analysis failed: ${failure.message}'),
  (scanResult) => debugPrint('Analysis complete: ${scanResult.skinAnalysis}'),
);
```

### Managing Camera Session

```dart
final initializeUseCase = InitializeCameraSessionUseCase(repository);

final params = InitializeCameraSessionParams(
  userId: 'user123',
  sessionConfig: CameraSessionConfig.defaultConfig(),
);

final sessionResult = await initializeUseCase.call(params);
```

### Validating Face Alignment

```dart
final validateUseCase = ValidateFaceAlignmentUseCase();

final params = ValidateFaceAlignmentParams(
  headAngles: FaceAngles(yaw: 5.0, pitch: -2.0, roll: 1.0),
  facePosition: FacePosition.center(),
  tolerance: FaceAlignmentTolerance.standard(),
);

final validationResult = await validateUseCase.call(params);
```

## Entity Relationships

```
FaceScanResult
├── SkinAnalysis
│   ├── SkinAreaAnalysis[]
│   ├── SkinConditionPrediction[]
│   └── SkinAreaBounds
├── ScanImage
│   ├── ImageCaptureMetadata
│   ├── ImageDimensions
│   ├── CameraSettings
│   └── ImageQuality
└── ProcessingMetadata

CameraScanSession
├── CameraSessionConfig
│   ├── FaceAlignmentTolerance
│   └── ImageQualityRequirements
├── FaceAlignmentState
│   ├── FaceAngles
│   └── FacePosition
├── SessionTiming
├── SessionError?
└── SessionMetadata
```

## Integration with Data Layer

The domain layer defines the `FaceScanRepository` interface that must be implemented by the data layer. This ensures:

1. **Testability** - Domain logic can be unit tested with mock repositories
2. **Flexibility** - Data sources can be changed without affecting business logic
3. **Separation of Concerns** - Domain focuses on business rules, data layer handles persistence

## Testing Strategy

The domain layer is designed for comprehensive unit testing:

- **Entities** - Test immutability, equality, and business methods
- **Use Cases** - Test business logic with mock repositories
- **Value Objects** - Test validation and type safety
- **Repository Interface** - Create mock implementations for testing

## Performance Considerations

- **Immutable Structures** - Efficient copying with structural sharing
- **Lazy Evaluation** - Computed properties calculated on demand
- **Memory Efficiency** - Value objects prevent duplicate string instances
- **Validation Caching** - Value objects validate once on creation

## Future Extensions

The domain layer is designed to accommodate future enhancements:

- Additional skin analysis algorithms
- Extended camera session features
- New quality assessment criteria
- Enhanced trend analysis
- Personalized recommendations engine

## Dependencies

The domain layer uses only core Dart libraries and the project's common utilities:

- `dart:typed_data` - For binary image data handling
- `dart:math` - For calculations and random ID generation
- `package:equatable` - For value equality comparison
- Project's `Either` implementation for error handling
- Project's `UseCase` pattern for consistency

This keeps the domain layer pure and framework-agnostic, making it highly testable and reusable across different presentation and data layer implementations.