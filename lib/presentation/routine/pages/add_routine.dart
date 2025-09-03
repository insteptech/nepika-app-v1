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
        
        bool loading = state is RoutineLoading;
        List<Routine> routines = [];
        String? errorMessage;
        String? loadingRoutineId;

        if (state is RoutineLoaded) {
          routines = state.routines;
          Logger.bloc('AddRoutine - RoutineLoaded with ${routines.length} routines');
        } else if (state is RoutineOperationLoading) {
          routines = state.currentRoutines;
          loadingRoutineId = state.operationId;
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
            child: Column(
              children: [
                 Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const CustomBackButton(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        Text(
                          "Add new routine",
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select routine steps to add to your daily routine',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .secondary(context),
                        ),
                        const SizedBox(height: 45),
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
                                          final isLoading = loadingRoutineId == routine.id;
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
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              ],
            ),
          ),
        );
      },
    );
  }
}