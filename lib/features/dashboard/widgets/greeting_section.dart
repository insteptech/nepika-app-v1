import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/features/payments/bloc/payment_bloc.dart';
import 'package:nepika/features/payments/bloc/payment_state.dart';
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

class _GreetingSectionState extends State<GreetingSection> {
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

    return BlocBuilder<PaymentBloc, PaymentState>(
      buildWhen: (previous, current) => current is SubscriptionStatusLoaded || current is PaymentLoading,
      builder: (context, state) {
        bool isPremium = false;
        if (state is SubscriptionStatusLoaded) {
          isPremium = state.status.hasPremium;
        }

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
                        if (isPremium) ...[
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
      },
    );
  }
}
