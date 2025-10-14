import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/constants/routes.dart';
import '../../../core/config/constants/app_constants.dart';
import '../../../core/config/constants/theme.dart';
import '../../../core/widgets/back_button.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/routine/entities/routine.dart';
import '../bloc/routine_bloc.dart';
import '../bloc/routine_event.dart';
import '../bloc/routine_state.dart';
import '../widgets/sticky_header_delegate.dart';
import '../widgets/routine_tile.dart';
import '../widgets/routine_empty_states.dart';

class AddRoutineScreen extends StatefulWidget {
  const AddRoutineScreen({super.key});

  @override
  State<AddRoutineScreen> createState() => _AddRoutineScreenState();
}

class _AddRoutineScreenState extends State<AddRoutineScreen> {
  String? _token;
  bool _isInitialized = false;
  final Set<String> _addedRoutineIds = {};
  final Set<String> _successfullyAddedRoutineIds = {};
  String? _addingRoutineId; // Track which routine is being added

  @override
  void initState() {
    super.initState();
    _loadTokenAndInitialize();
  }

  Future<void> _loadTokenAndInitialize() async {
    try {
      Logger.bloc('Initializing add routine page');
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

      // Load all available routines using BLoC
      if (mounted) {
        Logger.bloc('Loading all available routines');
        context.read<RoutineBloc>().add(
          LoadAllRoutinesEvent(token: _token!),
        );
      }
    } catch (e) {
      Logger.bloc('Error initializing add routine page', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onAddRoutine(String routineId) {
    if (_addedRoutineIds.contains(routineId) || _successfullyAddedRoutineIds.contains(routineId)) {
      return; // Already added or successfully added, do nothing
    }

    _addedRoutineIds.add(routineId);
    Logger.bloc('Adding routine: $routineId');
    context.read<RoutineBloc>().add(AddRoutineStepEvent(
      token: _token!,
      masterRoutineId: routineId,
    ));
  }


  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _token == null) {
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
                const SizedBox(height: 15),
                const SizedBox(height: 40),
                Text(
                  "Add new routine",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select routine steps to add to your daily routine',
                  style: Theme.of(context).textTheme.headlineMedium!.secondary(context),
                ),
                const SizedBox(height: 35),
                Expanded(child: _buildRoutineSkeletons()),
              ],
            ),
          ),
        ),
      );
    }

    return BlocConsumer<RoutineBloc, RoutineState>(
      listener: (context, state) {
        if (state is RoutineError) {
          Logger.bloc('Showing error to user: ${state.failure.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failure.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is RoutineOperationSuccess) {
          // Move from loading to successfully added set
          if (state.operationId != null) {
            setState(() {
              _addedRoutineIds.remove(state.operationId);
              _successfullyAddedRoutineIds.add(state.operationId!);
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        Logger.bloc('AddRoutine builder - Current state: ${state.runtimeType}');
        
        bool loading = state is RoutineLoading; // Only show full loading for initial load
        List<Routine> routines = [];
        String? errorMessage;
        
        // Track which specific routine is being added
        if (state is RoutineOperationLoading) {
          _addingRoutineId = state.operationId;
        } else {
          _addingRoutineId = null;
        }

        if (state is RoutineLoaded) {
          routines = state.routines;
          Logger.bloc('AddRoutine - RoutineLoaded with ${routines.length} routines');
        } else if (state is RoutineOperationLoading) {
          routines = state.currentRoutines;
          Logger.bloc('AddRoutine - RoutineOperationLoading with ${routines.length} routines');
        } else if (state is RoutineOperationSuccess) {
          routines = state.routines;
          Logger.bloc('AddRoutine - RoutineOperationSuccess with ${routines.length} routines');
        } else if (state is RoutineError) {
          errorMessage = state.failure.message;
          Logger.bloc('AddRoutine - RoutineError: $errorMessage');
        } else {
          Logger.bloc('AddRoutine - Unhandled state: ${state.runtimeType}');
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const CustomBackButton(),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                    delegate: StickyHeaderDelegate(
                    minHeight: 40,
                    maxHeight: 40,
                    isFirstHeader: true,
                    title: "Add new routine",
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Add new routine",
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
                          'Select routine steps to add to your daily routine',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .secondary(context),
                        ),
                        const SizedBox(height: 35),
                        _buildContent(
                          context: context,
                          loading: loading,
                          errorMessage: errorMessage,
                          routines: routines,
                        ),
                        _buildDoneButton(context),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required bool loading,
    required String? errorMessage,
    required List<Routine> routines,
  }) {
    if (loading) {
      return _buildRoutineSkeletons();
    }

    if (errorMessage != null) {
      return RoutineErrorWidget(
        message: errorMessage,
        onRetry: () {
          context.read<RoutineBloc>().add(
            LoadAllRoutinesEvent(token: _token!),
          );
        },
      );
    }

    if (routines.isEmpty) {
      return NoRoutinesAvailable(
        onRefresh: () {
          context.read<RoutineBloc>().add(
            LoadAllRoutinesEvent(token: _token!),
          );
        },
      );
    }

    return Column(
      children: routines.map((routine) {
        final isLoading = _addingRoutineId == routine.id;
        final isSuccessfullyAdded = _successfullyAddedRoutineIds.contains(routine.id);

        return RoutineTile(
          routine: routine,
          type: RoutineTileType.selection,
          isLoading: isLoading,
          isSuccessfullyAdded: isSuccessfullyAdded,
          onAdd: () => _onAddRoutine(routine.id),
        );
      }).toList(),
    );
  }

  Widget _buildRoutineSkeletons() {
    return Column(
      children: List.generate(5, (index) => _buildRoutineSkeleton()),
    );
  }

  Widget _buildRoutineSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon skeleton
          const SkeletonLoader(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          const SizedBox(width: 16),
          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                const SkeletonLoader(
                  width: 150,
                  height: 20,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                const SizedBox(height: 8),
                // Description skeleton
                const SkeletonLoader(
                  width: double.infinity,
                  height: 14,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                const SizedBox(height: 4),
                // Second line of description
                SkeletonLoader(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 14,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Add button skeleton
          const SkeletonLoader(
            width: 32,
            height: 32,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Done',
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