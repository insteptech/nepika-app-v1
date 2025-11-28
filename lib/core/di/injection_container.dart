import 'dart:async';
import 'package:flutter/foundation.dart';
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

// Reminders
import '../../data/reminders/datasources/reminder_remote_data_source.dart';
import '../../data/reminders/repositories/reminder_repository_impl.dart';
import '../../domain/reminders/repositories/reminder_repository.dart';
import '../../domain/reminders/usecases/add_reminder.dart';
import '../../features/reminders/bloc/reminder_bloc.dart';

// Local Notifications
import '../services/local_notification_service.dart';

// Purchase Verification
import '../services/purchase_verification_service.dart';

// Community
import '../../data/community/datasources/community_local_datasource.dart';
import '../../data/community/repositories/community_repository_impl.dart';
import '../../domain/community/repositories/community_repository.dart';
import '../../domain/community/usecases/get_received_follow_requests.dart';
import '../../domain/community/usecases/get_sent_follow_requests.dart';
import '../../domain/community/usecases/accept_follow_request.dart';
import '../../domain/community/usecases/decline_follow_request.dart';
import '../../domain/community/usecases/cancel_follow_request.dart';
import '../../domain/community/usecases/check_follow_request_status.dart';
import '../../features/community/bloc/blocs/posts_bloc.dart';
import '../../features/community/bloc/blocs/user_search_bloc.dart';
import '../../features/community/bloc/blocs/profile_bloc.dart';
import '../../features/community/managers/like_state_manager.dart';

// Notifications
import '../../data/notifications/repositories/notification_repository_impl.dart';
import '../../domain/notifications/repositories/notification_repository.dart';
import '../../features/notifications/bloc/notification_bloc.dart';

// Blocked Users
import '../../data/blocked_users/repositories/blocked_users_repository_impl.dart';
import '../../domain/blocked_users/repositories/blocked_users_repository.dart';
import '../../features/blocked_users/bloc/blocked_users_bloc.dart';

// Payments
import '../../data/payments/datasources/payments_remote_datasource.dart';
import '../../data/payments/repositories/payments_repository_impl.dart';
import '../../domain/payments/repositories/payments_repository.dart';
import '../../domain/payments/usecases/get_payment_plans.dart';
import '../../domain/payments/usecases/get_stripe_config.dart';
import '../../domain/payments/usecases/create_checkout_session.dart';
import '../../domain/payments/usecases/get_subscription_status.dart';
import '../../domain/payments/usecases/get_subscription_details.dart';
import '../../domain/payments/usecases/cancel_subscription.dart';
import '../../domain/payments/usecases/reactivate_subscription.dart';
import 'package:nepika/features/payments/bloc/payment_bloc.dart';
import 'package:nepika/features/payments/components/in_app_purchase_service.dart';

// Delete Account
import '../../data/auth/datasources/delete_account_remote_data_source.dart';
import '../../data/auth/repositories/delete_account_repository_impl.dart';
import '../../domain/auth/repositories/delete_account_repository.dart';
import '../../domain/auth/usecases/get_delete_reasons_usecase.dart';
import '../../domain/auth/usecases/delete_account_usecase.dart';
import '../../features/settings/bloc/delete_account_bloc.dart';

class ServiceLocator {
  static final Map<Type, dynamic> _services = <Type, dynamic>{};
  static bool _coreInitialized = false;
  static bool _fullyInitialized = false;
  static Completer<void>? _initializationCompleter;

  /// Returns true if full initialization is complete
  static bool get isFullyInitialized => _fullyInitialized;

  /// Wait for full initialization to complete
  static Future<void> waitForInitialization() async {
    debugPrint('ServiceLocator.waitForInitialization: fullyInitialized=$_fullyInitialized, completer=${_initializationCompleter != null}');
    if (_fullyInitialized) return;
    _initializationCompleter ??= Completer<void>();
    debugPrint('ServiceLocator.waitForInitialization: Waiting on completer...');
    return _initializationCompleter!.future;
  }

