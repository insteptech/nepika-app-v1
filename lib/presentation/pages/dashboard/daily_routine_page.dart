import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/constants/routes.dart';
import 'package:nepika/core/constants/theme.dart';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/presentation/bloc/dashboard/dashboard_bloc.dart';
import 'package:nepika/presentation/bloc/dashboard/dashboard_event.dart';
import 'package:nepika/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/data/dashboard/repositories/dashboard_repository.dart';

class TodaysRoutine extends StatelessWidget {
  const TodaysRoutine({super.key});
  Widget build(BuildContext context) {
    // TODO: Get token from provider or context
    final String token = '';
    return BlocProvider(
      create: (context) => DashboardBloc(
        DashboardRepository(
          ApiBase(),
        ),
      )..add(FetchTodaysRoutine(token, 'today')),
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          List<dynamic> routineSteps = [];
          int completedCount = 0;
          bool loading = state is TodaysRoutineLoading;
          if (state is TodaysRoutineLoaded) {
            routineSteps = state.routineSteps;
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
                      style: Theme.of(context).textTheme.displaySmall
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stay consistent. Mark each step as you complete it.',
                      style: Theme.of(context).textTheme.headlineMedium!.secondary(context)
                    ),
                    const SizedBox(height: 45),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Steps',
                          style: Theme.of(context).textTheme.headlineMedium
                        ),
                        Text(
                          'Completed: $completedCount/${routineSteps.length}',
                          style: Theme.of(context).textTheme.headlineMedium
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
                                  ), // Add padding if needed
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.4), width: 1),

                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.ac_unit,
                                          color: step['timing'] == 'morning'
                                              ? colorScheme.primary
                                              : colorScheme.surface,
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              step['title'] ?? 'No Title',
                                              style: Theme.of(context).textTheme.headlineMedium
                                            ),
                                            Text(
                                              timing,
                                              style: Theme.of(context).textTheme.bodyLarge!.secondary(context)
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      isCompleted
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check,
                                                  color: colorScheme.primary,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Completed',
                                                  style: Theme.of(context).textTheme.bodyLarge
                                                ),
                                              ],
                                            )
                                          : OutlinedButton(
                                              onPressed: () {
                                              },
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                  color: colorScheme.primary.withOpacity(0.4),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                              ),
                                              child: Text(
                                                'Mark as Done',
                                                style: Theme.of(context).textTheme.bodyLarge!.hint(context)
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
                            style: Theme.of(context).textTheme.headlineMedium!.hint(context)
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
