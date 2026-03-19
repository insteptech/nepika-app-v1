import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/di/injection_container.dart';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/core/utils/shared_prefs_helper.dart';
import '../../routine/widgets/sticky_header_delegate.dart';
import '../bloc/faq_bloc.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  late final FaqBloc _bloc;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bloc = ServiceLocator.get<FaqBloc>();
    _init();
  }

  Future<void> _init() async {
    // Ensure SharedPreferences is fully loaded before reading the professional flag
    await SharedPrefsHelper.init();
    final isProfessional = SharedPrefsHelper().isSkincareProfessionalSync();
    final targetAudience = isProfessional ? 'professional' : 'general';
    _bloc.add(GetFaqsEvent(targetAudience: targetAudience));
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: !_ready
              ? const Center(child: CircularProgressIndicator())
              : BlocBuilder<FaqBloc, FaqState>(
                  builder: (context, state) {
                    if (state is FaqLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is FaqError) {
                      final isPro = SharedPrefsHelper().isSkincareProfessionalSync();
                      final audience = isPro ? 'professional' : 'general';
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
                              onPressed: () => context.read<FaqBloc>().add(GetFaqsEvent(targetAudience: audience)),
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

                      // Group by category — API now always returns category field
                      final groupedFaqs = <String, List<dynamic>>{};
                      for (final faq in state.faqs) {
                        final category = faq.category ?? 'General';
                        groupedFaqs.putIfAbsent(category, () => []).add(faq);
                      }

                      // Sort each group by display_order (already sorted by backend, but defensive)
                      for (final list in groupedFaqs.values) {
                        list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
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
