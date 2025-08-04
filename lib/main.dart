import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/constants/theme.dart';
import 'package:nepika/core/constants/theme_notifier.dart';
import 'package:nepika/core/utils/shared_prefs_helper.dart';
import 'package:nepika/presentation/pages/terms_and_policy/privacy_policy_page.dart';
import 'package:nepika/presentation/pages/terms_and_policy/terms_of_use_page.dart';
import 'package:nepika/presentation/pages/pricing_and_error/not_found.dart';
import 'package:nepika/presentation/pages/first_scan/scan_guidence_page.dart';
import 'package:nepika/presentation/pages/first_scan/face_scan.dart';
import 'package:nepika/presentation/pages/dashboard/main.dart';
import 'package:nepika/presentation/pages/pricing_and_error/pricing_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/routes.dart';
import 'data/auth/datasources/auth_remote_data_source_impl.dart';
import 'data/auth/datasources/auth_local_data_source_impl.dart';
import 'data/auth/repositories/auth_repository_impl.dart';
import 'core/api_base.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/pages/splash/splash_screen.dart';
import 'presentation/pages/welcome/welcome_screen.dart';
import 'presentation/pages/auth/phone_entry_page.dart';
import 'presentation/pages/auth/otp_verification_page.dart';
import 'presentation/pages/onboarding/user_info_page.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  await SharedPrefsHelper.init(); // Initialize shared preferences helper

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


    final apiBase = ApiBase();
    final remoteDataSource = AuthRemoteDataSourceImpl(apiBase);
    final localDataSource = AuthLocalDataSourceImpl(sharedPreferences);
    final authRepository = AuthRepositoryImpl(
      remoteDataSource,
      localDataSource,
    );
    final authBloc = AuthBloc(authRepository: authRepository);

    return MultiBlocProvider(
      providers: [BlocProvider(create: (context) => authBloc)],
      child: MaterialApp(
        title: 'Nepika',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeNotifier.themeMode,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.splash,
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
              return MaterialPageRoute(builder: (_) => const PhoneEntryPage());
            case AppRoutes.otpVerification:
              return MaterialPageRoute(
                builder: (_) => const OtpVerificationPage(),
              );
            case AppRoutes.userInfo:
              return MaterialPageRoute(builder: (_) => const UserInfoPage());
            case AppRoutes.cameraScanGuidence:
              return MaterialPageRoute(
                builder: (_) => const ScanGuidenceScreen(),
              );
            case AppRoutes.faceScanResult:
              return MaterialPageRoute(
                builder: (_) => FaceScanResultPage(),
              );
            case AppRoutes.dashboardHome:
              return MaterialPageRoute(builder: (_) => const Dashboard());
            case AppRoutes.subscription:
              return MaterialPageRoute(builder: (_) => const PricingPage());
            case AppRoutes.privacyPolicy:
              return MaterialPageRoute(
                builder: (_) => const PrivacyPolicyPage(),
              );
            case AppRoutes.termsOfUse:
              return MaterialPageRoute(builder: (_) => const TermsOfUsePage());
            case AppRoutes.notFound:
              return MaterialPageRoute(builder: (_) => const NotFound());
            // case AppRoutes.todaysRoutine:
            //   return MaterialPageRoute(builder: (_) => const TodaysRoutine());
            default:
              return MaterialPageRoute(builder: (_) => const NotFound());
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
