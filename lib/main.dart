import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/config/constants/theme_notifier.dart';
import 'package:nepika/core/services/unified_fcm_service.dart';
import 'package:nepika/core/utils/shared_prefs_helper.dart';
import 'package:nepika/features/onboarding/screens/onboarding_screen.dart';
import 'package:nepika/features/dashboard/screens/skin_condition_details_screen.dart';
import 'package:nepika/features/face_scan/main.dart';
import 'package:nepika/features/face_scan/screens/scan_report_loader_screen.dart';
import 'package:nepika/features/dashboard/screens/image_gallery_screen.dart';
import 'package:nepika/features/dashboard/screens/history_screen.dart';
import 'package:nepika/features/settings/screens/main_settings_screen.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/fcm_background_handler.dart';
import 'package:nepika/features/settings/screens/privacy_policy_screen.dart';
import 'package:nepika/features/settings/screens/terms_of_use_screen.dart';
import 'package:nepika/features/dashboard/main.dart';
import 'package:nepika/features/products/main.dart';
import 'package:nepika/features/error_pricing/main.dart';
import 'package:nepika/features/auth/auth_module.dart' as auth_feature;
import 'package:nepika/features/auth/screens/phone_entry_screen.dart';
import 'package:nepika/features/auth/screens/otp_verification_screen.dart';
import 'package:nepika/features/community/main.dart';
import 'package:nepika/features/notifications/screens/notifications_screen.dart';
import 'package:nepika/features/notifications/screens/notification_debug_screen.dart';
import 'package:nepika/features/notifications/bloc/notification_bloc.dart';
import 'package:nepika/features/notifications/bloc/notification_event.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/constants/routes.dart';
import 'core/services/navigation_service.dart';
import 'data/auth/datasources/auth_remote_data_source_impl.dart';
import 'data/auth/datasources/auth_local_data_source_impl.dart';
import 'data/auth/repositories/auth_repository_impl.dart';
import 'domain/auth/usecases/send_otp.dart';
import 'domain/auth/usecases/verify_otp.dart';
import 'domain/auth/usecases/resend_otp.dart' as resend;
import 'features/splash/main.dart';
import 'features/welcome/main.dart'; 
import 'package:provider/provider.dart';

// Background message handler is now in fcm_background_handler.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  final sharedPreferences = await SharedPreferences.getInstance();
  await SharedPrefsHelper.init();
  await di.ServiceLocator.init();

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize unified FCM service
  try {
    await UnifiedFcmService.instance.initialize();
    // Use logger if available, otherwise fallback to debugPrint
    debugPrint('✅ Unified FCM Service initialized successfully');
  } catch (e) {
    debugPrint('❌ Unified FCM Service initialization failed: $e');
    // Continue app initialization even if FCM fails
  }



  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: MyApp(sharedPreferences: sharedPreferences),
    ),
  );
}


