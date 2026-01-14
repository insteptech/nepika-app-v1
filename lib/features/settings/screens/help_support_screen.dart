import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@nepika.com',
    );
    if (!await launchUrl(emailLaunchUri)) {
      debugPrint('Could not launch email client');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Help & Support',
          style: theme.textTheme.headlineMedium,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact Us',
                style: theme.textTheme.headlineMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoItem(
                context,
                title: 'Email',
                content: 'support@nepika.com',
                onTap: _launchEmail,
                showArrow: true,
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                context,
                title: 'Website',
                content: 'https://www.nepika.com',
                onTap: () => _launchUrl('https://www.nepika.com'),
                showArrow: true,
              ),
              const SizedBox(height: 32),
              Text(
                'Company Information',
                style: theme.textTheme.headlineMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoItem(
                context,
                title: 'Company Name',
                content: 'Nepika Creative Ltd',
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                context,
                title: 'Address',
                content: '20 Wenlock Road, London, N1 7GU, UK',
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                context,
                title: 'Registered in England',
                content: '16507702',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required String title,
    required String content,
    VoidCallback? onTap,
    bool showArrow = false,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: onTap != null ? theme.colorScheme.primary : null,
                    ),
                  ),
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.iconTheme.color?.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }
}