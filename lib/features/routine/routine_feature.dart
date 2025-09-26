// Routine Feature - Legacy Export File
// This file is maintained for backward compatibility
// New imports should use the main.dart file

// Re-export everything from the main feature file
export 'main.dart';

// Legacy exports for backward compatibility
export 'providers/routine_bloc_provider.dart';

// Import for using helper
import 'main.dart';

// Legacy utility classes for backward compatibility
class RoutineHelpers {
  static String getTimingDisplayText(String timing) {
    return RoutineTimingHelper.getDisplayText(timing);
  }
  
  static bool isMorningRoutine(String timing) {
    return RoutineTimingHelper.isMorningRoutine(timing);
  }
}

// Legacy enum for backward compatibility
enum RoutinePageType {
  daily,
  selection,
  edit,
}