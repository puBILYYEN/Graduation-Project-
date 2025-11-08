# AI Agent Instructions for Flutter Application

## Project Overview

This is a Flutter application focusing on smart nutrition tracking with features for food diary, camera-based food analysis, and body metrics tracking. The project follows a Feature-First architecture with clean code principles.

## Architecture

### Key Components

```
lib/
├── main.dart                      # Application entry point
├── core/                          # Core functionality
│   ├── app.dart                   # Root application node
│   └── navigation/
│       └── main_frame.dart        # Main navigation frame
├── data/                          # Data layer
│   ├── models/                    # Data models
│   │   ├── container_analysis.dart
│   │   ├── measurement.dart 
│   │   └── nutrition.dart
│   └── services/                  # Services layer
│       ├── reference_database.dart
│       ├── measurement_calculator.dart
│       └── log_manager.dart
└── features/                      # Feature modules
    ├── auth/                      # Authentication feature
    ├── home/                      # Home screen feature
    ├── analysis/                  # Body analysis feature
    ├── food_diary/               # Food diary feature
    └── camera/                   # Camera feature
```

### Key Patterns

1. **Dependency Injection**: Using `Provider` for state and service management. See `main.dart` for DI setup.
2. **Feature-First Architecture**: Each feature is self-contained with its own presentation, domain, and data layers.
3. **Clean Architecture**: Following unidirectional data flow with repositories, use cases, and view models.

## Critical Workflows

### Development Setup

1. Configure Flutter environment:
   ```bash
   flutter pub get
   flutter analyze
   ```

2. Check Android NDK setup in `android/app/build.gradle.kts`
   - Uses latest NDK version for compatibility
   - May need configuration changes for camera features

### Feature Development

1. Add new features in `features/` directory following the existing pattern
2. Use Provider pattern for state management
3. Follow repository pattern for data access
4. Implement domain-driven design with use cases

### Key Integration Points

1. **Firebase Integration**
   - Authentication via `FirebaseAuthDatasource`
   - Storage via `FirestoreService`

2. **Camera Integration**
   - Camera access through `CameraService`
   - Image processing via `ImageProcessingDatasource`

3. **Navigation**
   - Using `GoRouter` for navigation (see `AppRouter.router`)
   - Bottom navigation handled in `MainFrame`

## Common Patterns

### State Management
```dart
// Use ChangeNotifierProvider for view models
ChangeNotifierProvider<FoodDiaryViewModel>(
  create: (context) => FoodDiaryViewModel(
    context.read<GetFoodEntriesUseCase>(),
    context.read<AddFoodEntryUseCase>(),
  ),
)
```

### Error Handling
```dart
try {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Firebase 初始化成功');
} catch (e) {
  print('Firebase 初始化失敗: $e');
}
```

### View Model Pattern
```dart
class CameraViewModel extends ChangeNotifier {
  final GetAvailableCamerasUseCase getAvailableCamerasUseCase;
  final InitializeCameraUseCase initializeCameraUseCase;
  // ... more use cases
}
```

## Important Files

- `lib/main.dart`: Entry point and dependency injection setup
- `lib/core/router/app_router.dart`: Navigation configuration
- `lib/core/services/camera_service.dart`: Camera functionality
- `lib/features/camera/domain/repositories/camera_repository.dart`: Camera operations