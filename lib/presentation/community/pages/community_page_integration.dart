import 'package:flutter/material.dart';
import 'community_gateway_page.dart';

/// Main integration point for the community feature
/// 
/// This handles:
/// 1. Checking if user has a community profile
/// 2. Creating profile if needed
/// 3. Navigating to community feed once profile is ready
/// 
/// Usage:
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (context) => CommunityPageIntegration(
///       token: userToken,
///       userId: currentUserId,
///     ),
///   ),
/// );
/// ```
class CommunityPageIntegration extends StatelessWidget {
  final String token;
  final String userId;
  
  const CommunityPageIntegration({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return CommunityGatewayPage(
      token: token,
      userId: userId,
    );
  }
}

/// Alternative direct integration without extra wrapper
/// 
/// Usage in existing pages:
/// ```dart
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: CommunityHomePage(
///       token: widget.userToken,
///       userId: widget.currentUserId,
///     ),
///   );
/// }
/// ```
