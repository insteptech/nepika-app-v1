import 'package:flutter/material.dart';
import 'package:nepika/core/constants/theme.dart';

class ProductCard extends StatelessWidget {
  final String? imageUrl;
  final String brandName;
  final String productName;
  final String rating;
  final String maxRating;
  final bool showCheckmark;
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
                color: colorScheme.onTertiary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Product Image
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    // color: colorScheme.background,
                  ),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(context),
                            loadingBuilder: (context, child, loadingProgress) =>
                                loadingProgress == null ? child : _buildPlaceholderImage(context),
                          ),
                        )
                      : _buildPlaceholderImage(context),
                ),

                const SizedBox(width: 16),

                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Brand Name
                      Text(
                        brandName.toUpperCase(),
                        style: textTheme.bodyMedium!.secondary(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Product Name
                      Text(
                        productName,
                        style: textTheme.headlineMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Rating
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$rating/$maxRating',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          )
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkmark
                if (showCheckmark) ...[
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: onCheckmarkTap,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: colorScheme.surface,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceVariant,
      ),
      child: Icon(
        Icons.image_outlined,
        color: colorScheme.onSurfaceVariant,
        size: 24,
      ),
    );
  }
}
