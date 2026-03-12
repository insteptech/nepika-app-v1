import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/constants/app_constants.dart';
import '../../../core/services/recent_searches_service.dart';
import '../bloc/blocs/user_search_bloc.dart';
import '../bloc/events/user_search_event.dart';
import '../bloc/states/user_search_state.dart';
import '../components/professional_user_card.dart';
import '../components/recent_searches_view.dart';
import '../components/search_skeleton_loader.dart';
import 'package:url_launcher/url_launcher.dart';

class SkincareProfessionalScreen extends StatefulWidget {
  const SkincareProfessionalScreen({super.key});

  @override
  State<SkincareProfessionalScreen> createState() =>
      _SkincareProfessionalScreenState();
}

class _SkincareProfessionalScreenState
    extends State<SkincareProfessionalScreen> {
  String? _token;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  bool _showingResults = false;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initializeAndLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(AppConstants.accessTokenKey);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('SkincareProfessionalScreen: $e');
    }
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() => _showingResults = false);
      context.read<UserSearchBloc>().add(ClearUserSearch());
      return;
    }

    setState(() {});

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _token != null && query.isNotEmpty) {
        setState(() => _showingResults = true);
        final bloc = context.read<UserSearchBloc>();
        if (!bloc.isClosed) {
          bloc.add(
            SearchUsersV2(
              token: _token!,
              query: query,
              isProfessional: true,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.onTertiary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skincare Professionals',
                          style: theme.textTheme.displaySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Find qualified skincare experts',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Search bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onTertiary,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: theme.dividerColor, width: 0.8),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(Icons.search, size: 20,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Search professionals…',
                          hintStyle: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _focusNode.unfocus();
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(Icons.close, size: 18,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4)),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Results / History ────────────────────────────────────────────
            Expanded(
              child: _token == null
                  ? const Center(child: CircularProgressIndicator())
                  : !_showingResults
                      // Show recent searches history when search bar is empty
                      ? RecentSearchesView(
                          token: _token!,
                          onRecentSearchSelected: () {
                            _searchController.clear();
                          },
                        )
                      // Show search results while user has typed something
                      : BlocBuilder<UserSearchBloc, UserSearchState>(
                          builder: (context, state) {
                            if (state is UserSearchV2Loading) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: SearchSkeletonLoader(),
                              );
                            }

                            if (state is UserSearchV2Loaded) {
                              // Client-side filter: backend ignores query for professional
                              // searches so we filter locally by username/name
                              final q = _searchController.text.trim().toLowerCase();
                              final professionals = q.isEmpty
                                  ? state.users
                                  : state.users.where((u) {
                                      return u.username.toLowerCase().contains(q);
                                    }).toList();

                              if (professionals.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_search_outlined,
                                          size: 64,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.25)),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No professionals found',
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                itemCount: professionals.length,
                                itemBuilder: (context, index) {
                                  final user = professionals[index];
                                  return ProfessionalUserCard(
                                    user: user,
                                    onContact: () async {
                                      if (user.tel != null && user.tel!.isNotEmpty) {
                                        final uri = Uri.parse('tel:${user.tel}');
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        } else {
                                          _showSnack(context, 'Could not launch phone dialer');
                                        }
                                      } else {
                                        _showSnack(context, 'Phone number not provided');
                                      }
                                    },
                                    onEmail: () async {
                                      if (user.email != null && user.email!.isNotEmpty) {
                                        final uri = Uri.parse('mailto:${user.email}');
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        } else {
                                          _showSnack(context, 'Could not launch email app');
                                        }
                                      } else {
                                        _showSnack(context, 'Email not provided');
                                      }
                                    },
                                    onTap: () async {
                                      // Save to recent searches when tapped
                                      await RecentSearchesService
                                          .saveRecentSearch(user);
                                    },
                                  );
                                },
                              );
                            }

                            if (state is UserSearchV2Error) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline,
                                        size: 48,
                                        color: theme.colorScheme.error),
                                    const SizedBox(height: 12),
                                    const Text('Failed to load professionals'),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (_searchController.text
                                            .trim()
                                            .isNotEmpty) {
                                          _onSearchChanged();
                                        }
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
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }
}
