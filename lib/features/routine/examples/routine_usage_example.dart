// Example usage of the refactored Routine Feature
// This file demonstrates how to use the clean, modular routine feature

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import the complete routine feature
import '../main.dart';

/// Example of how to use the Daily Routine Screen
class ExampleDailyRoutineUsage extends StatelessWidget {
  const ExampleDailyRoutineUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoutineBlocProvider(
      child: const DailyRoutineScreen(),
    );
  }
}

/// Example of how to use the Add Routine Screen
class ExampleAddRoutineUsage extends StatelessWidget {
  const ExampleAddRoutineUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoutineBlocProvider(
      child: const AddRoutineScreen(),
    );
  }
}

/// Example of how to use the Edit Routine Screen
class ExampleEditRoutineUsage extends StatelessWidget {
  const ExampleEditRoutineUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoutineBlocProvider(
      child: const EditRoutineScreen(),
    );
  }
}

/// Example of how to use individual components
class ExampleComponentUsage extends StatelessWidget {
  const ExampleComponentUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routine Components Example')),
      body: Column(
        children: [
          // Using the routine management component
          Expanded(
            child: RoutineManagementComponent(
              displayType: RoutineTileType.daily,
              emptyStateTitle: 'No daily routines',
              emptyStateSubtitle: 'Add some routines to get started',
              emptyActionText: 'Add routines',
              onRoutineToggle: (routineId) {
                // Handle routine completion toggle
                context.read<RoutineBloc>().add(
                  UpdateRoutineStepEvent(
                    token: 'your-token',
                    routineId: routineId,
                    isCompleted: true,
                  ),
                );
              },
              onAddNew: () {
                // Navigate to add routine screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddRoutineScreen(),
                  ),
                );
              },
            ),
          ),
          
          // Using routine stats component
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: RoutineStatsComponent(
              completedCount: 3,
              totalCount: 5,
              progressPercentage: 60.0,
            ),
          ),
          
          // Using routine actions component
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: RoutineActionsComponent(
              actions: [
                RoutineAction(
                  label: 'Add Routine',
                  icon: Icons.add,
                  isPrimary: true,
                  onTap: () {
                    // Navigate to add routine
                  },
                ),
                RoutineAction(
                  label: 'Edit Routine',
                  icon: Icons.edit,
                  onTap: () {
                    // Navigate to edit routine
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Example of using routine utilities
class ExampleUtilityUsage {
  void demonstrateUtilities() {
    // Using timing helper
    final morningText = RoutineTimingHelper.getDisplayText('morning');
    print(morningText); // Output: "Morning Routine"
    
    final isMorning = RoutineTimingHelper.isMorningRoutine('morning');
    print(isMorning); // Output: true
    
    // Using validator
    final isValidName = RoutineValidator.isValidName('Daily Exercise');
    print(isValidName); // Output: true
    
    final isValidTiming = RoutineValidator.isValidTiming('morning');
    print(isValidTiming); // Output: true
    
    // Using constants
    const animationDuration = RoutineConstants.animationDuration;
    const tileHeight = RoutineConstants.routineTileHeight;
    
    print('Animation duration: $animationDuration');
    print('Tile height: $tileHeight');
  }
}

/// Example of custom BLoC usage
class ExampleCustomBlocUsage extends StatefulWidget {
  const ExampleCustomBlocUsage({super.key});

  @override
  State<ExampleCustomBlocUsage> createState() => _ExampleCustomBlocUsageState();
}

class _ExampleCustomBlocUsageState extends State<ExampleCustomBlocUsage> {
  late RoutineBloc _routineBloc;

  @override
  void initState() {
    super.initState();
    // Create bloc instance (assuming dependency injection is set up)
    _routineBloc = RoutineBloc(
      getTodaysRoutine: sl(), // Service locator
      updateRoutineStep: sl(),
      deleteRoutineStep: sl(),
      addRoutineStep: sl(),
    );
  }

  @override
  void dispose() {
    _routineBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _routineBloc,
      child: BlocBuilder<RoutineBloc, RoutineState>(
        builder: (context, state) {
          if (state is RoutineLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is RoutineError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.failure.message}'),
                  ElevatedButton(
                    onPressed: () {
                      // Retry loading routines
                      _routineBloc.add(const LoadTodaysRoutineEvent(
                        token: 'your-token',
                        type: 'get-user-routines',
                      ));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is RoutineLoaded) {
            return ListView.builder(
              itemCount: state.routines.length,
              itemBuilder: (context, index) {
                final routine = state.routines[index];
                return RoutineTile(
                  routine: routine,
                  type: RoutineTileType.daily,
                  onToggleComplete: () {
                    _routineBloc.add(UpdateRoutineStepEvent(
                      token: 'your-token',
                      routineId: routine.id,
                      isCompleted: !routine.isCompleted,
                    ));
                  },
                );
              },
            );
          }
          
          return const Center(child: Text('No data'));
        },
      ),
    );
  }
}

// Mock service locator for the example
// In real app, this would be your actual service locator
T sl<T>() {
  throw UnimplementedError('Service locator not implemented in example');
}