import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/data/products/datasources/products_remote_datasource_impl.dart';
import 'package:nepika/data/products/repositories/products_repository_impl.dart';
import 'package:nepika/domain/products/usecases/get_my_products.dart';
import 'package:nepika/domain/products/usecases/get_product_info.dart';
import 'package:nepika/domain/products/usecases/toggle_product.dart';
import 'package:nepika/presentation/bloc/products/products_bloc.dart';
import 'package:nepika/presentation/bloc/products/products_event.dart';
import 'package:nepika/presentation/bloc/products/products_state.dart';
import 'package:nepika/data/auth/datasources/auth_local_data_source_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'product_info_page.dart';
import 'widgets/product_card.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String? token;
  Set<String> selectedProductIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final authDataSource = AuthLocalDataSourceImpl(prefs);
    final loadedToken = await authDataSource.getToken();
    
    // final directToken = prefs.getString('access_token');
    if (mounted) {
      setState(() {
        token = loadedToken!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (token == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return BlocProvider(
      create: (context) {
        final apiBase = ApiBase();
        final dataSource = ProductsRemoteDataSourceImpl(apiBase);
        final repository = ProductsRepositoryImpl(dataSource);
        final getMyProductsUseCase = GetMyProducts(repository);
        final getProductInfoUseCase = GetProductInfo(repository);
        final toggleProductUseCase = ToggleProduct(repository);
        
        return ProductsBloc(
          getMyProductsUseCase: getMyProductsUseCase,
          getProductInfoUseCase: getProductInfoUseCase,
          toggleProductUseCase: toggleProductUseCase,
        )..add(GetMyProductsRequested(token: token!));
      },
      child: BlocConsumer<ProductsBloc, ProductsState>(
        listener: (context, state) {
          if (state is ProductToggled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is ProductsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, state) {
          bool isLoading = state is ProductsLoading;
          List<dynamic> myProducts = [];
          String? togglingProductId;
          
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
          } else if (state is ProductToggling) {
            togglingProductId = state.productId;
            // Show products from ProductToggling state
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
          } else if (state is ProductToggled) {
            // Show products from ProductToggled state
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

                    // DebouncedSearchBar(
                    //   onSearch: (query) {
                    //     // Call your search logic or API call here
                    //     debugPrint('Searching for: $query');
                    //   },
                    // ),

                    // const SizedBox(height: 45),

                    // Title (must not be const because it uses dynamic value)
                    Text(
                      "Recommend  Products",
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
                                    final productId = product['id'] ?? 'Unknown';
                                    return ProductCard(
                                      imageUrl: product['imageUrl'],
                                      brandName: product['brand_name'] ?? 'Unknown Brand',
                                      productName: product['name'] ?? 'Unknown Product',
                                      rating: (product['score'] ?? '0').toString(),
                                      maxRating: '100',
                                      showCheckmark: true,
                                      isSelected: selectedProductIds.contains(productId),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ProductInfoPage(
                                              productId: productId,
                                            ),
                                          ),
                                        );
                                      },
                                      onCheckmarkTap: () {
                                        _handleCheckmarkTap(context, productId);
                                      },
                                      isToggling: togglingProductId == productId,
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

  void _handleCheckmarkTap(BuildContext context, String productId) {
    // Update local state immediately for UI responsiveness
    setState(() {
      if (selectedProductIds.contains(productId)) {
        selectedProductIds.remove(productId);
      } else {
        selectedProductIds.add(productId);
      }
    });
    
    // Then call API in background
    context.read<ProductsBloc>().add(
      ToggleProductRequested(
        token: token!,
        productId: productId,
      ),
    );
  }
}
