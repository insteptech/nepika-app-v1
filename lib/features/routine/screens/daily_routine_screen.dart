import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/constants/routes.dart';
import '../../../core/config/constants/app_constants.dart';
import '../../../core/config/constants/theme.dart';
import '../../../core/widgets/back_button.dart';
import '../../../core/widgets/routine_image.dart';
import '../../../core/utils/logger.dart';
import '../bloc/routine_bloc.dart';
import '../bloc/routine_event.dart';
import '../bloc/routine_state.dart';
import '../widgets/sticky_header_delegate.dart';

class DailyRoutineScreen extends StatefulWidget {
  const DailyRoutineScreen({super.key});

  @override
  State<DailyRoutineScreen> createState() => _DailyRoutineScreenState();
}

class _DailyRoutineScreenState extends State<DailyRoutineScreen>
    with WidgetsBindingObserver {
  String? _token;
  bool _isInitialized = false;
  String? _updatingRoutineId; // Track which routine button is loading

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
                    LoadTodaysRoutineEvent(
                      token: _token!,
                      type: 'get-user-routines',
                    ),
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
          // No need to refresh - the success state already contains updated routines
        }
      },
      builder: (context, state) {
        bool loading =
            state is RoutineLoading; // Only show full loading for initial load

        // Track which specific routine is being updated
        if (state is RoutineOperationLoading) {
          _updatingRoutineId = state.operationId;
        } else {
          _updatingRoutineId = null;
        }
        List<dynamic> routineSteps = [];
        int completedCount = 0;
        String? errorMessage;

        if (state is RoutineLoaded ||
            state is RoutineOperationLoading ||
            state is RoutineOperationSuccess) {
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
          body: RefreshIndicator(
            onRefresh: () async {
              if (_token != null) {
                context.read<RoutineBloc>().add(
                  RefreshRoutinesEvent(
                    token: _token!,
                    type: 'get-user-routines',
                  ),
                );
              }
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          const CustomBackButton(),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyHeaderDelegate(
                    minHeight: 40,
                    maxHeight: 40,
                    isFirstHeader: true,
                    title: "Today's Routine",
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Today's Routine",
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Stay consistent. Mark each step as you complete it.',
                          style: Theme.of(context).textTheme.headlineMedium!.secondary(context),
                        ),
                        const SizedBox(height: 25),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyHeaderDelegate(
                    minHeight: 40,
                    maxHeight: 40,
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
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
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildContent(
                      context: context,
                      loading: loading,
                      errorMessage: errorMessage,
                      routineSteps: routineSteps,
                      completedCount: completedCount,
                    ),
                  ),
                ),
              ],
            ),
            )
          ),
        );
      },
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required bool loading,
    required String? errorMessage,
    required List<dynamic> routineSteps,
    required int completedCount,
  }) {
    return Column(
      children: [
        const SizedBox(height: 8),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (errorMessage != null)
          _buildErrorState(context, errorMessage)
        else if (routineSteps.isEmpty)
          _buildEmptyState(context)
        else
          _buildRoutineSteps(context, routineSteps, completedCount),
        const SizedBox(height: 24),
        if (routineSteps.isNotEmpty)
          _buildEditRoutineButton(context),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Column(
      children: [
        const SizedBox(height: 50),
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
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
              maxLines: 1,
              textAlign: TextAlign.end,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.hint(context)
                  .copyWith(
                    decoration:
                        TextDecoration.combine([
                          TextDecoration.underline,
                        ]),
                    decorationColor: Theme.of(
                      context,
                    ).colorScheme.primary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineSteps(BuildContext context, List<dynamic> routineSteps, int completedCount) {
    return Column(
      children: routineSteps.map((step) {
        final isCompleted = step['isCompleted'] == true;
        final timing = step['timing'] == 'morning'
            ? 'Morning Routine'
            : 'Night Routine';

        return Container(
          height: 85,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RoutineImageWidget(
                imageUrl: step['routineIcon'],
                size: 44,
                timing: step['timing'] ?? 'morning',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['name'] ?? 'Step',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timing,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.secondary(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildStepAction(context, step, isCompleted),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStepAction(BuildContext context, Map<String, dynamic> step, bool isCompleted) {
    if (isCompleted) {
      return Row(
        children: [
          Icon(
            Icons.check,
            color: Theme.of(context)
                .textTheme
                .bodyLarge!
                .hint(context)
                .color,
            size: 24,
          ),
          const SizedBox(width: 4),
          Text(
            'Completed',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      );
    }

    return OutlinedButton(
      onPressed: _updatingRoutineId == step['id']
          ? null
          : () {
              // Update local state immediately for instant feedback
              setState(() {
                step['isCompleted'] = true;
              });

              context.read<RoutineBloc>().add(
                UpdateRoutineStepEvent(
                  token: _token!,
                  routineId: step['id'],
                  isCompleted: true,
                ),
              );
            },
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
      child: _updatingRoutineId == step['id']
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          : Text(
              'Mark as Done',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .hint(context),
            ),
    );
  }

  Widget _buildEditRoutineButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: GestureDetector(
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
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium!
                  .hint(context),
            ),
          ],
        ),
      ),
    );
  }
}