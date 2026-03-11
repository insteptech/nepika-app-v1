import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/core/widgets/loading_widget.dart';
import '../../../../core/di/injection_container.dart';
import '../../routine/widgets/sticky_header_delegate.dart';
import '../bloc/legal/legal_cubit.dart';
import '../bloc/legal/legal_state.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LegalCubit>()..loadLegalDocument('privacy'),
      child: const _PrivacyPolicyView(),
    );
  }
}

class _PrivacyPolicyView extends StatelessWidget {
  const _PrivacyPolicyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    CustomBackButton(),
                    SizedBox(height: 15),
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
                title: "Privacy Policy",
                child: Container(
                  color: theme.scaffoldBackgroundColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Privacy Policy",
                    style: textTheme.displaySmall,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: BlocBuilder<LegalCubit, LegalState>(
                  builder: (context, state) {
                    if (state is LegalLoading || state is LegalInitial) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 50.0),
                        child: Center(child: LoadingWidget()),
                      );
                    } else if (state is LegalError) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 50.0),
                        child: Center(
                          child: Text(
                            state.message,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      );
                    } else if (state is LegalLoaded) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 25),
                          MarkdownBody(
                            data: state.document.content
                                .replaceAll('<br>', '\n\n&nbsp;\n\n')
                                .replaceAll('<br/>', '\n\n&nbsp;\n\n'),
                            extensionSet: md.ExtensionSet.gitHubWeb,
                            styleSheet: MarkdownStyleSheet(
                              blockSpacing: 16.0,
                              p: textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                                height: 1.6,
                              ),
                              h1: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              h2: textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              h3: textTheme.titleSmall?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                              h4: textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              listBullet: TextStyle(color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'Last Updated: ${state.document.updatedAt.toLocal().toString().split(' ')[0]}',
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}