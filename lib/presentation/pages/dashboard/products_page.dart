import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/constants/theme.dart';
import 'package:nepika/core/widgets/debounce_search_bar.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/data/dashboard/repositories/dashboard_repository.dart';
import 'package:nepika/presentation/bloc/dashboard/dashboard_bloc.dart';
import 'package:nepika/presentation/bloc/dashboard/dashboard_event.dart';
import 'package:nepika/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:nepika/presentation/pages/dashboard/product_info.dart';
import './widgets/product_card.dart';

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
      create: (context) =>
          DashboardBloc(DashboardRepositoryImpl(ApiBase()))
            ..add(FetchMyProducts(token)),
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          bool isLoading = state is MyProductsLoading;

          List<Map<String, dynamic>> myProducts = [];
          if (state is MyProductsLoaded) {
            myProducts = state.myProducts.products;
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
                                      imageUrl: product['image_url'] ?? product['imageUrl'],
                                      brandName: product['brand_name'] ?? product['brandName'] ?? 'Unknown Brand',
                                      productName: product['name'] ?? product['productName'] ?? 'Unknown Product',
                                      rating: (product['rating'] ?? product['score'] ?? '0').toString(),
                                      maxRating: '100',
                                      showCheckmark: true,
                                      onTap: () {
                                        print(product);
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ProductInfoPage(
                                              productId: product['id'] ?? 'Unknown',
                                            ),
                                          ),
                                        );
                                      },
                                      onCheckmarkTap: () {
                                        // Handle checkmark tap
                                        print('Checkmark tapped for: ${product['product_name'] ?? product['productName']}');
                                        // You can add product to favorites, cart, or any other action
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
        content: Text('${product['product_name'] ?? product['productName']} marked!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}