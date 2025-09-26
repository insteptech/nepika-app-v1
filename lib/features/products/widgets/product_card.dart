import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme.dart';

class ProductCard extends StatelessWidget {
  final String? imageUrl;
  final String brandName;
  final String productName;
  final String rating;
  final String maxRating;
  final bool showCheckmark;
  final bool isSelected;
  final bool isToggling;
  final VoidCallback? onTap;
  final VoidCallback? onCheckmarkTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const ProductCard({
    super.key,
    this.imageUrl,
    required this.brandName,
    required this.productName,
    required this.rating,
    this.maxRating = '100',
    this.showCheckmark = true,
    this.isSelected = false,
    this.isToggling = false,
    this.onTap,
    this.onCheckmarkTap,
    this.width,
    this.height,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProductImage(colorScheme),
                const SizedBox(width: 16),
                _buildProductDetails(textTheme, context),
                const SizedBox(width: 12),
                if (showCheckmark) _buildCheckmark(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(ColorScheme colorScheme) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderIcon(colorScheme, Icons.image_not_supported);
                },
              )
            : _buildPlaceholderIcon(colorScheme, Icons.image),
      ),
    );
  }

  Widget _buildPlaceholderIcon(ColorScheme colorScheme, IconData icon) {
    return Container(
      color: colorScheme.surface,
      child: Icon(
        icon,
        color: colorScheme.onSurface.withValues(alpha: 0.5),
        size: 30,
      ),
    );
  }

  Widget _buildProductDetails(TextTheme textTheme, BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBrandName(textTheme, context),
          const SizedBox(height: 4),
          _buildProductName(textTheme),
          const SizedBox(height: 8),
          _buildRatingBadge(textTheme),
        ],
      ),
    );
  }

  Widget _buildBrandName(TextTheme textTheme, BuildContext context) {
    return Text(
      brandName,
      style: textTheme.bodySmall!.secondary(context),
    );
  }

  Widget _buildProductName(TextTheme textTheme) {
    return Text(
      productName,
      style: textTheme.bodyLarge,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildRatingBadge(TextTheme textTheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: _getRatingColor(rating).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$rating/$maxRating',
            style: textTheme.bodySmall!.copyWith(
              color: _getRatingColor(rating),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckmark(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: isToggling ? null : onCheckmarkTap,
      child: Container(
        width: 22,
        height: 22,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          border: Border.all(
            color: colorScheme.primary,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: _buildCheckmarkContent(colorScheme),
      ),
    );
  }

  Widget? _buildCheckmarkContent(ColorScheme colorScheme) {
    if (isToggling) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      );
    } else if (isSelected) {
      return const Icon(
        Icons.check,
        color: Colors.white,
        size: 14,
      );
    }
    return null;
  }

  Color _getRatingColor(String rating) {
    final ratingValue = int.tryParse(rating) ?? 0;
    if (ratingValue >= 80) {
      return const Color(0xFF22C55E); // Green
    } else if (ratingValue >= 60) {
      return const Color(0xFFFFA500); // Orange
    } else {
      return const Color(0xFFEF4444); // Red
    }
  }
}