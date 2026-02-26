import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/di/injection_container.dart';
import 'package:nepika/core/widgets/back_button.dart';
import '../../routine/widgets/sticky_header_delegate.dart';
import '../bloc/faq_bloc.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocProvider(
      create: (context) => ServiceLocator.get<FaqBloc>()..add(GetFaqsEvent()),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: BlocBuilder<FaqBloc, FaqState>(
            builder: (context, state) {
              if (state is FaqLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is FaqError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<FaqBloc>().add(GetFaqsEvent()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (state is FaqLoaded) {
                if (state.faqs.isEmpty) {
                   return CustomScrollView(
                    slivers: [
                      ..._buildHeaderSlivers(context),
                      SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No FAQs available yet.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                   );
                }
                
                // Because backend is not deployed, the API doesn't return the category column. 
                // We map it manually based on the exact question string to show categories in UI.
                
                final Map<String, String> categoryMap = {
                  "How do I set up my skincare profile?": "Getting Started",
                  "Can I update my skin type or onboarding details later?": "Getting Started",
                  "What’s the best way to get more accurate results from my skin analysis?": "Getting Started",
                  
                  "How often should I analyze my skin?": "Skin Tracking & Improvement",
                  "Why do my results vary each time?": "Skin Tracking & Improvement",
                  "Can I compare before-and-after progress?": "Skin Tracking & Improvement",

                  "How do I set or change my routine reminders?": "Reminders & Notifications",
                  "Can I turn off notifications?": "Reminders & Notifications",

                  "How are product recommendations selected?": "Products & Recommendations",
                  "Can I add my own skincare products?": "Products & Recommendations",
                  "Are the recommended solutions/products sponsored?": "Products & Recommendations",

                  "What data does the app collect?": "Privacy & Account",
                  "How can I delete my data or account?": "Privacy & Account",

                  "How can I engage with other users?": "Community & Support",
                  "Are there Professionals in the App?": "Community & Support",
                  "What if I experience irritation or a reaction?": "Community & Support",
                  "How can I contact support?": "Community & Support",
                };

                final groupedFaqs = <String, List<dynamic>>{};
                for (final faq in state.faqs) {
                  final category = faq.category ?? categoryMap[faq.question] ?? 'General';
                  groupedFaqs.putIfAbsent(category, () => []).add(faq);
                }

                return CustomScrollView(
                  slivers: [
                    ..._buildHeaderSlivers(context),
                    ...groupedFaqs.entries.map((entry) {
                      final category = entry.key;
                      final categoryFaqs = entry.value;

                      return SliverMainAxisGroup(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.only(left: 20, right: 20, top: 25, bottom: 8),
                            sliver: SliverToBoxAdapter(
                              child: Text(
                                category,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return _buildFaqItem(context, categoryFaqs[index]);
                                },
                                childCount: categoryFaqs.length,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHeaderSlivers(BuildContext context) {
    final theme = Theme.of(context);
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const CustomBackButton(),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
      SliverPersistentHeader(
        pinned: true,
        delegate: StickyHeaderDelegate(
          minHeight: 40,
          maxHeight: 40,
          isFirstHeader: true,
          title: "FAQ",
          child: Container(color: theme.scaffoldBackgroundColor),
        ),
      ),
    ];
  }
  
  Widget _buildFaqItem(BuildContext context, dynamic faq) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: ExpansionTile(
        shape: Border.all(color: Colors.transparent),
         collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          faq.question,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  faq.answer,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
