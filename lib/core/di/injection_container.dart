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
import '../../features/routine/main.dart';

// FCM
import '../../data/fcm/repositories/fcm_token_repository_impl.dart';
import '../../domain/fcm/repositories/fcm_token_repository.dart';
import '../../domain/fcm/usecases/save_fcm_token_usecase.dart';
import '../services/fcm_token_service.dart';

// Reminders
import '../../data/reminders/datasources/reminder_remote_data_source.dart';
import '../../data/reminders/repositories/reminder_repository_impl.dart';
import '../../domain/reminders/repositories/reminder_repository.dart';
import '../../domain/reminders/usecases/add_reminder.dart';
import '../../features/reminders/bloc/reminder_bloc.dart';

// Local Notifications
import '../services/local_notification_service.dart';

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

    // FCM - Repository
    _registerLazySingleton<FcmTokenRepository>(
      FcmTokenRepositoryImpl(
        apiBase: get<ApiBase>(),
      ),
    );

    // FCM - Use cases
    _registerLazySingleton<SaveFcmTokenUseCase>(
      SaveFcmTokenUseCase(get<FcmTokenRepository>()),
    );

    // FCM - Legacy Service (Deprecated - use UnifiedFcmService.instance instead)
    _registerLazySingleton<FcmTokenService>(
      FcmTokenService(
        saveFcmTokenUseCase: get<SaveFcmTokenUseCase>(),
      ),
    );

    // Note: UnifiedFcmService is a singleton accessed via UnifiedFcmService.instance
    // No need to register it in DI as it manages its own lifecycle

    // Local Notifications Service (Singleton)
    _registerLazySingleton<LocalNotificationService>(
      LocalNotificationService.instance,
    );

    // Reminders - Data sources
    _registerLazySingleton<ReminderRemoteDataSource>(
      ReminderRemoteDataSourceImpl(get<ApiBase>()),
    );

    // Reminders - Repository
    _registerLazySingleton<ReminderRepository>(
      ReminderRepositoryImpl(get<ReminderRemoteDataSource>()),
    );

    // Reminders - Use cases
    _registerLazySingleton<AddReminder>(
      AddReminder(get<ReminderRepository>()),
    );

    // Reminders - Bloc (Factory)
    _registerFactory<ReminderBloc>(
      () => ReminderBloc(
        addReminderUseCase: get<AddReminder>(),
        localNotificationService: get<LocalNotificationService>(),
      ),
    );
  }

  static void reset() {
    _services.clear();
  }
}

// Global access
final sl = ServiceLocator.get;