import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/constants/routes.dart';
import '../../../core/config/constants/app_constants.dart';
import '../../../core/config/constants/theme.dart';
import '../../../core/config/env.dart';
import '../../../core/widgets/back_button.dart';
import '../../../core/utils/logger.dart';
import '../../../features/routine/routine_feature.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodaysRoutine extends StatelessWidget {
  const TodaysRoutine({super.key});

  @override
  Widget build(BuildContext context) {
    return RoutineBlocProvider(
      child: const _TodaysRoutineView(),
    );
  }
}

class _TodaysRoutineView extends StatefulWidget {
  const _TodaysRoutineView();

  @override
  State<_TodaysRoutineView> createState() => _TodaysRoutineViewState();
}

class _TodaysRoutineViewState extends State<_TodaysRoutineView>
    with WidgetsBindingObserver {
  String? _token;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTokenAndInitialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isInitialized) {
      _refreshRoutines();
    }
  }

  void _refreshRoutines() {
    if (_token != null && _isInitialized) {
      Logger.bloc('Refreshing routines from lifecycle change');
      context.read<RoutineBloc>().add(
        RefreshRoutinesEvent(token: _token!, type: 'get-user-routines'),
      );
    }
  }

  Future<void> _loadTokenAndInitialize() async {
    try {
      Logger.bloc('Initializing daily routine page');
      final sharedPrefs = await SharedPreferences.getInstance();
      final accessToken = sharedPrefs.getString(AppConstants.accessTokenKey);

      if (accessToken == null || accessToken.isEmpty) {
        Logger.bloc('No access token found, redirecting to login');
        if (mounted) {
          Navigator.pushNamed(context, AppRoutes.login);
        }
        return;
      }

      setState(() {
        _token = accessToken;
        _isInitialized = true;
      });

      // Load today's routine using BLoC
      if (mounted) {
        Logger.bloc('Loading today\'s routine with token');
        context.read<RoutineBloc>().add(
          LoadTodaysRoutineEvent(token: _token!, type: 'get-user-routines'),
        );
      }
    } catch (e) {
      Logger.bloc('Error initializing daily routine page', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _token == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocConsumer<RoutineBloc, RoutineState>(
      listener: (context, state) {
        if (state is RoutineError) {
          Logger.bloc('Showing error to user: ${state.failure.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failure.message),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  context.read<RoutineBloc>().add(
                    LoadTodaysRoutineEvent(token: _token!, type: 'get-user-routines'),
                  );
                },
              ),
            ),
          );
        } else if (state is RoutineOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        bool loading = state is RoutineLoading || state is RoutineOperationLoading;
        List<dynamic> routineSteps = [];
          int completedCount = 0;
          String? errorMessage;

          if (state is RoutineLoaded || state is RoutineOperationLoading || state is RoutineOperationSuccess) {
            List<dynamic> currentRoutines = [];
            
            if (state is RoutineLoaded) {
              currentRoutines = state.routines;
            } else if (state is RoutineOperationLoading) {
              currentRoutines = state.currentRoutines;
            } else if (state is RoutineOperationSuccess) {
              currentRoutines = state.routines;
            }
            
            routineSteps = currentRoutines
                .map(
                  (routine) => {
                    'id': routine.id,
                    'name': routine.name,
                    'timing': routine.timing,
                    'isCompleted': routine.isCompleted,
                    'description': routine.description,
                    'routineIcon': routine.routineIcon,
                  },
                )
                .toList();
            completedCount = routineSteps
                .where((s) => s['isCompleted'] == true)
                .length;
          } else if (state is RoutineError) {
            errorMessage = state.failure.message;
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
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium!.secondary(context),
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
                      child: RefreshIndicator(
                        onRefresh: () async {
                          if (_token != null) {
                            context.read<RoutineBloc>().add(
                              RefreshRoutinesEvent(token: _token!, type: 'get-user-routines'),
                            );
                          }
                          await Future.delayed(const Duration(milliseconds: 500));
                        },
                        child: loading
                            ? const Center(child: CircularProgressIndicator())
                            : errorMessage != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Error: $errorMessage',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(color: Colors.red),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        context.read<RoutineBloc>().add(
                                          LoadTodaysRoutineEvent(
                                            token: _token!,
                                            type: 'get-user-routines',
                                          ),
                                        );
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : routineSteps.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_note,
                                      size: 64,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No routines found',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Please add routines to your daily schedule',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .secondary(context),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    GestureDetector(
                                      onTap: () async {
                                        await Navigator.pushNamed(
                                          context,
                                          AppRoutes.dashboardAddRoutine,
                                        );
                                        // Refresh the routines when coming back from add routine screen
                                        _refreshRoutines();
                                      },
                                      child: Text(
                                        'Add routines →',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              // decoration:
                                              //     TextDecoration.underline,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: routineSteps.length,
                                itemBuilder: (context, index) {
                                  final step = routineSteps[index];
                                  final isCompleted =
                                      step['isCompleted'] == true;
                                  final timing = step['timing'] == 'morning'
                                      ? 'Morning Routine'
                                      : 'Night Routine';
                                  final colorScheme = Theme.of(
                                    context,
                                  ).colorScheme;
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 44,
                                          height: 44,
                                          child: Image.network(
                                            '${Env.baseUrl}${step['routineIcon']}',
                                            fit: BoxFit.cover,
                                            loadingBuilder:
                                                (context, child, progress) {
                                                  if (progress == null)
                                                    return child;
                                                  return Container(
                                                    width: 125,
                                                    height: 130,
                                                    color: Colors.grey.shade300,
                                                  );
                                                },
                                            errorBuilder: (_, __, ___) =>
                                                Image.asset(
                                                  'assets/images/image_placeholder.png',
                                                  width: 125,
                                                  height: 130,
                                                  fit: BoxFit.cover,
                                                ),
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
                                                step['name'] ?? 'Step',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.headlineMedium,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                timing,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge?.secondary(context),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        isCompleted
                                            ? Row(
                                                children: [
                                                  Icon(
                                                    Icons.check,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge!.hint(context).color,
                                                    size: 24,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Completed',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                  ),
                                                ],
                                              )
                                            : OutlinedButton(
                                                onPressed: () {
                                                  context
                                                      .read<RoutineBloc>()
                                                      .add(
                                                        UpdateRoutineStepEvent(
                                                          token: _token!,
                                                          routineId: step['id'],
                                                          isCompleted: true,
                                                        ),
                                                      );
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8,
                                                      ),
                                                ),
                                                child: Text(
                                                  'Mark as Done',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge!
                                                      .hint(context),
                                                ),
                                              ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          AppRoutes.dashboardEditRoutine,
                        );
                        // Refresh the routines when coming back from edit routine screen
                        _refreshRoutines();
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
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium!.hint(context),
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
      // ),
    );
  }
}
