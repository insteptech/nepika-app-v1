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
  String? _selectedCountry;
  final Set<String> _selectedConcerns = {};
  List<Map<String, String>> _allConcerns = [];
  bool _showingResults = false;
  Timer? _debounceTimer;
  
  // We can populate countries from a static list or an API if available.
  // Using a static representative list for the dropdown for demonstration.
  final List<String> _countries = [
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'India',
    'Ireland',
    'Germany',
    'France',
    'Italy',
    'Spain',
    'Netherlands',
    'Sweden',
    'Brazil',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
    _fetchSkinConcerns();
  }

  Future<void> _fetchSkinConcerns() async {
    // These are the exact 10 skin conditions used by the Nepika backend AI analysis
    setState(() {
      _allConcerns = [
        {'id': 'wrinkle', 'name': 'Wrinkles'},
        {'id': 'acne', 'name': 'Acne'},
        {'id': 'dark-spots', 'name': 'Dark Spots'},
        {'id': 'pores', 'name': 'Enlarged Pores'},
        {'id': 'eyebags', 'name': 'Eyebags'},
        {'id': 'oily-skin', 'name': 'Oily Skin'},
        {'id': 'dry-skin', 'name': 'Dry Skin'},
        {'id': 'blackheads', 'name': 'Blackheads'},
        {'id': 'whiteheads', 'name': 'Whiteheads'},
        {'id': 'skin-redness', 'name': 'Skin Redness'},
      ];
    });
  }

  Future<void> _initializeAndLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(AppConstants.accessTokenKey);
      if (mounted) {
        setState(() {});
        // We no longer fetch all professionals on load.
        // The user will see their recent searches history first.
      }
    } catch (e) {
      debugPrint('🔍 SkincarePro: Error in _initializeAndLoad: $e');
    }
  }

  void _onFilterChanged() {
    _debounceTimer?.cancel();
    
    final hasFilters = _selectedCountry != null || _selectedConcerns.isNotEmpty;

    if (!hasFilters) {
      if (_showingResults) {
        setState(() => _showingResults = false);
      }
      return;
    }

    setState(() => _showingResults = true);

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _token != null) {
        final bloc = context.read<UserSearchBloc>();
        if (!bloc.isClosed) {
          bloc.add(
            SearchUsersV2(
              token: _token!,
              query: '', 
              isProfessional: true,
              country: _selectedCountry,
              skinConditions: _selectedConcerns.toList(),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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

            // ── Filters ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Country Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.5), 
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCountry,
                        hint: Text(
                          'Select Country',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.primary),
                        items: _countries.map((String country) {
                          return DropdownMenuItem<String>(
                            value: country,
                            child: Text(country, style: theme.textTheme.bodyLarge),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCountry = newValue;
                          });
                          _onFilterChanged();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Skin Conditions Filter Chips (Horizontal Scroll)
                  if (_allConcerns.isNotEmpty)
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _allConcerns.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final concern = _allConcerns[index];
                          final id = concern['id'] ?? '';
                          final name = concern['name'] ?? '';
                          final isSelected = _selectedConcerns.contains(id);
                          return FilterChip(
                            label: Text(
                              name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            selected: isSelected,
                            showCheckmark: false,
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  if (_selectedConcerns.length < 10) {
                                    _selectedConcerns.add(id);
                                  } else {
                                    _showSnack(context, 'You can select up to 10 conditions');
                                  }
                                } else {
                                  _selectedConcerns.remove(id);
                                }
                              });
                              _onFilterChanged();
                            },
                            backgroundColor: theme.colorScheme.surface,
                            selectedColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // ── Results / History ────────────────────────────────────────────
            Expanded(
              child: _token == null
                  ? const Center(child: CircularProgressIndicator())
                  : !_showingResults
                      // Show recent searches history when search bar is empty
                      // Now we just show results automatically if filters change, so we might want to default to `true`
                      ? RecentSearchesView(
                          token: _token!,
                          onRecentSearchSelected: () {
                            // Empty for now since we removed search bar
                          },
                        )
                      // Show search results while user has typed something
                      : BlocBuilder<UserSearchBloc, UserSearchState>(
                          buildWhen: (previous, current) {
                            // Only rebuild for search-related states, not follow toggle states
                            return current is UserSearchInitial ||
                                current is UserSearchV2Loading ||
                                current is UserSearchV2Loaded ||
                                current is UserSearchV2Error ||
                                current is UserSearchV2Empty;
                          },
                          builder: (context, state) {
                            if (state is UserSearchV2Loading) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: SearchSkeletonLoader(),
                              );
                            }

                            if (state is UserSearchV2Loaded) {
                              // We removed client-side name search filtering as we no longer have a text field.
                              // We use the results direct from the API.
                              final professionals = state.users;

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
                                        _onFilterChanged();
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Initial state or any other state — show loading
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: SearchSkeletonLoader(),
                              ),
                            );
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
