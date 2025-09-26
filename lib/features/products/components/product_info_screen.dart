import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/utils/debug_logger.dart';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/core/widgets/custom_button.dart';
import 'package:nepika/data/products/datasources/products_remote_datasource_impl.dart';
import 'package:nepika/data/products/repositories/products_repository_impl.dart';
import 'package:nepika/domain/products/usecases/get_my_products.dart';
import 'package:nepika/domain/products/usecases/get_product_info.dart';
import 'package:nepika/domain/products/usecases/toggle_product.dart';
import 'package:nepika/data/auth/datasources/auth_local_data_source_impl.dart';
import '../bloc/products_bloc.dart';
import '../bloc/products_event.dart';
import '../bloc/products_state.dart';

class ProductInfoScreen extends StatefulWidget {
  final String productId;
  
  const ProductInfoScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductInfoScreen> createState() => _ProductInfoScreenState();
}

class _ProductInfoScreenState extends State<ProductInfoScreen> {
  String? token;
  late final String productId;

  @override
  void initState() {
    super.initState();
    productId = widget.productId;
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

  @override
  Widget build(BuildContext context) {
    if (productId.isEmpty) {
      return _buildErrorScaffold('Product ID missing');
    }

    if (token == null) {
      return _buildLoadingScaffold(context);
    }

    return BlocProvider(
      create: (context) => _createProductsBloc(),
      child: BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) {
          final isLoading = state is ProductInfoLoading;
          final productInfo = _extractProductInfo(state);
          
          return _buildScaffold(context, isLoading, productInfo);
        },
      ),
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
    )..add(GetProductInfoRequested(token: token!, productId: productId));
  }

  Widget _buildErrorScaffold(String message) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium!.secondary(context),
        ),
      ),
    );
  }

  Map<String, dynamic> _extractProductInfo(ProductsState state) {
    if (state is ProductInfoLoaded) {
      final productInfo = state.productInfo;
      return {
        'id': productInfo.id,
        'name': productInfo.name,
        'brand_name': productInfo.brandName,
        'imageUrl': productInfo.imageUrl,
        'score': productInfo.score,
        'ingredients': productInfo.ingredients,
        ...productInfo.details,
      };
    }
    return {};
  }

  Widget _buildScaffold(
    BuildContext context,
    bool isLoading,
    Map<String, dynamic> productInfo,
  ) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (isLoading)
              _buildLoadingContent(context)
            else
              _buildProductContent(context, productInfo),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [CustomBackButton()],
      ),
    );
  }

  Widget _buildLoadingContent(BuildContext context) {
    return Expanded(
      child: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildProductContent(
    BuildContext context,
    Map<String, dynamic> productInfo,
  ) {
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  _ProductImageSection(imageUrl: productInfo['imageUrl']),
                  const SizedBox(height: 24),
                  _ProductDetailsSection(productInfo: productInfo),
                  const SizedBox(height: 25),
                  _ProductScoreSection(score: productInfo['score']),
                  const SizedBox(height: 25),
                  _IngredientsSection(ingredients: productInfo['ingredients']),
                  const SizedBox(height: 40),
                  _buildAmazonButton(productInfo['ingredients']),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmazonButton(List<dynamic>? ingredients) {
    if (ingredients == null) return const SizedBox();
    
    final positiveIngredients = ingredients
        .where((ingredient) => 
            ingredient['riskLevel']?.toLowerCase() != 'high')
        .toList();
    
    if (positiveIngredients.length <= 2) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(0),
      child: CustomButton(
        text: "Buy from Amazon",
        onPressed: _launchAmazonUrl,
        isLoading: false,
      ),
    );
  }

  Future<void> _launchAmazonUrl() async {
    const url = 'https://www.amazon.com';
    final uri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorSnackBar('Could not open Amazon. Please try again.');
      }
    } catch (e) {
      logJson(e);
      _showErrorSnackBar('Error opening Amazon. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _ProductImageSection extends StatelessWidget {
  final String? imageUrl;
  
  const _ProductImageSection({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderIcon(context);
                },
              ),
            )
          : _buildPlaceholderIcon(context),
    );
  }

  Widget _buildPlaceholderIcon(BuildContext context) {
    return Icon(
      Icons.image,
      size: 40,
      color: Theme.of(context).colorScheme.onTertiary,
    );
  }
}

class _ProductDetailsSection extends StatelessWidget {
  final Map<String, dynamic> productInfo;
  
