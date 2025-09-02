import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/features/routine/routine_feature.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllRoutinesPage extends StatelessWidget {
  const AllRoutinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoutineBlocProvider(
      child: const _AllRoutinesPageView(),
    );
  }
}

class _AllRoutinesPageView extends StatefulWidget {
  const _AllRoutinesPageView();

  @override
  State<_AllRoutinesPageView> createState() => _AllRoutinesPageViewState();
}

class _AllRoutinesPageViewState extends State<_AllRoutinesPageView> with WidgetsBindingObserver {
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
      context.read<RoutineBloc>().add(LoadAllRoutinesEvent(token: _token!));
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

    // Load all available routines using BLoC provided by RoutineBlocProvider
    if (mounted) {
      context.read<RoutineBloc>().add(LoadAllRoutinesEvent(token: _token!));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
                    "All Available Routines",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Browse all routine steps available in the app',
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
                                : RoutineList(
                                    routines: routines,
                                    tileType: RoutineTileType.selection,
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
}