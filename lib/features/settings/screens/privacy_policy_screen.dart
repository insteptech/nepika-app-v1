import 'package:flutter/material.dart';
import 'package:nepika/core/widgets/back_button.dart';
import '../../routine/widgets/sticky_header_delegate.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25),
                    
                    // Header Information
                    Text(
                      'Nepika Creative Ltd, 20 Wenlock Road, London, N1 7GU, UK\n\nRegistered in England 16507702\n\nData Protection ICO: ZB937756',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nepika ("we," "our," "us") provides AI-powered insights and tools that use computer vision, emotional analysis, and content generation technology. Your privacy is central to how we design our systems. This Privacy Policy explains what information we collect, how we use it, how we protect it, and the choices you have.\n\nThis Privacy Policy applies to the Nepika mobile application, website, and any related services ("Services").',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Section 1
                    _buildSectionTitle(textTheme, colorScheme, '1. Information We Collect'),
                    const SizedBox(height: 8),
                    Text(
                      'We collect the following categories of information to provide and improve our Services.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildSubsectionTitle(textTheme, colorScheme, '1.1 Information You Provide'),
                    const SizedBox(height: 8),
                    Text(
                      '• Name\n• Email address or phone number\n• Account credentials\n• Profile information you voluntarily submit\n• Support communication content\n\nWe do not require sensitive personal identifiers unless explicitly needed for a feature.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildSubsectionTitle(textTheme, colorScheme, '1.2 Automatically Collected Information'),
                    const SizedBox(height: 8),
                    Text(
                      '• Device type, OS, unique identifiers\n• IP address and approximate location\n• Usage logs, crash data, performance data\n• Interaction patterns (buttons clicked, session length, etc.)\n\nThis helps improve stability, reliability, and performance.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildSubsectionTitle(textTheme, colorScheme, '1.3 Face Data & Biometric Processing'),
                    const SizedBox(height: 8),
                    Text(
                      'Nepika provides features that use temporary facial analysis to generate insights. We treat facial information with the highest level of protection.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildSubSubsectionTitle(textTheme, colorScheme, '1.3.1 What Face Data We Process'),
                    Text(
                      '• Temporary image frames from your device camera\n• Temporary facial landmarks, expressions, or attributes extracted by the model\n\nWe do NOT collect or create:\n• Faceprints\n• Biometric identifiers\n• Identity recognition templates\n• Any persistently stored facial profiles',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildSubSubsectionTitle(textTheme, colorScheme, '1.3.2 Face Data Is Not Retained'),
                    Text(
                      'All face data is processed ephemerally (real-time only) and is never stored on our servers or on your device after processing.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildSubSubsectionTitle(textTheme, colorScheme, '1.3.3 Why We Process Face Data'),
                    Text(
                      'Face data is processed solely to:\n• Generate instant insights related to appearance, emotional state, or content enhancement\n• Display results back to the user immediately\n\nFace data is never used for identification, authentication, surveillance, tracking, advertising, or profiling.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildSubSubsectionTitle(textTheme, colorScheme, '1.3.4 Retention Duration'),
                    Text(
                      'We retain zero biometric data. Data is discarded immediately after in-session processing.\n\nIf a feature optionally supports sending anonymized numerical metrics for model improvement (disabled by default):\n• These values cannot reverse-engineer a face.\n• Users may opt out and delete this data anytime.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildSubSubsectionTitle(textTheme, colorScheme, '1.3.5 Third-Party Processors for Face Data'),
                    Text(
                      'We do not share raw face data with advertisers, analytics companies, or unrelated partners. If facial analysis requires remote compute, we may use a secure cloud processor such as AWS, Google Cloud, Azure, or our own inference servers.\n\nThese providers:\n• Only process image frames in real time\n• Are contractually prohibited from storing face data\n• Delete data immediately after producing results',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildSubSubsectionTitle(textTheme, colorScheme, '1.3.6 Do Third Parties Store Face Data?'),
                    Text(
                      'No. Third-party processors used by Nepika do not store, retain, or reuse face data.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Section 2
                    _buildSectionTitle(textTheme, colorScheme, '2. How We Use Your Information'),
                    const SizedBox(height: 8),
                    Text(
                      'We use collected information to:\n• Provide and personalize the app experience\n• Run AI models and generate insights\n• Improve reliability, performance, and features\n• Maintain account security\n• Communicate updates, offers, or important notices\n• Prevent fraud and enforce policies\n• Comply with legal obligations\n\nWe do not sell your personal data.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Section 3
                    _buildSectionTitle(textTheme, colorScheme, '3. Sharing of Information'),
                    const SizedBox(height: 8),
                    Text(
                      'We only share information when necessary.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildSubsectionTitle(textTheme, colorScheme, '3.1 Service Providers'),
                    const SizedBox(height: 8),
                    Text(
                      'Trusted partners who help us operate:\n• Cloud hosting\n• Storage\n• Analytics\n• Customer support\n• Security\n\nAll partners are contractually bound to:\n• Use information strictly for service delivery\n• Not sell or misuse your data\n• Comply with strict privacy and security controls',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildSubsectionTitle(textTheme, colorScheme, '3.2 Legal Compliance'),
                    const SizedBox(height: 8),
                    Text(
                      'We may share information to comply with:\n• Applicable laws\n• Lawful legal requests\n• Protection of rights, safety, and security\n\nWe do not provide biometric data to law enforcement because we do not store any.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Section 4
                    _buildSectionTitle(textTheme, colorScheme, '4. Data Storage & Retention'),
                    const SizedBox(height: 16),
                    
                    _buildSubsectionTitle(textTheme, colorScheme, '4.1 Personal Data'),
                    const SizedBox(height: 8),
                    Text(
                      'Account and service data are stored only as long as required to:\n• Provide the service\n• Comply with regulations\n• Resolve disputes',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildSubsectionTitle(textTheme, colorScheme, '4.2 Face Data'),
                    const SizedBox(height: 8),
                    Text(
                      'Face data is stored 0 seconds. It is processed in real time and immediately deleted.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildSubsectionTitle(textTheme, colorScheme, '4.3 Deletion Controls'),
                    const SizedBox(height: 8),
                    Text(
                      'Users may request deletion of:\n• Account data\n• Optional non-biometric analytics data\n• Communication data\n\nDeletion requests are processed within 30 days.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Section 5
                    _buildSectionTitle(textTheme, colorScheme, '5. Security'),
                    const SizedBox(height: 8),
                    Text(
                      'We implement industry-standard security measures, including:\n• Encryption in transit and at rest\n• Role-based access controls\n• Strict data-access auditing\n• No storage of biometric identifiers\n• Continuous monitoring and updates',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Section 6
                    _buildSectionTitle(textTheme, colorScheme, '6. Children\'s Privacy'),
                    const SizedBox(height: 8),
                    Text(
                      'Nepika is not intended for children under 18. We do not knowingly collect personal data from children.\n\nIf a parent believes a child has provided data, contact us for immediate deletion.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Section 7
                    _buildSectionTitle(textTheme, colorScheme, '7. International Users'),
                    const SizedBox(height: 8),
                    Text(
                      'We comply with global data regulations such as:\n• GDPR (EU)\n• UK GDPR\n• CCPA/CPRA (California)\n• India DPDP Act (2023)\n\nYour information may be processed in locations where we or our providers operate.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Section 8
                    _buildSectionTitle(textTheme, colorScheme, '8. Your Rights'),
                    const SizedBox(height: 8),
                    Text(
                      'Depending on your region, you may have rights to:\n• Access your data\n• Correct inaccuracies\n• Request deletion\n• Opt out of marketing\n• Withdraw consent for facial processing\n• Export your data\n• File complaints with regulators\n\nContact us to exercise these rights.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Section 9
                    _buildSectionTitle(textTheme, colorScheme, '9. Third-Party Links'),
                    const SizedBox(height: 8),
                    Text(
                      'Some features may link to third-party websites. We are not responsible for their privacy practices.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Section 10
                    _buildSectionTitle(textTheme, colorScheme, '10. Changes to This Policy'),
                    const SizedBox(height: 8),
                    Text(
                      'We may update this Privacy Policy periodically. Significant changes will be communicated via in-app notices or email.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Section 11
                    _buildSectionTitle(textTheme, colorScheme, '11. Contact Us'),
                    const SizedBox(height: 8),
                    Text(
                      'Nepika Privacy Team\nEmail: support@nepika.com\nWebsite: https://www.nepika.com',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    Text(
                      'Last Updated: December 2025',
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
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

  Widget _buildSectionTitle(TextTheme textTheme, ColorScheme colorScheme, String title) {
    return Text(
      title,
      style: textTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSubsectionTitle(TextTheme textTheme, ColorScheme colorScheme, String title) {
    return Text(
      title,
      style: textTheme.titleSmall?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSubSubsectionTitle(TextTheme textTheme, ColorScheme colorScheme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}