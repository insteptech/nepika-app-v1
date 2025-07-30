import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/constants/routes.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/data/dashboard/repositories/dashboard_repository.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/daily_routine.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/face_scan_card.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/greeting_section.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/image_gallery.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/progress_summary_chart.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/recomended_products.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/skin_score_card.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/section_header.dart';
import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../bloc/dashboard/dashboard_event.dart';
import '../../bloc/dashboard/dashboard_state.dart';

class DashboardPage extends StatelessWidget {
  final String token;
  final VoidCallback? onFaceScanTap;
  final void Function(String route)? onNavigate;

  const DashboardPage({
    Key? key,
    required this.token,
    this.onFaceScanTap,
    this.onNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc(
        DashboardRepository(
          ApiBase(),
        ),
      )..add(DashboardRequested(token)),
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          // Default values
          Map<String, dynamic> user = {};
          Map<String, dynamic> faceScan = {};
          Map<String, dynamic> skinScore = {};
          Map<String, dynamic> progressSummary = {};
          Map<String, dynamic> dailyRoutine = {};
          List<Map<String, dynamic>> imageGallery = [];
          List<Map<String, dynamic>> recommendedProducts = [];
          // List<Map<String, dynamic>> navigation = [];

          bool isLoading = state is DashboardLoading;
          bool isError = state is DashboardError;

          if (state is DashboardLoaded) {
            final dashboardData = state.dashboardData;
            user = dashboardData['user'] ?? {};
            faceScan = dashboardData['faceScan'] ?? {};
            skinScore = dashboardData['skinScore'] ?? {};
            progressSummary = dashboardData['progressSummary'] ?? {};
            dailyRoutine = dashboardData['dailyRoutine'] ?? {};
            imageGallery = List<Map<String, dynamic>>.from(
              dashboardData['imageGallery'] ?? [],
            );
            recommendedProducts = List<Map<String, dynamic>>.from(
              dashboardData['recommendedProducts'] ?? [],
            );
          }

          return PopScope(
            canPop: false, // Block back navigation
            child: Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<DashboardBloc>().add(
                      DashboardRequested(token),
                    );
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        
                        GreetingSection(user: user),



                        if (isError || isLoading) 
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                isLoading ? 'Loading...' : 'Failed to load dashboard data',
                                style: Theme.of(context).textTheme.labelSmall
                              ),
                            ),
                          ),

                        isError || isLoading
                            ? const SizedBox(height: 10)
                            : const SizedBox(height: 30),

                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 170,
                                child: FaceScanCard(
                                  faceScan: faceScan,
                                  onTap: onFaceScanTap,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                height: 170,
                                child: SkinScoreCard(skinScore: skinScore),
                              ),
                            ),
                          ],
                        ),

                        SectionHeader(
                          heading: 'Progress Summary',
                          showButton: false,
                        ),

                        ProgressSummaryChart(
                                progressSummary: progressSummary,
                                height: 280,
                              ),

                        SectionHeader(
                          heading: 'Daily Routine',
                          showButton: true,
                          buttonText: 'View all',
                          onButtonPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.dashboardTodaysRoutine);
                          },
                          buttonLoading: isLoading,
                        ),


                       DailyRoutineSection(dailyRoutine: dailyRoutine),

                        
                        SectionHeader(
                          heading: 'Image Gallery',
                          showButton: true,
                          buttonText: 'View all',
                          onButtonPressed: () {
                            if (onNavigate != null) {
                              onNavigate!('/image_gallery');
                            }
                          },
                          buttonLoading: isLoading,
                        ),

                        
                        ImageGallerySection(imageGallery: imageGallery),

                        SectionHeader(
                          heading: 'Recommend Products',
                          showButton: true,
                          buttonText: 'View all',
                          onButtonPressed: () {
                           Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.dashboardAllProducts);
                          },
                          buttonLoading: isLoading,
                        ),
                        
                        RecommendedProductsSection(
                          products: recommendedProducts,
                          scrollDirection: Axis.horizontal,
                          showTag: true,
                        ),
                        


                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
