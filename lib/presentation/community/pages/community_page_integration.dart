import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api_base.dart';
import '../../../data/community/repositories/community_repository_impl.dart';
import 'home.dart';
import '../bloc/community_bloc.dart';

/// Example of how to integrate the CommunityHomePage into your app
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
    return BlocProvider(
      create: (context) => CommunityBloc(
        CommunityRepositoryImpl(ApiBase()),
      ),
      child: CommunityHomePage(
        token: token,
        userId: userId,
      ),
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