class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;
  const MyApp({super.key, required this.sharedPreferences});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);


    final remoteDataSource = AuthRemoteDataSourceImpl();
    final localDataSource = AuthLocalDataSourceImpl(sharedPreferences);
    final authRepository = AuthRepositoryImpl(
      remoteDataSource,
      localDataSource,
    );
    
    // Create use cases
    final sendOtpUseCase = SendOtp(authRepository);
    final verifyOtpUseCase = VerifyOtp(authRepository);
    final resendOtpUseCase = resend.ResendOtp(authRepository);

    final authBloc = auth_feature.AuthBloc(
      sendOtpUseCase: sendOtpUseCase,
      verifyOtpUseCase: verifyOtpUseCase,
      resendOtpUseCase: resendOtpUseCase,
    );

    return MultiBlocProvider(
      providers: [BlocProvider(create: (context) => authBloc)],
      child: MaterialApp(
        title: 'Nepika',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeNotifier.themeMode,
        debugShowCheckedModeBanner: false,
        navigatorKey: NavigationService.navigatorKey,
        initialRoute: AppRoutes.splash,
        navigatorObservers: [RouteObserver<PageRoute>()],
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case AppRoutes.splash:
              return MaterialPageRoute(builder: (_) => const SplashScreen());
            case AppRoutes.welcome:
              return MaterialPageRoute(
                builder: (_) => const WelcomeScreen(),
              );
            case AppRoutes.login:
            case AppRoutes.phoneEntry:
              return MaterialPageRoute(builder: (_) => const PhoneEntryScreen());
            case AppRoutes.otpVerification:
              return MaterialPageRoute(
                builder: (_) => const OtpVerificationScreen(),
              );
            case AppRoutes.userInfo:
              return MaterialPageRoute(builder: (_) => const OnboardingScreen());
            case AppRoutes.onboarding:
              return MaterialPageRoute(builder: (_) => const OnboardingScreen());
            case AppRoutes.cameraScanGuidence:
              return MaterialPageRoute(
                builder: (_) => const FaceScanGuidanceScreen(),
              );
            case AppRoutes.faceScanOnboarding:
              return MaterialPageRoute(
                builder: (_) => const FaceScanMainScreen(),
              );
            case AppRoutes.faceScanResult:
              return MaterialPageRoute(
                builder: (_) => const FaceScanResultScreen(),
              );
            case AppRoutes.dashboardHome:
              return MaterialPageRoute(builder: (_) => const DashboardWithNotifications());
            case AppRoutes.dashboardScanResultDetails:
              // Navigate to dashboard first, then to scan result details
              return MaterialPageRoute(
                builder: (_) => DashboardWithScanResults(
                  reportId: (settings.arguments as Map<String, dynamic>?)?['reportId'] as String?,
                ),
              );
            case AppRoutes.conditionDetailsPage:
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const SkinConditionDetailsPage(),
              );
            case AppRoutes.communityHome:
              return MaterialPageRoute(
                builder: (_) => CommunityFeature.create(),
              );
            case AppRoutes.communitySearch:
              return MaterialPageRoute(
                builder: (_) => CommunityFactory.createSearchScreen(),
              );
            case AppRoutes.communityUserProfile:
              return MaterialPageRoute(
                builder: (_) => CommunityFactory.createUserProfileScreen(),
                settings: settings,
              );
            case AppRoutes.dashboardAllProducts:
              return MaterialPageRoute(
                builder: (_) => const ProductsScreen(),
              );
            case AppRoutes.dashboardSpecificProduct:
              return MaterialPageRoute(
                settings: settings,
                builder: (_) {
                  final String productId = settings.arguments as String? ?? '';
                  return ProductInfoScreen(productId: productId);
                },
              );
            case AppRoutes.dashboardImageGallery:
              return MaterialPageRoute(
                settings: settings,
                builder: (_) {
                  final args = settings.arguments as Map<String, dynamic>?;
                  final images = args?['images'] as List<Map<String, dynamic>>?;
                  return ImageGalleryScreen(initialImages: images);
                },
              );
            case AppRoutes.dashboardHistory:
              return MaterialPageRoute(
                builder: (_) => const HistoryScreen(),
              );
            case AppRoutes.dashboardSettings:
              return MaterialPageRoute(
                builder: (_) => const MainSettingsScreen(),
              );
            case AppRoutes.subscription:
              return MaterialPageRoute(builder: (_) => const PricingScreen());
            case AppRoutes.notifications:
              return MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (context) => NotificationBloc()..add(const ConnectToNotificationStream()),
                  child: const NotificationsScreen(),
                ),
              );
            case AppRoutes.notificationDebug:
              return MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (context) => NotificationBloc()..add(const ConnectToNotificationStream()),
                  child: const NotificationDebugScreen(),
                ),
              );
            case AppRoutes.privacyPolicy:
              return MaterialPageRoute(
                builder: (_) => const PrivacyPolicyScreen(),
              );
            case AppRoutes.termsOfUse:
              return MaterialPageRoute(builder: (_) => const TermsOfUseScreen());
            case AppRoutes.scanResultDetails:
              final args = settings.arguments as Map<String, dynamic>?;
              final reportId = args?['reportId'] as String?;
              if (reportId == null) {
                return MaterialPageRoute(builder: (_) => const NotFoundScreen());
              }
              return MaterialPageRoute(
                builder: (_) => ScanReportLoaderScreen(reportId: reportId),
              );
            case AppRoutes.notFound:
              return MaterialPageRoute(builder: (_) => const NotFoundScreen());
            default:
              return MaterialPageRoute(builder: (_) => const NotFoundScreen());
          }
        },
      ),
    );
  }
}

// Placeholder for home page
class PlaceholderHomePage extends StatelessWidget {
  const PlaceholderHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'Home',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Nepika!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Home page will be implemented in the next phase.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
