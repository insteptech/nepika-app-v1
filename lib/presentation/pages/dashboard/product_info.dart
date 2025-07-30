import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/constants/routes.dart';
import 'package:nepika/core/constants/theme.dart';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/core/widgets/custom_button.dart';
import 'package:nepika/data/dashboard/repositories/dashboard_repository.dart';
import 'package:nepika/presentation/bloc/dashboard/dashboard_bloc.dart';
import 'package:nepika/presentation/bloc/dashboard/dashboard_event.dart';
import 'package:nepika/presentation/bloc/dashboard/dashboard_state.dart';

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
        return Color(0xFFEF4444);
      case 'moderate':
        return Color(0xFFFFD748);
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

  void _showInfoModal(BuildContext context, String info) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
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
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium,
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
                Text(
                  textAlign: TextAlign.left,
                  info.isNotEmpty
                      ? info
                      : 'No additional information available.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.secondary(context),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (productId.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Text(
            "Product ID missing",
            style: Theme.of(context).textTheme.bodyMedium!.secondary(context),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (context) =>
          DashboardBloc(DashboardRepository(ApiBase()))
            ..add(FetchProductInfo(token, productId)),
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          bool isLoading = state is ProductInfoLoading;

          Map<String, dynamic> productInfo = {};
          if (state is ProductInfoLoaded) {
            productInfo = state.productInfo;
          }
          print('Product Info: ${productInfo['imageUrl']}');

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 20),
                    child: Row(children: [
                      const CustomBackButton(),
                    ]),
                  ),
                  // const CustomBackButton(),
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
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 32),

                                  // Product Image
                                  Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12), 
                                    ),
                                    child: productInfo['imageUrl'] != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.network(
                                              productInfo['imageUrl'],
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Icon(
                                                      Icons.image,
                                                      size: 40,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onTertiary,
                                                    );
                                                  },
                                            ),
                                          )
                                        : Icon(
                                            Icons.image,
                                            size: 40,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onTertiary,
                                          ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Brand Name
                                  Text(
                                    productInfo['brand_name'] ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium!.secondary(context),
                                  ),

                                  const SizedBox(height: 10),

                                  // Product Name
                                  Text(
                                    productInfo['name'] ?? 'Loading...',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),

                                  const SizedBox(height: 25),

                                  // Score Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${productInfo['score'] ?? 0}/100',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.copyWith(
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
                                          _getScoreText(
                                            productInfo['score'] ?? 0,
                                          ),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 25),

                                  // Ingredients Section
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Ingredients',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineMedium,
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Ingredients Content
                                  if (productInfo['ingredients'] != null)
                                    ...(() {
                                      List<dynamic> ingredients =
                                          productInfo['ingredients'];
                                      List<dynamic> negativeIngredients =
                                          ingredients
                                              .where(
                                                (ingredient) =>
                                                    ingredient['riskLevel']
                                                        ?.toLowerCase() ==
                                                    'high',
                                              )
                                              .toList();

                                      List<Widget> widgets = [];

                                      if (negativeIngredients.isNotEmpty) {
                                        widgets.add(
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Negatives',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.headlineMedium,
                                            ),
                                          ),
                                        );
                                        widgets.add(const SizedBox(height: 10));

                                        for (var ingredient
                                            in negativeIngredients) {
                                          widgets.add(
                                            Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 2,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      ingredient['name'] ?? '',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headlineMedium,
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () => _showInfoModal(
                                                      context,
                                                      ingredient['info'] ??
                                                          productInfo['info'] ??
                                                          '',
                                                    ),
                                                    child: SizedBox(
                                                      width: 19,
                                                      height: 19,
                                                      child: Image.asset(
                                                        'assets/icons/info_icon.png',
                                                        width: 12,
                                                        height: 12,
                                                        color: Theme.of(
                                                          context,
                                                        ).textTheme.bodyLarge!.secondary(context).color,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                          widgets.add(
                                            Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    'High Risk',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          color: _getRiskColor(
                                                            'high',
                                                          ),
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                          widgets.add(
                                            negativeIngredients.length > 1
                                                ? Container(
                                                    height: 1,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(alpha: 0.2),
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 16,
                                                        ),
                                                  )
                                                : const SizedBox(),
                                          );
                                        }
                                        widgets.add(const SizedBox(height: 30));
                                      }

                                      // Positive Section
                                      List<dynamic> positiveIngredients =
                                          ingredients
                                              .where(
                                                (ingredient) =>
                                                    ingredient['riskLevel']
                                                        ?.toLowerCase() !=
                                                    'high',
                                              )
                                              .toList();

                                      if (positiveIngredients.isNotEmpty) {
                                        widgets.add(
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Positive',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyLarge,
                                            ),
                                          ),
                                        );
                                        widgets.add(const SizedBox(height: 10));

                                        for (
                                          int i = 0;
                                          i < positiveIngredients.length &&
                                              i < 2;
                                          i++
                                        ) {
                                          var ingredient =
                                              positiveIngredients[i];
                                          widgets.add(
                                            Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 2,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      ingredient['name'] ?? '',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headlineMedium,
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () => _showInfoModal(
                                                      context,
                                                      ingredient['info'] ??
                                                          productInfo['info'] ??
                                                          '',
                                                    ),
                                                    child: SizedBox(
                                                      width: 19,
                                                      height: 19,
                                                      child: Image.asset(
                                                        'assets/icons/info_icon.png',
                                                        width: 12,
                                                        height: 12,
                                                        color: Theme.of(
                                                          context,
                                                        ).textTheme.bodyLarge!.secondary(context).color,
                                                      ),

                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                          widgets.add(
                                            Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    '${ingredient['riskLevel'] ?? 'Low'} Risk',
                                                    style: TextStyle(
                                                      color: _getRiskColor(
                                                        ingredient['riskLevel'] ??
                                                            'Low',
                                                      ),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                          if (i <
                                                  positiveIngredients.length -
                                                      1 &&
                                              i < 1) {
                                            widgets.add(
                                              Container(
                                                height: 1,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface.withValues(alpha: 0.2),
                                                margin: const EdgeInsets.only(
                                                  bottom: 16,
                                                ),
                                              ),
                                            );
                                          }
                                        }

                                        // Add spacer to push button to bottom when there are few ingredients
                                        widgets.add(const SizedBox(height: 20));
                                      }

                                      return widgets;
                                    })(),
                                ],
                              ),
                            ),
                          ),

                          // Bottom Button Section - Always at bottom
                          if (productInfo['ingredients'] != null)
                            ...(() {
                              List<dynamic> ingredients =
                                  productInfo['ingredients'];
                              List<dynamic> positiveIngredients = ingredients
                                  .where(
                                    (ingredient) =>
                                        ingredient['riskLevel']
                                            ?.toLowerCase() !=
                                        'high',
                                  )
                                  .toList();

                              if (positiveIngredients.length > 2) {
                                return [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    child: CustomButton(
                                      text:
                                          'View ${positiveIngredients.length - 2} positive ingredients',
                                      onPressed: () {
                                        Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).pushNamed(AppRoutes.subscription);
                                      },
                                      isLoading: false,
                                    ),
                                  ),
                                ];
                              }
                              return [const SizedBox()];
                            })(),
                        ],
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
