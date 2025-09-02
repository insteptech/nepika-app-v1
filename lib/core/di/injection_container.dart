import 'package:shared_preferences/shared_preferences.dart';

// Core
import '../network/network_info.dart';
import '../api_base.dart';
import '../utils/secure_storage.dart';

// Routine
import '../../data/routine/datasources/routine_remote_data_source.dart';
import '../../data/routine/datasources/routine_remote_data_source_impl.dart';
import '../../data/routine/repositories/routine_repository_impl.dart';
import '../../domain/routine/repositories/routine_repository.dart';
import '../../domain/routine/usecases/get_todays_routine.dart';
import '../../domain/routine/usecases/update_routine_step.dart';
import '../../domain/routine/usecases/delete_routine_step.dart';
import '../../domain/routine/usecases/add_routine_step.dart';
import '../../presentation/routine/bloc/routine_bloc.dart';

class ServiceLocator {
  static final Map<Type, dynamic> _services = <Type, dynamic>{};
  
  static T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T is not registered. Make sure to call init() first.');
    }
    if (service is Function) {
      return service() as T;
    }
    return service as T;
  }

  static void _registerLazySingleton<T>(T instance) {
    _services[T] = instance;
  }

  static void _registerFactory<T>(T Function() factory) {
    _services[T] = factory;
  }

  static Future<void> init() async {
    // External dependencies
    final sharedPreferences = await SharedPreferences.getInstance();
    _registerLazySingleton<SharedPreferences>(sharedPreferences);

    // Core
    _registerLazySingleton<SecureStorage>(SecureStorage());
    _registerLazySingleton<ApiBase>(ApiBase());
    _registerLazySingleton<NetworkInfo>(NetworkInfoImpl());

    // Routine - Data sources
    _registerLazySingleton<RoutineRemoteDataSource>(
      RoutineRemoteDataSourceImpl(apiBase: get<ApiBase>()),
    );

    // Routine - Repository
    _registerLazySingleton<RoutineRepository>(
      RoutineRepositoryImpl(
        remoteDataSource: get<RoutineRemoteDataSource>(),
        networkInfo: get<NetworkInfo>(),
      ),
    );

    // Routine - Use cases
    _registerLazySingleton<GetTodaysRoutine>(
      GetTodaysRoutine(get<RoutineRepository>()),
    );
    _registerLazySingleton<UpdateRoutineStep>(
      UpdateRoutineStep(get<RoutineRepository>()),
    );
    _registerLazySingleton<DeleteRoutineStep>(
      DeleteRoutineStep(get<RoutineRepository>()),
    );
    _registerLazySingleton<AddRoutineStep>(
      AddRoutineStep(get<RoutineRepository>()),
    );

    // Routine - Bloc (Factory)
    _registerFactory<RoutineBloc>(
      () => RoutineBloc(
        getTodaysRoutine: get<GetTodaysRoutine>(),
        updateRoutineStep: get<UpdateRoutineStep>(),
        deleteRoutineStep: get<DeleteRoutineStep>(),
        addRoutineStep: get<AddRoutineStep>(),
      ),
    );
  }

  static void reset() {
    _services.clear();
  }
}

// Global access
final sl = ServiceLocator.get;