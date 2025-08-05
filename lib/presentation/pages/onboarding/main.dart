import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:nepika/core/constants/onboarding_steps.dart';
import 'package:nepika/core/constants/routes.dart';
import 'package:nepika/presentation/pages/onboarding/lifestyle_questionnaire_page.dart';
import 'package:nepika/presentation/pages/onboarding/menstrual_cycle_tracking_page.dart';
import 'package:nepika/presentation/pages/onboarding/skin_goals_page.dart';
import 'package:nepika/presentation/pages/onboarding/skin_type_selection_page.dart';
import 'package:nepika/presentation/pages/onboarding/user_details_page.dart';
import 'package:nepika/presentation/pages/onboarding/user_info_page.dart';
import 'package:nepika/presentation/pages/pricing_and_error/not_found.dart';

class OnboardingNavigator extends StatefulWidget {
  final String activeStep;

  const OnboardingNavigator({
    super.key,
    required this.activeStep,
  });

  @override
  State<OnboardingNavigator> createState() => _OnboardingNavigatorState();
}

class _OnboardingNavigatorState extends State<OnboardingNavigator> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late String _currentRoute;

  final Map<String, Widget> _routes = {
    OnboardingRoutes.userInfo: const UserInfoPage(),
    OnboardingRoutes.userDetails: const UserDetailsPage(),
    OnboardingRoutes.skinType: const SkinTypeSelectionPage(),
    OnboardingRoutes.lifestyle: const LifestyleQuestionnairePage(),
    OnboardingRoutes.skinGoals: const SkinGoalsPage(),
    OnboardingRoutes.cycleDetails: const MenstrualCycleTrackingPage(),
    OnboardingRoutes.naturalRhythm: const MenstrualCycleTrackingPage(),
    OnboardingRoutes.menopause: const MenstrualCycleTrackingPage(),
  };

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.activeStep;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      initialRoute: _currentRoute,
      observers: [
        _OnboardingRouteObserver(
          onRouteChanged: (route) {
            if (mounted && _currentRoute != route) {
              setState(() => _currentRoute = route);
            }
          },
        )
      ],
      onGenerateRoute: (settings) {
        final name = settings.name ?? OnboardingRoutes.userInfo;
        print('OnboardingNavigator: Generating route for $name');
        final Widget page = _routes[name] ?? const NotFound();
        print('Route found for the name ${_routes[name] != null ? name : "null"}');
        return MaterialPageRoute(
          builder: (context) => page,
          settings: RouteSettings(name: name),
        );
      },
    );
  }
}




class _OnboardingRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final Function(String) onRouteChanged;

  _OnboardingRouteObserver({required this.onRouteChanged});

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute?.settings.name != null) {
      onRouteChanged(previousRoute!.settings.name!);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name != null) {
      onRouteChanged(route.settings.name!);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute?.settings.name != null) {
      onRouteChanged(newRoute!.settings.name!);
    }
  }
}
