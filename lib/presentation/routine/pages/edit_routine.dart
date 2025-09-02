import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/features/routine/routine_feature.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditRoutine extends StatelessWidget {
  const EditRoutine({super.key});

  @override
  Widget build(BuildContext context) {
    return RoutineBlocProvider(
      child: const _EditRoutineView(),
    );
  }
}

class _EditRoutineView extends StatefulWidget {
  const _EditRoutineView();

  @override
  State<_EditRoutineView> createState() => _EditRoutineViewState();
}

class _EditRoutineViewState extends State<_EditRoutineView> with WidgetsBindingObserver {
  String? _token;
  bool _isLoading = true;
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
        bool loading = state is RoutineLoading;
        List<Routine> routines = [];
        String? errorMessage;
        String? loadingRoutineId;

        if (state is RoutineLoaded) {
          routines = state.routines;
        } else if (state is RoutineOperationLoading) {
          routines = state.currentRoutines;
          loadingRoutineId = state.operationId;
        } else if (state is RoutineOperationSuccess) {
          routines = state.routines;
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
                    "Edit routine",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Remove routine steps from your daily routine',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium!
                        .secondary(context),
                  ),
                  const SizedBox(height: 45),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        _refreshRoutines();
                        // Wait a bit for the refresh to complete
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : errorMessage != null
                              ? RoutineErrorWidget(
                                  message: errorMessage,
                                  onRetry: () {
                                    context.read<RoutineBloc>().add(
                                          LoadTodaysRoutineEvent(token: _token!, type: 'get-user-routines'),
                                        );
                                  },
                                )
                            : routines.isEmpty
                                ? NoRoutinesFound(
                                    onAddRoutines: () async {
                                      await Navigator.pushNamed(
                                        context,
                                        AppRoutes.dashboardAddRoutine,
                                      );
                                      // Refresh the routines when coming back from add routine screen
                                      _refreshRoutines();
                                    },
                                  )
                                : RoutineList(
                                    routines: routines,
                                    tileType: RoutineTileType.editable,
                                    loadingRoutineId: loadingRoutineId,
                                    onDeleteRoutine: _onDeleteRoutine,
                                  ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        AppRoutes.dashboardAddRoutine,
                      );
                      // Refresh the routines when coming back from add routine screen
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
                          'Add more routines',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .hint(context),
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
    );
  }
}