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
                    Text(
                      'This Privacy Policy describes how Nepika Creative Ltd ("we," "our," or "us"), a company registered in England and Wales with company number 16507702 and registered office at 20 Wenlock Road, London, N1 7GU, England, collects, uses, and protects your personal data when you visit and use our website. We are committed to protecting your privacy and complying with applicable data protection laws, including the General Data Protection Regulation (GDPR), the UK GDPR, and the Data Protection Act 2018. We are registered with the Information Commissioner\'s Office (ICO) under registration number ZB937756.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '1. Information We Collect',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We may collect the following types of personal data when you use our website:\n• Name and contact details (e.g., email address, phone number) if you submit them via our contact form.\n• Any information you include in messages or inquiries sent through our website forms.\n• Technical data such as your IP address, browser type, and pages visited.\n• Cookie and usage data collected through analytics tools (e.g., Google Analytics).',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '2. How We Use Your Information',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We use your personal data for the following purposes:\n• To respond to inquiries and communicate with you.\n• To analyze and improve our website and user experience.\n• To ensure website security and prevent misuse.\n• To comply with legal obligations.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '3. Legal Basis for Processing',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We process your personal data based on:\n• Your consent (e.g., when you submit a contact form).\n• Our legitimate interests in analyzing website performance and improving user experience.\n• Compliance with legal obligations where applicable.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '4. Cookies and Analytics',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our website uses cookies and similar technologies to enhance your browsing experience. We may use third-party analytics services, such as Google Analytics, which collect information about your use of our site. You can manage or disable cookies through your browser settings.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '5. Face Scan Data',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The app processes user-uploaded facial images to detect skin type and common concerns. The original image is processed in memory and not stored. An annotated version of the image and analysis results are securely stored on our AWS servers (S3 and RDS).\n\nWhat face data we collect:\n• A single facial image uploaded by the user for skin-analysis scan purposes only.\n• We do not collect or generate biometric identifiers such as face geometry, depth maps, face templates, or facial recognition data.\n\nHow face data is used:\n• To detect skin type, conditions, and concerns.\n• To generate personalized product and routine recommendations.\n• We do not use face data for identity verification, authentication, or tracking.\n\nWhere face data is stored:\n• Raw uploaded image: Processed in memory only and never stored.\n• Annotated image: Securely stored in AWS S3 (encrypted).\n• Scan results: Stored encrypted in AWS RDS (PostgreSQL).\n• All data is encrypted both in transit and at rest.\n\nFace data sharing:\n• We do not share raw images, annotated images, or analysis results with any third parties.\n• All processing takes place on our secured AWS infrastructure.\n\nData retention:\n• Annotated images and scan results are retained for up to 2 years.\n• Exception: If you delete your account, all associated data — including annotated S3 images and analysis results — is permanently deleted immediately.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '6. Data Retention',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We retain personal data only as long as necessary to respond to your inquiries or as required by law. Technical data and analytics may be stored for a limited time to monitor and improve website performance. For face scan data retention, please see Section 5 above.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '7. Account Deletion',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can delete your account at any time through the app:\nSettings → Delete Account → Select Reason → Confirm\n\nWhen you delete your account, the following happens immediately:\n• Your user account is permanently removed.\n• All scan results and analysis data are deleted from our database.\n• All annotated face images are deleted from AWS S3.\n• All linked records in our RDS database are permanently removed.\n\nThis deletion is immediate and irreversible. We do not retain any face scan data or personal information after account deletion.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '8. Your Rights',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Under the GDPR and UK GDPR, you have the right to:\n• Access, correct, or delete your personal data.\n• Object to or restrict the processing of your data.\n• Withdraw consent at any time.\n• Request data portability.\n• Lodge a complaint with a data protection authority.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '9. Data Security',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We implement appropriate technical and organizational measures to protect your personal data against unauthorized access, alteration, disclosure, or destruction.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '10. Third-Party Services',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We may use trusted third-party service providers to manage our website and analytics. These providers are bound by strict data protection obligations.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '11. Changes to This Privacy Policy',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We may update this Privacy Policy from time to time. Any changes will be posted on this page with an updated revision date.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '12. Contact Us',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If you have any questions or concerns about this Privacy Policy or how we handle your personal data, please contact us at:\n\nNepika Creative Ltd\n20 Wenlock Road\nLondon\nN1 7GU\nEngland\nEmail: info@nepika.com',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Last updated: July 2025',
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
}