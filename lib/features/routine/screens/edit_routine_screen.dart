import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/constants/routes.dart';
import '../../../core/config/constants/app_constants.dart';
import '../../../core/config/constants/theme.dart';
import '../../../core/widgets/back_button.dart';
import '../../../domain/routine/entities/routine.dart';
import '../bloc/routine_bloc.dart';
import '../bloc/routine_event.dart';
import '../bloc/routine_state.dart';
import '../widgets/sticky_header_delegate.dart';
import '../widgets/routine_tile.dart';
import '../widgets/routine_empty_states.dart';

class EditRoutineScreen extends StatefulWidget {
  const EditRoutineScreen({super.key});

  @override
  State<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends State<EditRoutineScreen> with WidgetsBindingObserver {
  String? _token;
  bool _isLoading = true;
  bool _isInitialized = false;
  String? _deletingRoutineId; // Track which routine is being deleted

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
      context.read<RoutineBloc>().add(LoadTodaysRoutineEvent(token: _token!, type: 'get-user-routines'));
    }
  }

  Future<void> _loadTokenAndInitialize() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final accessToken = sharedPrefs.getString(AppConstants.accessTokenKey);

    if (accessToken == null || accessToken.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return;
    }

    setState(() {
      _token = accessToken;
      _isLoading = false;
      _isInitialized = true;
    });

    // Load today's user routines using BLoC provided by RoutineBlocProvider
    if (mounted) {
      context.read<RoutineBloc>().add(LoadTodaysRoutineEvent(token: _token!, type: 'get-user-routines'));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onDeleteRoutine(String routineId) {
    context.read<RoutineBloc>().add(DeleteRoutineStepEvent(
      token: _token!,
      routineId: routineId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _token == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BlocConsumer<RoutineBloc, RoutineState>(
      listener: (context, state) {
        if (state is RoutineError) {
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
        bool loading = state is RoutineLoading; // Only show full loading for initial load
        List<Routine> routines = [];
        String? errorMessage;
        
        // Track which specific routine is being deleted
        if (state is RoutineOperationLoading) {
          _deletingRoutineId = state.operationId;
        } else {
          _deletingRoutineId = null;
        }

        if (state is RoutineLoaded) {
          routines = state.routines;
        } else if (state is RoutineOperationLoading) {
          routines = state.currentRoutines;
        } else if (state is RoutineOperationSuccess) {
          routines = state.routines;
        } else if (state is RoutineError) {
          errorMessage = state.failure.message;
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: RefreshIndicator(
            onRefresh: () async {
              _refreshRoutines();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SafeArea(
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
                    title: "Edit Routine",
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Edit Routine",
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
                            'Remove routine steps from your daily routine',
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
                          if(routines.isNotEmpty)
                            _buildAddStepButton(context),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
      return const Center(child: CircularProgressIndicator());
    }
    
    if (errorMessage != null) {
      return RoutineErrorWidget(
        message: errorMessage,
        onRetry: () {
          context.read<RoutineBloc>().add(
            LoadTodaysRoutineEvent(token: _token!, type: 'get-user-routines'),
          );
        },
      );
    }
    
    if (routines.isEmpty) {
      return NoRoutinesFound(
        onAddRoutines: () async {
          await Navigator.pushNamed(
            context,
            AppRoutes.dashboardAddRoutine,
          );
          _refreshRoutines();
        },
      );
    }

    return Column(
      children: routines.map((routine) {
        final isLoading = _deletingRoutineId == routine.id;
        
        return RoutineTile(
          routine: routine,
          type: RoutineTileType.editable,
          isLoading: isLoading,
          onDelete: () => _onDeleteRoutine(routine.id),
        );
      }).toList(),
    );
  }

  Widget _buildAddStepButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: GestureDetector(
        onTap: () async {
          await Navigator.pushNamed(
            context,
            AppRoutes.dashboardAddRoutine,
          );
          _refreshRoutines();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/add_icon.png',
              width: 20,
              height: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Add new step',
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