  const _ProductDetailsSection({required this.productInfo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          productInfo['brand_name'] ?? '',
          style: Theme.of(context).textTheme.bodyMedium!.secondary(context),
        ),
        const SizedBox(height: 10),
        Text(
          productInfo['name'] ?? 'Loading...',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }
}

class _ProductScoreSection extends StatelessWidget {
  final dynamic score;
  
  const _ProductScoreSection({required this.score});

  @override
  Widget build(BuildContext context) {
    final scoreValue = score ?? 0;
    final scoreText = _getScoreText(scoreValue);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$scoreValue/100',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            scoreText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getScoreText(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  }
}

class _IngredientsSection extends StatelessWidget {
  final List<dynamic>? ingredients;
  
  const _IngredientsSection({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    if (ingredients == null || ingredients!.isEmpty) {
      return const SizedBox();
    }
    
    final negativeIngredients = ingredients!
        .where((ingredient) => 
            ingredient['riskLevel']?.toLowerCase() == 'high')
        .toList();
    
    final positiveIngredients = ingredients!
        .where((ingredient) => 
            ingredient['riskLevel']?.toLowerCase() != 'high')
        .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Ingredients',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 24),
        if (negativeIngredients.isNotEmpty) ...[
          _NegativeIngredientsSection(ingredients: negativeIngredients),
          const SizedBox(height: 30),
        ],
        if (positiveIngredients.isNotEmpty)
          _PositiveIngredientsSection(ingredients: positiveIngredients),
      ],
    );
  }
}

class _NegativeIngredientsSection extends StatelessWidget {
  final List<dynamic> ingredients;
  
  const _NegativeIngredientsSection({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Negatives',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 10),
        ...ingredients.map((ingredient) => _buildIngredientItem(
          context,
          ingredient,
          'High Risk',
          const Color(0xFFEF4444),
        )),
      ],
    );
  }

  Widget _buildIngredientItem(
    BuildContext context,
    Map<String, dynamic> ingredient,
    String riskText,
    Color riskColor,
  ) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  ingredient['name'] ?? '',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              GestureDetector(
                onTap: () => _showIngredientInfoModal(
                  context,
                  ingredient['info'] ?? '',
                ),
                child: SizedBox(
                  width: 19,
                  height: 19,
                  child: Image.asset(
                    'assets/icons/info_icon.png',
                    width: 12,
                    height: 12,
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .secondary(context)
                        .color,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Text(
                riskText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: riskColor,
                ),
              ),
            ],
          ),
        ),
        if (ingredients.length > 1)
          Container(
            height: 1,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.2),
            margin: const EdgeInsets.only(bottom: 16),
          ),
      ],
    );
  }

  void _showIngredientInfoModal(BuildContext context, String info) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _IngredientInfoDialog(info: info);
      },
    );
  }
}

class _PositiveIngredientsSection extends StatelessWidget {
  final List<dynamic> ingredients;
  
  const _PositiveIngredientsSection({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    final displayCount = ingredients.length > 2 ? 2 : ingredients.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Positive',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(displayCount, (index) {
          final ingredient = ingredients[index];
          final riskLevel = ingredient['riskLevel'] ?? 'Low';
          return _buildIngredientItem(
            context,
            ingredient,
            '$riskLevel Risk',
            _getRiskColor(riskLevel, context),
            showDivider: index < displayCount - 1,
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildIngredientItem(
    BuildContext context,
    Map<String, dynamic> ingredient,
    String riskText,
    Color riskColor, {
    bool showDivider = false,
  }) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  ingredient['name'] ?? '',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              GestureDetector(
                onTap: () => _showIngredientInfoModal(
                  context,
                  ingredient['info'] ?? '',
                ),
                child: SizedBox(
                  width: 19,
                  height: 19,
                  child: Image.asset(
                    'assets/icons/info_icon.png',
                    width: 12,
                    height: 12,
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .secondary(context)
                        .color,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Text(
                riskText,
                style: TextStyle(
                  color: riskColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.2),
            margin: const EdgeInsets.only(bottom: 16),
          ),
      ],
    );
  }

  Color _getRiskColor(String riskLevel, BuildContext context) {
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

  void _showIngredientInfoModal(BuildContext context, String info) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _IngredientInfoDialog(info: info);
      },
    );
  }
}

class _IngredientInfoDialog extends StatelessWidget {
  final String info;
  
  const _IngredientInfoDialog({required this.info});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ingredient Information',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      color: Theme.of(context).iconTheme.color,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Text(
                info.isNotEmpty
                    ? info
                    : 'No additional information available.',
                textAlign: TextAlign.left,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .secondary(context),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}