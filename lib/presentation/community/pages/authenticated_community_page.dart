import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/config/constants/app_constants.dart';
import '../../../core/config/constants/routes.dart';
import 'community_page_integration.dart';

class AuthenticatedCommunityPage extends StatefulWidget {
  const AuthenticatedCommunityPage({super.key});

  @override
  State<AuthenticatedCommunityPage> createState() => _AuthenticatedCommunityPageState();
}

class _AuthenticatedCommunityPageState extends State<AuthenticatedCommunityPage> {
  bool _isLoading = true;
  String? _token;
  String? _userId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final accessToken = sharedPrefs.getString(AppConstants.accessTokenKey);
      final userData = sharedPrefs.getString(AppConstants.userDataKey);
      
      if (accessToken == null || accessToken.isEmpty) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      String? userId;
      if (userData != null && userData.isNotEmpty) {
        try {
          final userMap = json.decode(userData) as Map<String, dynamic>;
          userId = userMap['user_id'] ?? userMap['id'] ?? 'user_001'; // Fallback userId
        } catch (e) {
          print('Error parsing user data: $e');
          userId = 'user_001'; // Default fallback
        }
      } else {
        userId = 'user_001'; // Default fallback
      }

      setState(() {
        _token = accessToken;
        _userId = userId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading authentication data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _token == null || _userId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Authentication Required',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Please log in to access the community',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return CommunityPageIntegration(
      token: _token!,
      userId: _userId!,
    );
  }
}
