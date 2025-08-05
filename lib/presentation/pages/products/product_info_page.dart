import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/constants/theme.dart';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/core/widgets/custom_button.dart';
import 'package:nepika/data/products/datasources/products_remote_datasource_impl.dart';
import 'package:nepika/data/products/repositories/products_repository_impl.dart';
import 'package:nepika/domain/products/usecases/get_my_products.dart';
import 'package:nepika/domain/products/usecases/get_product_info.dart';
import 'package:nepika/presentation/bloc/products/products_bloc.dart';
import 'package:nepika/presentation/bloc/products/products_event.dart';
import 'package:nepika/presentation/bloc/products/products_state.dart';

class ProductInfoPage extends StatefulWidget {
  final String productId;
  const ProductInfoPage({super.key, required this.productId});

  @override
  State<ProductInfoPage> createState() => _ProductInfoPageState();
}

class _ProductInfoPageState extends State<ProductInfoPage> {
  final String token = '';
  late final String productId;

  @override
  void initState() {
    super.initState();
    productId = widget.productId;
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'moderate':
        return const Color(0xFFFFD748);
      case 'low':
      default:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  String _getScoreText(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    if (productId.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: Text("Product ID missing"),
        ),
      );
    }

    return BlocProvider(
      create: (context) {
        final apiBase = ApiBase();
        final dataSource = ProductsRemoteDataSourceImpl(apiBase);
        final repository = ProductsRepositoryImpl(dataSource);
        final getProductInfoUseCase = GetProductInfo(repository);
        
        return ProductsBloc(
          getMyProductsUseCase: GetMyProducts(repository),
          getProductInfoUseCase: getProductInfoUseCase,
        )..add(GetProductInfoRequested(token: token, productId: productId));
      },
      child: BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) {
          bool isLoading = state is ProductInfoLoading;
          Map<String, dynamic> productInfo = {};

          if (state is ProductInfoLoaded) {
            final product = state.productInfo;
            productInfo = {
              'id': product.id,
              'name': product.name,
              'brand_name': product.brandName,
              'imageUrl': product.imageUrl,
              'score': product.score,
              'ingredients': product.ingredients,
              ...product.details,
            };
          }

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(children: [
                      const CustomBackButton(),
                    ]),
                  ),
                  if (isLoading)
                    Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 32),
                            // Product Image
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Theme.of(context).colorScheme.surface,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: productInfo['imageUrl'] != null
                                    ? Image.network(
                                        productInfo['imageUrl'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.image_not_supported,
                                            size: 60,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.5),
                                          );
                                        },
                                      )
                                    : Icon(
                                        Icons.image,
                                        size: 60,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.5),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Brand Name
                            Text(
                              productInfo['brand_name'] ?? 'Unknown Brand',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .secondary(context),
                            ),
                            const SizedBox(height: 8),
                            // Product Name
                            Text(
                              productInfo['name'] ?? 'Unknown Product',
                              style: Theme.of(context).textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            // Score
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Score: ${productInfo['score'] ?? 0}/100',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Ingredients Section
                            if (productInfo['ingredients'] != null &&
                                (productInfo['ingredients'] as List).isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ingredients',
                                    style: Theme.of(context).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  ...((productInfo['ingredients'] as List)
                                      .map((ingredient) => Container(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.2),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        ingredient['name'] ?? '',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge,
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: _getRiskColor(
                                                                ingredient[
                                                                        'riskLevel'] ??
                                                                    'low')
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        ingredient['riskLevel'] ??
                                                            'Low',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall!
                                                            .copyWith(
                                                              color: _getRiskColor(
                                                                  ingredient[
                                                                          'riskLevel'] ??
                                                                      'low'),
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (ingredient['info'] != null &&
                                                    ingredient['info'].isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(
                                                        top: 8),
                                                    child: Text(
                                                      ingredient['info'],
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium!
                                                          .secondary(context),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ))),
                                ],
                              ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
