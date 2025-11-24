import 'package:flutter/material.dart';
import 'package:nepika/core/widgets/back_button.dart';
import '../../routine/widgets/sticky_header_delegate.dart';

class FaceScanInfoScreen extends StatelessWidget {
  const FaceScanInfoScreen({super.key});

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
                title: "Face Scan Info",
                child: Container(
                  color: theme.scaffoldBackgroundColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Face Scan Info",
                    style: textTheme.displaySmall,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25),
                    _buildInfoCard(
                      context,
                      title: 'How Face Scan Works',
                      content: 'Our advanced AI technology analyzes your facial features to identify skin conditions, type, and areas of concern. The scan uses machine learning models trained on thousands of images to provide accurate assessments of your skin health.',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context,
                      title: 'Scoring & Analysis',
                      content: 'Confidence scores range from 0-100%, indicating how certain our AI is about detected conditions. Higher scores mean more reliable detections. The system analyzes:\n\n• Skin conditions (acne, wrinkles, dark spots, etc.)\n• Skin type (normal, oily, dry, combination, sensitive)\n• Area-specific detections with bounding boxes\n• Overall skin health assessment',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context,
                      title: 'Processing Details',
                      content: 'Analysis typically takes 8-12 seconds and involves:\n\n1. Image quality assessment for adequate lighting\n2. Face detection and feature mapping\n3. Multi-model analysis for different skin aspects\n4. Confidence calculation and result compilation\n5. Personalized recommendation generation',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context,
                      title: 'Data Storage & Privacy',
                      content: 'Your scan data is handled with utmost care:\n\n• Images are processed securely and deleted after analysis\n• Scan results are stored for 2 years to track progress\n• Personal data is encrypted and stored on secure servers\n• You can delete your scan history anytime in settings\n• Data is never shared without explicit consent',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context,
                      title: 'Accuracy & Limitations',
                      content: 'While our AI is highly advanced, please note:\n\n• Results are for informational purposes only\n• Not a substitute for professional medical advice\n• Accuracy depends on image quality and lighting\n• Some conditions may require dermatologist consultation\n• Best results achieved with front-facing, well-lit photos',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context,
                      title: 'Technology Behind the Scan',
                      content: 'Our face scan technology uses:\n\n• Google ML Kit for face detection\n• Custom-trained neural networks for skin analysis\n• Multi-stage processing pipeline\n• Real-time image quality assessment\n• Advanced computer vision algorithms\n• Continuous model improvements based on research',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context,
                      title: 'Using Your Results',
                      content: 'Make the most of your scan results:\n\n• Track changes over time in your scan history\n• Follow personalized product recommendations\n• Use insights to adjust your skincare routine\n• Share results with skincare professionals if needed\n• Set reminders for regular skin assessments',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Important Disclaimer',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Face scan results are for educational and informational purposes only. They do not constitute medical advice, diagnosis, or treatment. Always consult qualified healthcare professionals for medical concerns or before making significant changes to your skincare routine.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String content,
    required ThemeData theme,
  }) {
    return Container(
      width: double.infinity,
      // padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(
        //   color: theme.colorScheme.outline.withValues(alpha: 0.2),
        //   width: 1,
        // ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}