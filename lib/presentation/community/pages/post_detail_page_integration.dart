import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api_base.dart';
import '../../../data/community/repositories/community_repository_impl.dart';
import '../../../data/community/datasources/community_local_datasource.dart';
import 'post_detail_page.dart';
import '../bloc/community_bloc.dart';

/// Integration wrapper for PostDetailPage
/// 
/// Usage:
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (context) => PostDetailPageIntegration(
///       token: userToken,
///       postId: postId,
///       userId: currentUserId,
///     ),
///   ),
/// );
/// ```
class PostDetailPageIntegration extends StatelessWidget {
  final String token;
  final String postId;
  final String userId;
  final bool? currentLikeStatus;
  final int? currentLikeCount;
  
  const PostDetailPageIntegration({
    super.key,
    required this.token,
    required this.postId,
    required this.userId,
    this.currentLikeStatus,
    this.currentLikeCount,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CommunityBloc(
        CommunityRepositoryImpl(ApiBase(), CommunityLocalDataSourceImpl()),
      ),
      child: PostDetailPage(
        token: token,
        postId: postId,
        userId: userId,
        currentLikeStatus: currentLikeStatus,
        currentLikeCount: currentLikeCount,
      ),
    );
  }
}
