import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/data/skin_condition/datasources/skin_condition_remote_datasource.dart';
import 'package:nepika/data/skin_condition/repositories/skin_condition_repository.dart';
import 'package:nepika/domain/skin_condition/usecases/get_skin_condition_details.dart';
import 'package:nepika/presentation/bloc/skin_condition/skin_condition_bloc.dart';
import 'package:nepika/presentation/bloc/skin_condition/skin_condition_event.dart';
import 'package:nepika/presentation/bloc/skin_condition/skin_condition_state.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/progress_summary_chart.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/section_header.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/skin_score_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SkinConditionDetailsPage extends StatefulWidget {
  const SkinConditionDetailsPage({super.key});

  @override
  State<SkinConditionDetailsPage> createState() => _SkinConditionDetailsPageState();
}

class _SkinConditionDetailsPageState extends State<SkinConditionDetailsPage> {
  String? token;
  Map<String, dynamic>? skinScore;
  String? conditionInfo;
  String? conditionSlug;
  bool _argumentsExtracted = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_argumentsExtracted) {
      // Extract navigation arguments
      final route = ModalRoute.of(context);
      final settings = route?.settings;
      final arguments = settings?.arguments as Map<String, dynamic>?;
      
      debugPrint('🔍 Route: $route');
      debugPrint('🔍 Settings: $settings');
      debugPrint('🔍 Settings name: ${settings?.name}');
      debugPrint('🔍 Raw navigation arguments: $arguments');
      
      if (arguments != null) {
        skinScore = arguments['skinScore'] as Map<String, dynamic>?;
        conditionInfo = arguments['conditionInfo'] as String?;
        
        // Extract condition slug from the conditionInfo
        conditionSlug = _getConditionSlug(conditionInfo);
        
        debugPrint('🔍 Received arguments: $arguments');
        debugPrint('🔍 skinScore: $skinScore');
        debugPrint('🔍 conditionInfo: $conditionInfo');
        debugPrint('🔍 conditionSlug: $conditionSlug');
        debugPrint('🔍 token: $token');
        
        _argumentsExtracted = true;
        
        // Trigger a rebuild since we now have the arguments
        if (mounted) {
          setState(() {});
        }
      } else {
        debugPrint('❌ No navigation arguments found!');
      }
    }
  }

  String? _getConditionSlug(String? conditionName) {
    if (conditionName == null) return null;
    
    // Convert display names to API slugs
    switch (conditionName.toLowerCase()) {
      case 'acne':
        return 'acne';
      case 'dry skin':
      case 'dry ':
        return 'dry ';
      case 'normal skin':
      case 'normal':
        return 'normal';
      case 'wrinkles':
      case 'wrinkle':
        return 'wrinkle';
      case 'dark circles':
      case 'dark_circles':
        return 'dark_circles';
      case 'pigmentation':
        return 'pigmentation';
      default:
        return conditionName.toLowerCase().replaceAll(' ', '_');
    }
  }

  double _getConditionPercentage() {
    if (skinScore == null || conditionInfo == null) {
      return 0.0;
    }
    
    // Try to get the percentage for the specific condition from latestConditionResult
    final latestConditionResult = skinScore?['latestConditionResult'] as Map<String, dynamic>?;
    if (latestConditionResult != null) {
      // Try the exact conditionInfo first
      if (latestConditionResult.containsKey(conditionInfo)) {
        final value = latestConditionResult[conditionInfo];
        if (value is num) {
          return value.toDouble();
        }
      }
      
      // Try the condition slug
      if (conditionSlug != null && latestConditionResult.containsKey(conditionSlug)) {
        final value = latestConditionResult[conditionSlug];
        if (value is num) {
          return value.toDouble();
        }
      }
    }
    
    return 0.0;
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedToken = prefs.getString(AppConstants.accessTokenKey);
    
    debugPrint('🔑 Token loaded: $loadedToken');
    
    if (mounted) {
      setState(() {
        token = loadedToken;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (token == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Debug - check if we have arguments first
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    debugPrint('🔍 Final check - arguments in build: $arguments');
    
    if (arguments == null) {
      // Show debug info if no arguments
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomBackButton(),
                const SizedBox(height: 20),
                Text(
                  'DEBUG INFO - No Arguments',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 20),
                Text('Token: ${token ?? 'null'}'),
                Text('Route Arguments: null'),
                const SizedBox(height: 20),
                Text('This screen was opened without proper navigation arguments.'),
                Text('Please navigate from the dashboard conditions section.'),
              ],
            ),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (context) {
        final apiBase = ApiBase();
        final dataSource = SkinConditionRemoteDataSourceImpl(apiBase);
        final repository = SkinConditionRepositoryImpl(dataSource);
        final useCase = GetSkinConditionDetails(repository);
        
        return SkinConditionBloc(useCase);
      },
      child: BlocConsumer<SkinConditionBloc, SkinConditionState>(
        listener: (context, state) {
          // This is where we can handle side effects if needed
        },
        builder: (context, state) {
          final theme = Theme.of(context);
          
          // Trigger API call when both token and conditionSlug are available
          if (conditionSlug != null && token != null && state is SkinConditionInitial) {
            debugPrint('✅ Triggering API call for condition: $conditionSlug');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<SkinConditionBloc>().add(
                SkinConditionDetailsRequested(
                  token: token!,
                  conditionSlug: conditionSlug!,
                ),
              );
            });
          }
          
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomBackButton(),
                    const SizedBox(height: 28),
                    
                    // Condition Name Title
                    Text(
                      'Skin Condition',
                      style: theme.textTheme.displaySmall
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Stay consistent. Mark each step as you complete it.',
                      style: theme.textTheme.headlineMedium?.secondary(context)
                    ),
                    const SizedBox(height: 25),
                    
                    // // Cards Row
                    Row(
                      children: [
                        // Current Percentage Card
                        Expanded(
                          child: Container(
                            height: 170,
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(alpha: 0.8),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state is SkinConditionLoaded
                                      ? state
                                            .skinConditionDetails
                                            .formattedConditionName
                                      : conditionInfo ?? 'Skin Condition',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 12),
                                if (state is SkinConditionLoading)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                else if (state is SkinConditionLoaded)
                                  Text(
                                    '${state.skinConditionDetails.currentPercentage.toStringAsFixed(1)}%',
                                    style: theme.textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 30,
                                      color: theme.textTheme.titleLarge?.primary(context).color,
                                    ),
                                  )
                                else if (state is SkinConditionError)
                                  Text(
                                    'Error',
                                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.red),
                                  )
                                else
                                  Text(
                                    '${_getConditionPercentage().toStringAsFixed(1)}%',
                                    style: theme.textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 30,
                                      color: theme.textTheme.titleLarge?.primary(context).color,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                // if (state is SkinConditionLoaded)
                                //   Text(
                                //     'Last updated: ${_formatDate(state.skinConditionDetails.lastUpdated)}',
                                //     style: theme.textTheme.bodySmall?.secondary(context),
                                //   ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Skin Score Card
                        Expanded(
                          child: SizedBox(
                            height: 170,
                            child: SkinScoreCard(skinScore: skinScore ?? {}),
                          ),
                        ),
                      ],
                    ),
                    
                    // const SizedBox(height: 30),
                    
                    // Progress Summary Section
                    SectionHeader(
                      heading: 'Progress Summary',
                      showButton: false,
                    ),
                    // const SizedBox(height: 16),
                    
                    _buildProgressChart(state)
                    // Expanded(
                    //   child: _buildProgressChart(state),
                    // ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressChart(SkinConditionState state) {
    if (state is SkinConditionLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is SkinConditionLoaded) {
      return ProgressSummaryChart(
        progressSummary: state.skinConditionDetails.progressSummary,
        height: 280,
        showPointsAndLabels: true,
      );
    } else if (state is SkinConditionError) {
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
              'Failed to load progress data',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium?.secondary(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (conditionSlug != null && token != null) {
                  context.read<SkinConditionBloc>().add(
                    SkinConditionDetailsRequested(
                      token: token!,
                      conditionSlug: conditionSlug!,
                    ),
                  );
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else {
      // Fallback to empty chart
      return ProgressSummaryChart(
        progressSummary: {},
        height: 280,
        showPointsAndLabels: true,
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}