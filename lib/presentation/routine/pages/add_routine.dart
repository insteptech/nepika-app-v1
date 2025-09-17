import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/constants/routes.dart';
import '../../../core/config/constants/app_constants.dart';
import '../../../core/config/constants/theme.dart';
import '../../../core/widgets/back_button.dart';
import '../../../core/utils/logger.dart';
import '../../../features/routine/routine_feature.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddRoutine extends StatelessWidget {
  const AddRoutine({super.key});

  @override
  Widget build(BuildContext context) {
    return RoutineBlocProvider(
      child: const _AddRoutineView(),
    );
  }
}

class _AddRoutineView extends StatefulWidget {
  const _AddRoutineView();

  @override
  State<_AddRoutineView> createState() => _AddRoutineViewState();
}

class _AddRoutineViewState extends State<_AddRoutineView> {
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
                  delegate: _StickyHeaderDelegate(
                    minHeight: 40,
                    maxHeight: 40,
                    showAnimatedBackButton: true,
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
                        loading
                            ? const Center(child: CircularProgressIndicator())
                            : errorMessage != null
                                ? RoutineErrorWidget(
                                    message: errorMessage,
                                    onRetry: () {
                                      context.read<RoutineBloc>().add(
                                            LoadAllRoutinesEvent(token: _token!),
                                          );
                                    },
                                  )
                                : routines.isEmpty
                                    ? NoRoutinesAvailable(
                                        onRefresh: () {
                                          context.read<RoutineBloc>().add(
                                                LoadAllRoutinesEvent(token: _token!),
                                              );
                                        },
                                      )
                                    : Column(
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
                                      ),
                        Container(
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
                        ),
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
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;
  final bool showAnimatedBackButton;
  final String? title;
  final Color? backgroundColor;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
    this.showAnimatedBackButton = false,
    this.title,
    this.backgroundColor,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    if (showAnimatedBackButton && title != null) {
      final isStuckToTop = shrinkOffset > 0;
      
      return Container(
        color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 10),
        child: Row(
          children: [
            // Animated back button with slide effect
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: isStuckToTop ? 40 : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isStuckToTop ? 1.0 : 0.0,
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  maxWidth: 40,
                  child: CustomBackButton(
                    label: '',
                    iconSize: 24,
                    iconColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return SizedBox.expand(child: child);
    }
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child ||
        showAnimatedBackButton != oldDelegate.showAnimatedBackButton ||
        title != oldDelegate.title ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}