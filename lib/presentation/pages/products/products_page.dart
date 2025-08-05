import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/constants/theme.dart';
import 'package:nepika/core/widgets/debounce_search_bar.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/data/products/datasources/products_remote_datasource_impl.dart';
import 'package:nepika/data/products/repositories/products_repository_impl.dart';
import 'package:nepika/domain/products/usecases/get_my_products.dart';
import 'package:nepika/domain/products/usecases/get_product_info.dart';
import 'package:nepika/presentation/bloc/products/products_bloc.dart';
import 'package:nepika/presentation/bloc/products/products_event.dart';
import 'package:nepika/presentation/bloc/products/products_state.dart';
import 'product_info_page.dart';
import 'widgets/product_card.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final String token = ''; // You can set this from your auth logic

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final apiBase = ApiBase();
        final dataSource = ProductsRemoteDataSourceImpl(apiBase);
        final repository = ProductsRepositoryImpl(dataSource);
        final getMyProductsUseCase = GetMyProducts(repository);
        final getProductInfoUseCase = GetProductInfo(repository);
        
        return ProductsBloc(
          getMyProductsUseCase: getMyProductsUseCase,
          getProductInfoUseCase: getProductInfoUseCase,
        )..add(GetMyProductsRequested(token: token));
      },
      child: BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) {
          bool isLoading = state is ProductsLoading;
          List<dynamic> myProducts = [];
          
          if (state is MyProductsLoaded) {
            myProducts = state.products.map((product) => {
              'id': product.id,
              'name': product.name,
              'brand_name': product.brandName,
              'imageUrl': product.imageUrl,
              'score': product.score,
              'tag': product.tag,
              'action': product.action,
              'ingredients': product.ingredients,
            }).toList();
          }

          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final textTheme = theme.textTheme;
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    DebouncedSearchBar(
                      onSearch: (query) {
                        // Call your search logic or API call here
                        print('Searching for: $query');
                      },
                    ),

                    const SizedBox(height: 45),

                    // Title (must not be const because it uses dynamic value)
                    Text(
                      "My Products (${myProducts.length})",
                      style: textTheme.bodyLarge
                    ),

                    const SizedBox(height: 20),

                    // Product Cards List
                    Expanded(
                      child: isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                              ),
                            )
                          : myProducts.isEmpty
                              ? Center(
                                  child: Text(
                                    'No products found',
                                    style: textTheme.bodyMedium!.secondary(context)
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: myProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = myProducts[index];
                                    return ProductCard(
                                      imageUrl: product['imageUrl'],
                                      brandName: product['brand_name'] ?? 'Unknown Brand',
                                      productName: product['name'] ?? 'Unknown Product',
                                      rating: (product['score'] ?? '0').toString(),
                                      maxRating: '100',
                                      showCheckmark: true,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ProductInfoPage(
                                              productId: product['id'] ?? 'Unknown',
                                            ),
                                          ),
                                        );
                                      },
                                      onCheckmarkTap: () {
                                        _handleCheckmarkTap(product);
                                      },
                                      margin: const EdgeInsets.only(bottom: 12),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleCheckmarkTap(Map<String, dynamic> product) {
    // Handle checkmark tap logic here
    // For example: add to favorites, mark as selected, etc.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} marked!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
