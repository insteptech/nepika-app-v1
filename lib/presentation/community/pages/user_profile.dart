import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/utils/secure_storage.dart';
import 'package:nepika/core/utils/shared_prefs_helper.dart';
import 'package:nepika/presentation/community/widgets/user_post.dart';
import 'package:nepika/presentation/community/widgets/user_post_with_comment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/data/community/repositories/community_repository_impl.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';
import '../../../domain/community/entities/community_entities.dart';

enum ActiveTab { threads, replies }

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String? userId;
  String? _token;
  CommunityBloc? _communityBloc;
  bool _isInitialized = false;

  ActiveTab _currentActive = ActiveTab.threads;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    userId = (args is Map<String, dynamic>)
        ? args['userId'] as String? ?? 'Unknown'
        : 'Unknown';

    if (!_isInitialized && userId != null && userId != 'Unknown') {
      _isInitialized = true;
      _initializeData();
    }
  }

  Future<void> _initializeData() async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      await SharedPrefsHelper.init();
      _token = sharedPreferences.getString(AppConstants.accessTokenKey);

      if (_token != null && userId != null && userId != 'Unknown') {
        final apiBase = ApiBase();
        final repository = CommunityRepositoryImpl(apiBase);
        _communityBloc = CommunityBloc(repository);
        _communityBloc!.add(FetchUserProfile(token: _token!, userId: userId!));
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error initializing UserProfilePage: $e");
    }
  }

  @override
  void dispose() {
    _communityBloc?.close();
    super.dispose();
  }

  void toggleActiveTab() {
    setState(() {
      _currentActive = _currentActive == ActiveTab.threads
          ? ActiveTab.replies
          : ActiveTab.threads;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_token == null || _communityBloc == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.onTertiary,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider.value(
      value: _communityBloc!,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.onTertiary,
        body: SafeArea(
          child: BlocBuilder<CommunityBloc, CommunityState>(
            builder: (context, state) {
              if (state is UserProfileLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is UserProfileLoaded) {
                return _buildProfileLayout(context, state.profileData);
              } else if (state is UserProfileError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${state.message}'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _communityBloc!.add(
                            FetchUserProfile(token: _token!, userId: userId!),
                          );
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileLayout(
    BuildContext context,
    UserProfileResponseEntity data,
  ) {
    final profile = data.profile;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Image.asset(
                  'assets/icons/globe_icon.png',
                  height: 25,
                  width: 25,
                  color: Theme.of(context).textTheme.headlineMedium!.color,
                ),
                onPressed: () => {print('Globe icon pressed')},
              ),
              IconButton(
                icon: Image.asset(
                  'assets/icons/menu_icon.png',
                  height: 25,
                  width: 25,
                  color: Theme.of(context).textTheme.headlineMedium!.color,
                ),
                onPressed: () => {print('Menu icon pressed')},
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Text(
                    profile.fullName,
                    style: Theme.of(context).textTheme.displayLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        profile.fullName,
                        style: Theme.of(context).textTheme.headlineMedium!
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: Theme.of(
                            context,
                          ).scaffoldBackgroundColor.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          'threads.net',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall!.secondary(context),
                        ),
                      ),
                    ],
                  ),
                  // if (profile.bio != null && profile.bio!.isNotEmpty)
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.70,
                    child: Text(
                      profile.bio != null && profile.bio!.isNotEmpty
                          ? profile.bio!
                          : 'No bio available...',
                      style: profile.bio != null && profile.bio!.isNotEmpty
                          ? Theme.of(context).textTheme.headlineMedium!
                          : Theme.of(context).textTheme.headlineMedium!
                                .secondary(context)
                                .copyWith(fontWeight: FontWeight.w300),
                      maxLines: 2,
                      overflow: TextOverflow.fade,
                      softWrap: true,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '26 followers',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium!.secondary(context),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                child:
                    profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          profile.avatarUrl!,
                          height: 50,
                          width: 50,
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.center,
                        ),
                      )
                    : Image.asset(
                        'assets/images/nepika_logo_image.png',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 15,
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onTertiary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).textTheme.headlineMedium!.secondary(context).color!,
                      width: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    'Edit Profile',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onTertiary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).textTheme.headlineMedium!.secondary(context).color!,
                      width: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    'Share Profile',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
            ],
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 0,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_currentActive != ActiveTab.threads) {
                    setState(() {
                      _currentActive = ActiveTab.threads;
                    });
                  }
                },

                child: Container(
                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                  decoration: BoxDecoration(
                    border: _currentActive == ActiveTab.threads
                        ? Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                          )
                        : null,
                  ),
                  child: Text(
                    'Threads',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_currentActive != ActiveTab.replies) {
                    setState(() {
                      _currentActive = ActiveTab.replies;
                    });
                  }
                },

                child: Container(
                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                  decoration: BoxDecoration(
                    border: _currentActive == ActiveTab.replies
                        ? Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                          )
                        : null,
                  ),
                  child: Text(
                    'Replies',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _renderPosts(
              _currentActive == ActiveTab.threads
                  ? data.threads
                  : data.replies,
              userId!,
              _currentActive,
            ),
          )
        )


      ],
    );
  }
}


Widget _renderPosts(posts,  userId, active) {
  return FutureBuilder<SharedPreferences>(
    future: SharedPreferences.getInstance(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Center(child: CircularProgressIndicator());
      }

      final token =
          snapshot.data!.getString(AppConstants.accessTokenKey) ?? '';

      return ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return UserPostWithComment(
            thread: active == ActiveTab.threads ? post : null,
            reply: active == ActiveTab.replies ? post : null,
            token: token,
            userId: userId,
          );
        },
      );
    },
  );
}
