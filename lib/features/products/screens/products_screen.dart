import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/data/products/datasources/products_remote_datasource_impl.dart';
import 'package:nepika/data/products/repositories/products_repository_impl.dart';
import 'package:nepika/domain/products/usecases/get_my_products.dart';
import 'package:nepika/domain/products/usecases/get_product_info.dart';
import 'package:nepika/domain/products/usecases/toggle_product.dart';
import 'package:nepika/data/auth/datasources/auth_local_data_source_impl.dart';
import '../bloc/products_bloc.dart';
import '../bloc/products_event.dart';
import '../bloc/products_state.dart';
import '../widgets/product_card.dart';
import '../components/product_info_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
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
    
    if (mounted) {
      setState(() {
        token = loadedToken!;
      });
    }
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

  void _navigateToProductInfo(String productId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductInfoScreen(
          productId: productId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (token == null) {
      return _buildLoadingScaffold(context);
    }

    return BlocProvider(
      create: (context) => _createProductsBloc(),
      child: _buildProductsView(),
    );
  }

  Widget _buildLoadingScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  ProductsBloc _createProductsBloc() {
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
  }

  Widget _buildProductsView() {
    return BlocConsumer<ProductsBloc, ProductsState>(
      listener: _handleBlocStateChanges,
      builder: (context, state) {
        final isLoading = state is ProductsLoading;
        final myProducts = _extractProductsFromState(state);
        final togglingProductId = _getTogglingProductId(state);
        
        return _buildScaffold(context, isLoading, myProducts, togglingProductId);
      },
    );
  }

  void _handleBlocStateChanges(BuildContext context, ProductsState state) {
    if (state is ProductToggled) {
      _showSuccessSnackBar(context, state.message);
    } else if (state is ProductsError) {
      _showErrorSnackBar(context, state.message);
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<Map<String, dynamic>> _extractProductsFromState(ProductsState state) {
    List<dynamic> productEntities = [];
    
    if (state is MyProductsLoaded) {
      productEntities = state.products;
    } else if (state is ProductToggling) {
      productEntities = state.products;
    } else if (state is ProductToggled) {
      productEntities = state.products;
    }
    
    return productEntities.map((product) => {
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

  String? _getTogglingProductId(ProductsState state) {
    if (state is ProductToggling) {
      return state.productId;
    }
    return null;
  }

  Widget _buildScaffold(
    BuildContext context,
    bool isLoading,
    List<Map<String, dynamic>> myProducts,
    String? togglingProductId,
  ) {
    final theme = Theme.of(context);
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
              _buildTitle(textTheme),
              const SizedBox(height: 20),
              _buildProductsList(context, isLoading, myProducts, togglingProductId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(TextTheme textTheme) {
    return Text(
      "Recommend Products",
      style: textTheme.bodyLarge,
    );
  }

  Widget _buildProductsList(
    BuildContext context,
    bool isLoading,
    List<Map<String, dynamic>> myProducts,
    String? togglingProductId,
  ) {
    return Expanded(
      child: isLoading
          ? _buildLoadingIndicator(context)
          : myProducts.isEmpty
              ? _buildEmptyState(context)
              : _buildProductGrid(myProducts, togglingProductId),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text(
        'No products found',
        style: Theme.of(context).textTheme.bodyMedium!.secondary(context),
      ),
    );
  }

  Widget _buildProductGrid(
    List<Map<String, dynamic>> myProducts,
    String? togglingProductId,
  ) {
    return ListView.builder(
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
          onTap: () => _navigateToProductInfo(productId),
          onCheckmarkTap: () => _handleCheckmarkTap(context, productId),
          isToggling: togglingProductId == productId,
          margin: const EdgeInsets.only(bottom: 12),
        );
      },
    );
  }
}