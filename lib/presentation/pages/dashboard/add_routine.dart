import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/constants/routes.dart';
import 'package:nepika/core/constants/theme.dart';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/data/dashboard/repositories/dashboard_repository.dart';
import 'package:nepika/presentation/bloc/dashboard/dashboard_bloc.dart';
import 'package:nepika/presentation/bloc/dashboard/dashboard_event.dart';
import 'package:nepika/presentation/bloc/dashboard/dashboard_state.dart';

class AddRoutine extends StatelessWidget {
  const AddRoutine({super.key});
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String token = '';
    return BlocProvider(
      create: (context) => DashboardBloc(
        DashboardRepository(
          ApiBase(),
        ),
      )..add(FetchTodaysRoutine(token, 'add')),
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          List<dynamic> routineSteps = [];
          bool loading = state is TodaysRoutineLoading;
          if (state is TodaysRoutineLoaded) {
            routineSteps = state.routineSteps;
          }
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
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
                      "Add new routine",
                      style: Theme.of(context).textTheme.displaySmall

                    ),
                    const SizedBox(height: 45),

                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              itemCount: routineSteps.length,
                              itemBuilder: (context, index) {
                                final step = routineSteps[index];
                                final timing = step['timing'] == 'morning'
                                    ? 'Morning Routine'
                                    : 'Night Routine';
                                final color = step['timing'] == 'morning'
                                    ? colorScheme.secondaryContainer
                                    : colorScheme.primaryContainer; 
                                return Container(
                                  height: 85,
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
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
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .secondary(context),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () {},
                                        child: Image.asset(
                                          'assets/icons/add_icon.png',
                                          width: 22,
                                          height: 22,
                                          color: colorScheme.primary,
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
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.dashboardReminderSettings,
                          (route) => false,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Done',
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
