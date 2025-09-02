// Routine Feature Exports

// Presentation Layer
export 'presentation/providers/routine_bloc_provider.dart';
export 'presentation/widgets/routine_tile.dart';
export 'presentation/widgets/routine_list.dart';
export 'presentation/widgets/routine_empty_states.dart';

// BLoC
export '../../presentation/routine/bloc/routine_bloc.dart';
export '../../presentation/routine/bloc/routine_event.dart';
export '../../presentation/routine/bloc/routine_state.dart';

// Domain Layer (already exported from main domain)
export '../../domain/routine/entities/routine.dart';

// Common Types
enum RoutinePageType {
  daily,
  selection,
  edit,
}

// Utility Classes
class RoutineHelpers {
  static String getTimingDisplayText(String timing) {
    switch (timing.toLowerCase()) {
      case 'morning':
        return 'Morning Routine';
      case 'night':
      case 'evening':
        return 'Night Routine';
      default:
        return 'Routine';
    }
  }
  
  static bool isMorningRoutine(String timing) {
    return timing.toLowerCase() == 'morning';
  }
}