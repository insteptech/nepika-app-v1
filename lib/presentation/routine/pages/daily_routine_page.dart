import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/constants/routes.dart';
import 'package:nepika/core/constants/theme.dart';
import 'package:nepika/core/widgets/back_button.dart';
import '../bloc/routine_bloc.dart';
import '../bloc/routine_event.dart';
import '../bloc/routine_state.dart';
import '../../../domain/routine/usecases/get_todays_routine.dart';
import '../../../domain/routine/usecases/update_routine_step.dart';
import '../../../data/routine/repositories/routine_repository_impl.dart';
import '../../../data/routine/datasources/routine_remote_data_source.dart';
import 'package:nepika/core/api_base.dart';

class TodaysRoutine extends StatelessWidget {
  const TodaysRoutine({super.key});
  @override
  Widget build(BuildContext context) {
    // TODO: Get token from provider or context
    final String token = '';
    return BlocProvider(
      create: (context) => RoutineBloc(
        getTodaysRoutine: GetTodaysRoutine(
          RoutineRepositoryImpl(
            remoteDataSource: RoutineRemoteDataSourceImpl(),
            apiBase: ApiBase(),
          ),
        ),
        updateRoutineStep: UpdateRoutineStep(
          RoutineRepositoryImpl(
            remoteDataSource: RoutineRemoteDataSourceImpl(),
            apiBase: ApiBase(),
          ),
        ),
      )..add(GetTodaysRoutineEvent(token: token, type: 'today')),
      child: BlocBuilder<RoutineBloc, RoutineState>(
        builder: (context, state) {
          bool loading = state is RoutineLoading;
          List<dynamic> routineSteps = [];
          int completedCount = 0;
          
          if (state is RoutineLoaded) {
            // Convert Routine entities to the expected format
            routineSteps = state.routines.map((routine) => {
              'id': routine.id,
              'name': routine.name,
              'timing': routine.timing,
              'isCompleted': routine.isCompleted,
              'description': routine.description,
            }).toList();
            completedCount = routineSteps
                .where((s) => s['isCompleted'] == true)
                .length;
          }
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const CustomBackButton(),
                    const SizedBox(height: 32),
                    Text(
                      "Today's Routine",
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stay consistent. Mark each step as you complete it.',
                      style: Theme.of(context).textTheme.headlineMedium!.secondary(context),
                    ),
                    const SizedBox(height: 45),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Steps',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          'Completed: $completedCount/${routineSteps.length}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              itemCount: routineSteps.length,
                              itemBuilder: (context, index) {
                                final step = routineSteps[index];
                                final isCompleted = step['isCompleted'] == true;
                                final timing = step['timing'] == 'morning'
                                    ? 'Morning Routine'
                                    : 'Night Routine';
                                final colorScheme = Theme.of(context).colorScheme;
                                final color = step['timing'] == 'morning'
                                    ? colorScheme.onSecondary
                                    : colorScheme.primary;
                                return Container(
                                  height: 85,
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.check_circle_outline,
                                          size: 30,
                                          color: isCompleted ? Colors.green : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              step['name'] ?? 'Step',
                                              style: Theme.of(context).textTheme.bodyLarge,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              timing,
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      isCompleted
                                          ? Row(
                                              children: [
                                                Icon(Icons.check, color: Colors.green, size: 24),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Done',
                                                  style: Theme.of(context).textTheme.bodyLarge!.hint(context),
                                                ),
                                              ],
                                            )
                                          : OutlinedButton(
                                              onPressed: () {
                                                // TODO: Mark as done logic
                                              },
                                              style: OutlinedButton.styleFrom(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              ),
                                              child: Text(
                                                'Mark as Done',
                                                style: Theme.of(context).textTheme.bodyLarge!.hint(context),
                                              ),
                                            ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.dashboardEditRoutine,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/edit_icon.png',
                            width: 20,
                            height: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Edit Routine',
                            style: Theme.of(context).textTheme.headlineMedium!.hint(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
