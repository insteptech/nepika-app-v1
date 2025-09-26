// Routine Feature Entry Point
// This file provides a clean, centralized access point to all routine feature functionality

// ============================================================================
// SCREENS - Main UI screens for routine feature
// ============================================================================
export 'screens/daily_routine_screen.dart';
export 'screens/add_routine_screen.dart';
export 'screens/edit_routine_screen.dart';

// ============================================================================
// BLOC - State management for routine feature
// ============================================================================
export 'bloc/routine_bloc.dart';
export 'bloc/routine_event.dart';
export 'bloc/routine_state.dart';

// ============================================================================
// WIDGETS - Reusable UI components
// ============================================================================
export 'widgets/routine_tile.dart';
export 'widgets/routine_list.dart';
export 'widgets/routine_empty_states.dart';
export 'widgets/daily_routine_card.dart';
export 'widgets/sticky_header_delegate.dart';

// ============================================================================
// COMPONENTS - Complex reusable functional units
// ============================================================================
export 'components/routine_management_component.dart';

// ============================================================================
// PROVIDERS - BLoC providers for dependency injection
// ============================================================================
export 'providers/routine_bloc_provider.dart';

// ============================================================================
// DOMAIN LAYER - Business entities (imported from domain layer)
// ============================================================================
export '../../domain/routine/entities/routine.dart';

// ============================================================================
// CONSTANTS & UTILITIES
// ============================================================================

/// Timing utilities for routine display
class RoutineTimingHelper {
  static const String morning = 'morning';
  static const String night = 'night';
  static const String evening = 'evening';
  
  /// Converts timing string to display text
  static String getDisplayText(String timing) {
    switch (timing.toLowerCase()) {
      case morning:
        return 'Morning Routine';
      case night:
      case evening:
        return 'Night Routine';
      default:
        return 'Routine';
    }
  }
  
  /// Checks if timing is morning routine
  static bool isMorningRoutine(String timing) {
    return timing.toLowerCase() == morning;
  }
  
  /// Checks if timing is night/evening routine
  static bool isNightRoutine(String timing) {
    final lowerTiming = timing.toLowerCase();
    return lowerTiming == night || lowerTiming == evening;
  }
}

/// Route management for routine feature
class RoutineRoutes {
  static const String daily = '/routine/daily';
  static const String add = '/routine/add';
  static const String edit = '/routine/edit';
  
  /// Get all routine feature routes
  static List<String> get allRoutes => [daily, add, edit];
}

/// Feature configuration and metadata
class RoutineFeatureConfig {
  static const String name = 'routine';
  static const String version = '1.0.0';
  static const String description = 'Daily routine management feature';
  
  /// Feature capabilities
  static const List<String> capabilities = [
    'view_daily_routines',
    'add_routine_steps',
    'edit_routine_steps',
    'delete_routine_steps',
    'mark_routine_complete',
    'track_progress',
  ];
  
  /// Minimum required permissions
  static const List<String> requiredPermissions = [
    'read_routines',
    'write_routines',
  ];
}

/// Helper class for routine validation
class RoutineValidator {
  /// Validates routine name
  static bool isValidName(String name) {
    return name.isNotEmpty && name.trim().length >= 2;
  }
  
  /// Validates routine timing
  static bool isValidTiming(String timing) {
    final validTimings = [
      RoutineTimingHelper.morning,
      RoutineTimingHelper.night,
      RoutineTimingHelper.evening,
    ];
    return validTimings.contains(timing.toLowerCase());
  }
  
  /// Validates routine ID
  static bool isValidId(String id) {
    return id.isNotEmpty && id.trim().isNotEmpty;
  }
}

/// Feature constants
class RoutineConstants {
  // Animation durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration quickAnimation = Duration(milliseconds: 150);
  static const Duration longAnimation = Duration(milliseconds: 600);
  
  // UI constants
  static const double routineTileHeight = 85.0;
  static const double routineIconSize = 44.0;
  static const double borderRadius = 20.0;
  static const double paddingHorizontal = 20.0;
  
  // API endpoints (if needed for configuration)
  static const String getUserRoutinesEndpoint = 'get-user-routines';
  static const String getAllRoutinesEndpoint = 'all';
}