  static T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T is not registered. Core: $_coreInitialized, Full: $_fullyInitialized');
    }
    if (service is Function) {
      return service() as T;
    }
    return service as T;
  }

  /// Safely get a service, returning null if not registered
  static T? getOrNull<T>() {
    final service = _services[T];
    if (service == null) return null;
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

  /// Initialize only core services needed immediately
  static void initializeCore(SharedPreferences sharedPreferences) {
    if (_coreInitialized) return;
    
    // Register only essential services
    _registerLazySingleton<SharedPreferences>(sharedPreferences);
    _registerLazySingleton<SecureStorage>(SecureStorage());
    _registerLazySingleton<ApiBase>(ApiBase());
    _registerLazySingleton<NetworkInfo>(NetworkInfoImpl());
    
    _coreInitialized = true;
  }
  
  /// Initialize remaining services in background
  static Future<void> initializeRemaining() async {
    if (_fullyInitialized) return;

    // Create completer at start so waiters can await it
    _initializationCompleter ??= Completer<void>();

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

    // Note: UnifiedFcmService is a singleton accessed via UnifiedFcmService.instance
    // No need to register it in DI as it manages its own lifecycle
    // Legacy FcmTokenService has been removed - use UnifiedFcmService.instance instead

    // Local Notifications Service (Singleton)
    _registerLazySingleton<LocalNotificationService>(
      LocalNotificationService.instance,
    );

    // Purchase Verification Service (Singleton)
    _registerLazySingleton<PurchaseVerificationService>(
      PurchaseVerificationService(),
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

    // Community - Data sources
    _registerLazySingleton<CommunityLocalDataSource>(
      CommunityLocalDataSourceImpl(),
    );

    // Community - Repository
    _registerLazySingleton<CommunityRepository>(
      CommunityRepositoryImpl(
        get<ApiBase>(),
        get<CommunityLocalDataSource>(),
      ),
    );

    // Community - Use cases
    _registerLazySingleton<GetReceivedFollowRequestsUseCase>(
      GetReceivedFollowRequestsUseCase(get<CommunityRepository>()),
    );
    _registerLazySingleton<GetSentFollowRequestsUseCase>(
      GetSentFollowRequestsUseCase(get<CommunityRepository>()),
    );
    _registerLazySingleton<AcceptFollowRequestUseCase>(
      AcceptFollowRequestUseCase(get<CommunityRepository>()),
    );
    _registerLazySingleton<DeclineFollowRequestUseCase>(
      DeclineFollowRequestUseCase(get<CommunityRepository>()),
    );
    _registerLazySingleton<CancelFollowRequestUseCase>(
      CancelFollowRequestUseCase(get<CommunityRepository>()),
    );
    _registerLazySingleton<CheckFollowRequestStatusUseCase>(
      CheckFollowRequestStatusUseCase(get<CommunityRepository>()),
    );

    // Community - Like State Manager (Singleton with delayed initialization)
    _registerLazySingleton<LikeStateManager>(
      LikeStateManager(),
    );

    // Community - BLoCs (Lazy Singletons for cross-screen navigation stability)
    _registerLazySingleton<PostsBloc>(
      () {
        final likeStateManager = get<LikeStateManager>();
        final repository = get<CommunityRepository>();
        
        // Initialize LikeStateManager if not already initialized
        likeStateManager.initialize(repository);
        
        return PostsBloc(
          repository: repository,
          likeStateManager: likeStateManager,
        );
      }(),
    );
    
    _registerLazySingleton<UserSearchBloc>(
      UserSearchBloc(
        repository: get<CommunityRepository>(),
      ),
    );
    
    _registerLazySingleton<ProfileBloc>(
      ProfileBloc(
        repository: get<CommunityRepository>(),
      ),
    );

    // Notifications - Repository
    _registerLazySingleton<NotificationRepository>(
      NotificationRepositoryImpl(
        apiBase: get<ApiBase>(),
      ),
    );

    // Notifications - Bloc (Factory)
    _registerFactory<NotificationBloc>(
      () => NotificationBloc(
        notificationRepository: get<NotificationRepository>(),
      ),
    );

    // Blocked Users - Repository  
    // Types: BlockedUsersRepository, BlockedUsersRepositoryImpl, BlockedUsersBloc
    _registerLazySingleton<BlockedUsersRepository>(
      BlockedUsersRepositoryImpl(get<ApiBase>()),
    );

    // Blocked Users - Bloc (Factory)
    _registerFactory<BlockedUsersBloc>(
      () => BlockedUsersBloc(
        repository: get<BlockedUsersRepository>(),
      ),
    );

    // Payments - Data sources
    _registerLazySingleton<PaymentsRemoteDataSource>(
      PaymentsRemoteDataSourceImpl(get<ApiBase>()),
    );

    // Payments - Repository
    _registerLazySingleton<PaymentsRepository>(
      PaymentsRepositoryImpl(get<PaymentsRemoteDataSource>()),
    );

    // Payments - Use cases
    _registerLazySingleton<GetPaymentPlans>(
      GetPaymentPlans(get<PaymentsRepository>()),
    );
    _registerLazySingleton<GetStripeConfig>(
      GetStripeConfig(get<PaymentsRepository>()),
    );
    _registerLazySingleton<CreateCheckoutSession>(
      CreateCheckoutSession(get<PaymentsRepository>()),
    );
    _registerLazySingleton<GetSubscriptionStatus>(
      GetSubscriptionStatus(get<PaymentsRepository>()),
    );
    _registerLazySingleton<GetSubscriptionDetails>(
      GetSubscriptionDetails(get<PaymentsRepository>()),
    );
    _registerLazySingleton<CancelSubscription>(
      CancelSubscription(get<PaymentsRepository>()),
    );
    _registerLazySingleton<ReactivateSubscription>(
      ReactivateSubscription(get<PaymentsRepository>()),
    );

    // Payments - Bloc (Factory)
    _registerFactory<PaymentBloc>(
      () => PaymentBloc(
        getPaymentPlans: get<GetPaymentPlans>(),
        getStripeConfig: get<GetStripeConfig>(),
        createCheckoutSession: get<CreateCheckoutSession>(),
        getSubscriptionStatus: get<GetSubscriptionStatus>(),
        getSubscriptionDetails: get<GetSubscriptionDetails>(),
        cancelSubscription: get<CancelSubscription>(),
        reactivateSubscription: get<ReactivateSubscription>(),
      ),
    );

    // IAP Service (Singleton - it manages its own state)
    _registerLazySingleton<IAPService>(IAPService());

    // IAP Bloc (Factory - creates new instance each time)
    _registerFactory<IAPBloc>(
      () => IAPBloc(iapService: get<IAPService>()),
    );

    // Delete Account - Data sources
    _registerLazySingleton<DeleteAccountRemoteDataSource>(
      DeleteAccountRemoteDataSourceImpl(get<ApiBase>()),
    );

    // Delete Account - Repository
    _registerLazySingleton<DeleteAccountRepository>(
      DeleteAccountRepositoryImpl(get<DeleteAccountRemoteDataSource>()),
    );

    // Delete Account - Use cases
    _registerLazySingleton<GetDeleteReasonsUseCase>(
      GetDeleteReasonsUseCase(get<DeleteAccountRepository>()),
    );
    _registerLazySingleton<DeleteAccountUseCase>(
      DeleteAccountUseCase(get<DeleteAccountRepository>()),
    );

    // Delete Account - Bloc (Factory)
    _registerFactory<DeleteAccountBloc>(
      () => DeleteAccountBloc(
        getDeleteReasonsUseCase: get<GetDeleteReasonsUseCase>(),
        deleteAccountUseCase: get<DeleteAccountUseCase>(),
      ),
    );
    
    _fullyInitialized = true;

    // Complete the initialization completer if anyone is waiting
    if (_initializationCompleter != null && !_initializationCompleter!.isCompleted) {
      _initializationCompleter!.complete();
    }
  }

  /// Legacy method for backward compatibility
  static Future<void> init() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    initializeCore(sharedPreferences);
    await initializeRemaining();
  }

  static void reset() {
    _services.clear();
    _coreInitialized = false;
    _fullyInitialized = false;
  }
}

// Global access
final sl = ServiceLocator.get;