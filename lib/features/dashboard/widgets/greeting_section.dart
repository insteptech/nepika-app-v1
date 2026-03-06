import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/presentation/bloc/app/app_bloc.dart';
import 'package:nepika/presentation/bloc/app/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GreetingSection extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isCollapsed;
  
  const GreetingSection({
    required this.user, 
    this.isCollapsed = false,
    super.key
  });

  @override
  State<GreetingSection> createState() => _GreetingSectionState();
}

class _GreetingSectionState extends State<GreetingSection> with RouteAware {
  bool _isPremium = false;
  RouteObserver<PageRoute>? _routeObserver;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route is PageRoute) {
      final navigator = Navigator.of(context);
      final observers = navigator.widget.observers;
      _routeObserver = observers.whereType<RouteObserver<PageRoute>>().firstOrNull;
      if (_routeObserver != null) {
        _routeObserver!.subscribe(this, route);
      }
    }
  }

  @override
  void dispose() {
    if (_routeObserver != null) {
      _routeObserver!.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when the top route has been popped off, and the current route shows up.
    // e.g., coming back from the Pricing Screen
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString('cached_subscription_plan');
      
      if (cachedData != null) {
        debugPrint('CACHED SUBSCRIPTION DATA: $cachedData');
        final data = jsonDecode(cachedData);
        final hasSubscription = data['has_subscription'] == true || data['is_premium'] == true;
        
        bool isCanceled = false;
        if (data['current_plan'] != null) {
          isCanceled = data['current_plan']['cancel_at_period_end'] == true;
        } else if (data['cancel_at_period_end'] != null) {
          isCanceled = data['cancel_at_period_end'] == true;
        }

        final isPremium = hasSubscription && !isCanceled;
        debugPrint('BADGE STATUS: hasSubscription=$hasSubscription, isCanceled=$isCanceled, SHOW_BADGE=$isPremium');
        
        if (mounted) setState(() => _isPremium = isPremium);
      }
    } catch (e) {
      debugPrint('Error reading cached subscription for badge: $e');
    }
  }

  String _getTimeBasedGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    
    if (hour >= 5 && hour < 12) {
      return 'Good Morning!';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon!';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening!';
    } else {
      return 'Good Night!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userName = widget.user['name']?.toString().trim() ?? '';

    final String? avatarUrl = widget.user['avatarUrl'];
    final ImageProvider avatarImage =
        (avatarUrl != null && avatarUrl.trim().isNotEmpty)
        ? NetworkImage(avatarUrl)
        : const AssetImage('assets/icons/horizontal_lines_with_dots.png');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        crossAxisAlignment: widget.isCollapsed ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Column(
                  key: const ValueKey('expanded'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hey, ${userName.isNotEmpty ? userName.split(' ')[0] : 'User'}',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        if (_isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '✦',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    !widget.isCollapsed 
                      ? AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: widget.isCollapsed ? 0.0 : 1.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                _getTimeBasedGreeting(),
                                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ) 
                      : const SizedBox(height: 0),
                  ],
                ),
          ),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: IconButton(
              onPressed: () => {
                Navigator.of(context).pushNamed(AppRoutes.dashboardSettings)
              },
              padding: EdgeInsets.all(0),
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: 34,
                height: 34,
                margin: EdgeInsets.all(0),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: widget.isCollapsed 
                    ? null 
                    : Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.0,
                      ),
                ),
                child: Image(
                  image: avatarImage,
                  height: 18,
                  width: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
