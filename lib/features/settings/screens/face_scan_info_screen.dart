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
                      title: 'How the Scan Works',
                      content: 'When you upload your photo, our AI examines your facial features to identify your skin type and detect common skin concerns. The system compares patterns in your photo with patterns learned from thousands of real skin images.\n\nThe scan looks at texture, color variations, pore visibility, shine levels, and irregularities to understand what\'s happening on your skin.',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context,
                      title: 'What the Scan Detects',
                      content: '1. Skin Conditions (10 Types)\n\nThe scan checks for these conditions individually:\n• Acne\n• Wrinkles\n• Dark spots\n• Dry skin\n• Enlarged pores\n• Eyebags\n• Oily skin\n• Redness\n• Blackheads\n• Whiteheads\n\nEach condition is analyzed separately and assigned its own confidence score.\n\n2. Skin Type (5 Categories)\n\nYour overall skin type is estimated based on oiliness, texture, moisture patterns, and light reflection:\n• Normal\n• Oily\n• Dry\n• Combination\n• Sensitive\n\nYou\'ll also see a confidence score for your predicted skin type.\n\n3. Area-Specific Detection\n\nThe system doesn\'t just tell you what is present — it also shows you where:\n• Boundaries around detected areas\n• Multiple instances of the same concern (e.g., several acne spots)\n• Visual highlights to help you understand exact problem zones\n\nThese locations help generate more accurate product and routine recommendations.\n\n4. Complete Skin Health Summary\n\nYour final result includes:\n• Each detected condition + confidence score\n• Your predicted skin type + confidence score\n• Count of total detected issues\n• Annotated image with highlights of each detected area\n\nThis gives you a clear, visual overview of your skin\'s current condition.',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context,
                      title: 'How Your Skin Score Is Calculated',
                      content: 'Your face image is analyzed across multiple skin concerns, such as:\n• Acne\n• Enlarged pores\n• Dark spots or pigmentation\n• Wrinkles\n• Redness or similar issues\n\nEach concern gets a "severity percentage."\nExample: Acne = 25%, Pores = 40%, Wrinkles = 15%, etc.\n\nWe add up all the detected severity percentages. This gives a total "skin issues score."\n\nYour final Skin Score is calculated as:\nSkin Score = 100 – (Total severity of all detected issues)\n\n• If your total issues are low → your score goes higher\n• If your issues are high → your score goes lower\n\nWe make sure the final score never goes below 0.',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context,
                      title: 'Understanding Confidence Scores',
                      content: 'A confidence score shows how sure the AI is about each detection.\n\nScore Meaning:\n\n80–100% → Very High Confidence\nStrong match to the condition. Likely accurate.\n\n60–79% → Moderate Confidence\nGood match, but lighting/angle may influence accuracy.\n\n40–59% → Low Confidence\nPossible presence, but not certain. Treat as a caution.\n\n10–39% → Very Low Confidence\nWeak pattern. Consider re-scanning with better lighting.\n\nBelow 10%\nAutomatically ignored for area detection.\n\nConfidence exists because skin features can change based on lighting, angles, dryness, or makeup.',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context,
                      title: 'What Affects Accuracy',
                      content: 'For the best results, the AI needs a clear and well-lit face. Accuracy is influenced by:\n\n• Lighting (even lighting works best)\n• Whether your face is centered\n• Image resolution and sharpness\n• Makeup or filters\n• Shadows across the face\n• Wet or shiny skin\n• Camera distance and angle\n\nThe better the image quality, the more reliable the scores.',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context,
                      title: 'How the Scan Processes Your Image',
                      content: '1. Image Quality Check\nEnsures your photo is bright, clear, and within acceptable size and format.\n\n2. Face Detection\nIdentifies your face and isolates the region needed for analysis.\n\n3. Skin Type Analysis\nEvaluates texture and overall facial patterns to estimate your skin type.\n\n4. Skin Condition Detection\nSearches for the 10 possible skin concerns across your face.\n\n5. Area Localization\nHighlights where each concern appears and groups similar detections.\n\n6. Result Generation\nCombines everything into a clear report with scores and recommendations.\n\nTypical processing time: 8–12 seconds.',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context,
                      title: 'Limitations You Should Know',
                      content: 'Our AI is highly capable but not perfect:\n\n• It cannot diagnose medical conditions\n• Harsh or uneven lighting can impact the results\n• Some conditions may overlap visually\n• Not suitable for detecting serious skin diseases\n• Best used as guidance, not medical advice\n\nIf you have worsening or persistent issues, consult a dermatologist.',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context,
                      title: 'Your Data & Privacy',
                      content: 'We take your privacy seriously:\n\n• Original photos are processed securely and not permanently stored\n• Only your annotated results are saved for your history\n• You can delete your scan data anytime\n• Your data is never shared with anyone without your consent',
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
                            'Face scan results are for informational purposes only and do not constitute medical advice, diagnosis, or treatment. Our AI is highly capable but not perfect. Always consult qualified healthcare professionals for medical concerns or persistent skin issues.',
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