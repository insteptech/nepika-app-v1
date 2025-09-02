import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/presentation/community/widgets/create_post.dart';
import 'package:nepika/presentation/community/widgets/page_header.dart';
import 'package:nepika/presentation/community/widgets/user_post.dart';
import '../../../data/community/repositories/community_repository_impl.dart';
import '../../../core/api_base.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';
import 'user_search_page.dart';
import 'create_post_page.dart';

class CommunityHomePage extends StatefulWidget {
  final String token;
  final String userId;

  const CommunityHomePage({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  State<CommunityHomePage> createState() => _CommunityHomePageState();
}

class _CommunityHomePageState extends State<CommunityHomePage> {
  late CommunityBloc _communityBloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _communityBloc = CommunityBloc(CommunityRepositoryImpl(ApiBase()));
    _communityBloc.add(FetchCommunityPosts(token: widget.token));

    // Setup pagination
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = _communityBloc.state;
      if (state is CommunityPostsLoaded && state.hasMorePosts) {
        _communityBloc.add(
          LoadMoreCommunityPosts(
            token: widget.token,
            page: state.currentPage + 1,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _communityBloc.close();
    super.dispose();
  }

  void _navigateToSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: _communityBloc,
          child: UserSearchPage(),
        ),
      ),
    );
  }

  void _navigateToCreatePost() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: _communityBloc,
          child: CreatePostPage(
            token: widget.token,
            userId: widget.userId,
            communityId: 'community_01', // Default community ID
          ),
        ),
      ),
    );

    // Refresh posts if a new post was created
    if (result == true) {
      _communityBloc.add(RefreshCommunityPosts(token: widget.token));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _communityBloc,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SafeArea(
            child: Column(
              children: [
                PageHeader(onSearchTap: _navigateToSearch),
                // const SizedBox(height: 20),

                Expanded(
                  child: BlocBuilder<CommunityBloc, CommunityState>(
                    builder: (context, state) {
                      if (state is CommunityPostsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is CommunityPostsLoaded ||
                          state is CommunityPostsLoadingMore) {
                        final posts = state is CommunityPostsLoaded
                            ? state.posts
                            : (state as CommunityPostsLoadingMore).currentPosts;
                        final hasMorePosts = state is CommunityPostsLoaded
                            ? state.hasMorePosts
                            : true;
                        final currentPage = state is CommunityPostsLoaded
                            ? state.currentPage
                            : 1;

                        return RefreshIndicator(
                          onRefresh: () async {
                            _communityBloc.add(
                              RefreshCommunityPosts(token: widget.token),
                            );
                          },
                          child: ListView.separated(
                            controller: _scrollController,
                            itemCount:
                                posts.length +
                                1 +
                                (hasMorePosts
                                    ? 1
                                    : 0), // +1 for CreatePostWidget
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                // Create post widget as first item
                                return Container(
                                  margin: const EdgeInsets.only(
                                    top: 24,
                                    bottom: 10,
                                  ),
                                  padding: const EdgeInsets.only(bottom: 17),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Theme.of(context)
                                            .textTheme
                                            .headlineMedium!
                                            .secondary(context)
                                            .color!
                                            .withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: CreatePostWidget(
                                    onCreatePostTap: _navigateToCreatePost,
                                  ),
                                );
                              }
                              final postIndex =
                                  index -
                                  1; // Adjust index after create post widget

                              if (postIndex < posts.length) {
                                return UserPostWidget(
                                  post: posts[postIndex],
                                  token: widget.token,
                                  userId: widget.userId,
                                );
                              } else {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      } else if (state is CommunityPostsError) {
                        return Center(
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
                                'Error loading posts',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  _communityBloc.add(
                                    FetchCommunityPosts(token: widget.token),
                                  );
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
