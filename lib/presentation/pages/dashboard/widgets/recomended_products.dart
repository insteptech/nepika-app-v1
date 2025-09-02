import 'package:flutter/material.dart';
import 'package:nepika/presentation/pages/dashboard/product_info.dart';

class RecommendedProductsSection extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final bool isLoading;
  final Axis scrollDirection;
  final bool showTag; // true = show tag, false = show tick icon

  const RecommendedProductsSection({
    required this.products,
    this.isLoading = false,
    this.scrollDirection = Axis.horizontal,
    this.showTag = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading || products.isEmpty) {
      return scrollDirection == Axis.horizontal
          ? _buildSkeletonLoaderHorizontal()
          : _buildSkeletonLoaderVertical();
    }

    return SizedBox(
      height: scrollDirection == Axis.horizontal ? 140 : null,
      child: scrollDirection == Axis.horizontal
          ? PageView.builder(
              controller: PageController(viewportFraction: 0.96),
              itemCount: products.length,
              padEnds: false,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductCard(product, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductInfoPage(
                        productId: product['id'] ?? 'Unknown',
                      ),
                    ),
                  );
                });
              },
            )
          : ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildProductCard(product, () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductInfoPage(
                          productId: product['id'] ?? 'Unknown',
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, VoidCallback onTap) {
    final padding = scrollDirection == Axis.horizontal
        ? const EdgeInsets.only(right: 10)
        : EdgeInsets.zero;

    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;
        return Padding(
          padding: padding,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.onTertiary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product['imageUrl'] ?? '',
                      width: 80,
                      height: 90,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 90,
                          height: 90,
                          color: colorScheme.surfaceVariant,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.image_not_supported,
                            color: colorScheme.onSurfaceVariant,
                            size: 30,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Product Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          product['name'] ?? 'Product Name',
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Score Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondary,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                "${product['score'] ?? '0'}/100",
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Tag or Tick Icon
                            showTag
                                ? Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: colorScheme.primary,
                                        ),
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      child: Text(
                                        product['tag'] ?? 'Tag',
                                        style: textTheme.bodyLarge?.copyWith(
                                          color: colorScheme.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.check_circle,
                                    color: colorScheme.primary,
                                    size: 24,
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLoaderHorizontal() {
    return SizedBox(
      height: 140,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.96),
        itemCount: 3,
        padEnds: false,
        itemBuilder: (context, index) {
          return _buildSkeletonCard();
        },
      ),
    );
  }

  Widget _buildSkeletonLoaderVertical() {
    return ListView.builder(
      itemCount: 3,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSkeletonCard(),
        );
      },
    );
  }

  Widget _buildSkeletonCard() {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildShimmerEffect(),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _buildShimmerEffect(),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _buildShimmerEffect(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: _buildShimmerEffect(),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 80,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: _buildShimmerEffect(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerEffect() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return AnimatedBuilder(
          animation: AlwaysStoppedAnimation(value),
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.grey[300]!,
                    Colors.grey[100]!,
                    Colors.grey[300]!,
                  ],
                  stops: [
                    (value - 0.3).clamp(0.0, 1.0),
                    value.clamp(0.0, 1.0),
                    (value + 0.3).clamp(0.0, 1.0),
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        );
      },
    );
  }
}
