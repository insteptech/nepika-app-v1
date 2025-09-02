import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../presentation/routine/bloc/routine_bloc.dart';

/// Provides RoutineBloc to the widget tree using dependency injection
class RoutineBlocProvider extends StatelessWidget {
  final Widget child;

  const RoutineBlocProvider({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RoutineBloc>(
      create: (context) => sl<RoutineBloc>(),
      child: child,
    );
  }
}

/// Provides RoutineBloc using factory pattern for multiple instances
class RoutineBlocFactoryProvider extends StatelessWidget {
  final Widget child;

  const RoutineBlocFactoryProvider({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RoutineBloc>(
      create: (context) => ServiceLocator.get<RoutineBloc>(),
      child: child,
    );
  }
}

/// Multi-provider for routine feature dependencies
class RoutineFeatureProvider extends StatelessWidget {
  final Widget child;

  const RoutineFeatureProvider({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RoutineBloc>(
          create: (context) => ServiceLocator.get<RoutineBloc>(),
        ),
        // Add other routine-related blocs here if needed
      ],
      child: child,
    );
  }
}