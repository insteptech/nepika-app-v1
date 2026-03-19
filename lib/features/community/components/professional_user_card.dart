import 'package:flutter/material.dart';
import '../../../../core/config/constants/routes.dart';
import '../../../../core/services/recent_searches_service.dart';
import '../../../../domain/community/entities/community_entities.dart';

/// A card that displays a skincare professional user in the style matching the
/// design mockup, with name, clinic, country, qualifications, specialties, and
/// action buttons for Contact / Email.
class ProfessionalUserCard extends StatelessWidget {
  final UserSearchResultEntity user;
  final VoidCallback? onContact;
  final VoidCallback? onEmail;
  final VoidCallback? onTap;

  const ProfessionalUserCard({
    super.key,
    required this.user,
    this.onContact,
    this.onEmail,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE8E8E8);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B6B6B);
    final primaryColor = theme.colorScheme.primary;

    final profileUrl = user.profileImageUrl ?? '';
    final hasAvatar = profileUrl.isNotEmpty;

    return GestureDetector(
      onTap: () async {
        onTap?.call();
        // Save to recent searches (same as user_search_card pattern)
        await RecentSearchesService.saveRecentSearch(user);
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pushNamed(
            AppRoutes.communityUserProfile,
            arguments: {'userId': user.id},
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: avatar + name/clinic/country ──────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: primaryColor.withValues(alpha: 0.12),
                  backgroundImage: hasAvatar ? NetworkImage(profileUrl) : null,
                  child: !hasAvatar
                      ? Text(
                          user.username.isNotEmpty
                              ? user.username[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + verified badge
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.username,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified, size: 16, color: primaryColor),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Clinic / bio
                      Text(
                        user.salonBusinessName?.isNotEmpty == true
                            ? user.salonBusinessName!
                            : 'Skincare Professional',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Country indicator
                      Row(
                        children: [
                          const Text('🌍', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.country?.isNotEmpty == true
                                  ? user.country!
                                  : 'Verified Expert',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Qualification row ────────────────────────────────────────────
            if (user.qualifications?.isNotEmpty == true) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.school_outlined, size: 16, color: textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      user.qualifications!.join('  ·  '),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ] else ...[
              Row(
                children: [
                  Icon(Icons.school_outlined, size: 16, color: textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Qualified Skincare Professional',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // ── Specialties row ──────────────────────────────────────────────
            if (user.skinConcernsTreated != null && user.skinConcernsTreated!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome_outlined, size: 16, color: textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      user.skinConcernsTreated!.map((s) {
                        return s.replaceAll('-', '_').split('_').map((w) {
                          if (w.isEmpty) return '';
                          return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
                        }).join(' ');
                      }).join('  ·  '),
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ] else ...[
              Row(
                children: [
                  Icon(Icons.auto_awesome_outlined, size: 16, color: textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Acne  ·  Ageing  ·  Pigmentation',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // ── Disclaimer ───────────────────────────────────────────────────
            Text(
              'Location details provided when you contact this professional',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 14),

            // ── Action buttons ───────────────────────────────────────────────
            Row(
              children: [
                // Contact button (filled)
                Expanded(
                  child: GestureDetector(
                    onTap: onContact,
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_outlined, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          const Text(
                            'Contact',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Email button (outlined)
                Expanded(
                  child: GestureDetector(
                    onTap: onEmail,
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: primaryColor),
                      ),
                      child: Center(
                        child: Text(
                          'Email',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
