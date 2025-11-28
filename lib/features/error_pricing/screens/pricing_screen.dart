import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/widgets/custom_button.dart';
import 'package:nepika/core/di/injection_container.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nepika/data/app/repositories/app_repository.dart';
import 'package:nepika/presentation/bloc/app/app_bloc.dart';
import 'package:nepika/presentation/bloc/app/app_event.dart';
import 'package:nepika/presentation/bloc/app/app_state.dart';
import 'package:nepika/features/payments/bloc/payment_bloc.dart';
import 'package:nepika/features/payments/bloc/payment_event.dart';
import 'package:nepika/features/payments/bloc/payment_state.dart';
import 'package:nepika/core/config/constants/theme.dart';
// IAP imports
import 'package:nepika/features/payments/widgets/iap_bottom_sheet.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  String token = '';
  int selectedPlanIndex = 0;
  PaymentBloc? _paymentBloc;
  IAPBloc? _iapBloc;
  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _getToken();
  }

  Future<void> _initializeBlocs() async {
    print('PricingScreen: Starting initialization, isFullyInitialized=${ServiceLocator.isFullyInitialized}');

    // Wait for ServiceLocator to be fully initialized
    if (!ServiceLocator.isFullyInitialized) {
      print('PricingScreen: Waiting for ServiceLocator initialization...');
      await ServiceLocator.waitForInitialization();
      print('PricingScreen: ServiceLocator initialization complete');
    }

    print('PricingScreen: Getting blocs from ServiceLocator');

    try {
      print('PricingScreen: About to get PaymentBloc...');
      final paymentBloc = ServiceLocator.get<PaymentBloc>();
      print('PricingScreen: Got PaymentBloc: $paymentBloc');

      print('PricingScreen: About to get IAPBloc...');
      final iapBloc = ServiceLocator.get<IAPBloc>();
      print('PricingScreen: Got IAPBloc: $iapBloc');

      print('PricingScreen: mounted=$mounted');
      if (mounted) {
        setState(() {
          _paymentBloc = paymentBloc;
          _iapBloc = iapBloc..add(InitializeIAP());
          _isInitializing = false;
        });
        print('PricingScreen: Blocs initialized successfully, _isInitializing=$_isInitializing');
      }
    } catch (e, stackTrace) {
      print('PricingScreen: ERROR getting blocs: $e');
      print('PricingScreen: Stack trace: $stackTrace');
    }
  }

  void _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(AppConstants.accessTokenKey);
    setState(() {
      token = accessToken ?? '';
    });
  }

  @override
  void dispose() {
    _paymentBloc?.close();
    _iapBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show loading state while waiting for initialization
    if (_isInitializing || _paymentBloc == null || _iapBloc == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AppBloc(appRepository: AppRepositoryImpl(ApiBase()))
                  ..add(AppSubscriptions(token)),
          ),
          BlocProvider.value(value: _paymentBloc!),
          BlocProvider.value(value: _iapBloc!),
        ],
        child: SafeArea(
          child: MultiBlocListener(
            listeners: [
              // Existing Payment Bloc listener (Stripe)
              BlocListener<PaymentBloc, PaymentState>(
                listener: (context, state) {
                  if (state is CheckoutSessionCreated) {
                    _launchCheckoutUrl(state.session.url);
                  } else if (state is SubscriptionCanceled) {
                    _handleCancellationSuccess(state.details);
                  } else if (state is SubscriptionReactivated) {
                    _handleReactivationSuccess(state.details);
                  } else if (state is PaymentError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                    );
                  }
                  setState(() {
                    _isLoading = state is PaymentLoading;
                  });
                },
              ),
              // IAP Bloc listener
              BlocListener<IAPBloc, IAPState>(
                listener: (context, state) {
                  if (state is IAPPurchaseSuccess) {
                    // Refresh subscription status after successful IAP
                    context.read<AppBloc>().add(AppSubscriptions(token));
                  } else if (state is IAPRestoreSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Purchases restored successfully'), backgroundColor: Colors.green),
                    );
                    context.read<AppBloc>().add(AppSubscriptions(token));
                  } else if (state is IAPError) {
                    // Error handling is done in bottom sheet
                  }
                },
              ),
            ],
            child: BlocBuilder<AppBloc, AppState>(
              builder: (context, state) {
                if (state is AppSubscriptionLoading) {
                  return _buildLoadingSkeleton(theme);
                }

                if (state is AppSubscriptionError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text('Failed to load pricing plans', style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(state.message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<AppBloc>().add(AppSubscriptions(token)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is AppInitial || state is! AppSubscriptionLoaded) {
                  return _buildLoadingSkeleton(theme);
                }

                final data = state.subscriptionPlan;
                final hasSubscription = data['has_subscription'] == true;
                final currentPlan = data['current_plan'] as Map<String, dynamic>?;

                List<dynamic> plansData = [];
                try {
                  if (data.containsKey('plans') && data['plans'] != null) {
                    plansData = List<dynamic>.from(data['plans'] ?? []);
                  } else if (data.containsKey('other_plans') && data['other_plans'] != null) {
                    plansData = List<dynamic>.from(data['other_plans'] ?? []);
                  } else if (data.containsKey('data') && data['data'] != null) {
                    final nestedData = data['data'] as Map<String, dynamic>?;
                    if (nestedData != null) {
                      if (nestedData.containsKey('plans') && nestedData['plans'] != null) {
                        plansData = List<dynamic>.from(nestedData['plans'] ?? []);
                      } else if (nestedData.containsKey('other_plans') && nestedData['other_plans'] != null) {
                        plansData = List<dynamic>.from(nestedData['other_plans'] ?? []);
                      }
                    }
                  }
                } catch (e) {
                  plansData = [];
                }

                // ✅ Merge StoreKit prices with server data
                List<Map<String, dynamic>> plans = [];
                try {
                  if (_iapBloc!.isAvailable && _iapBloc!.products.isNotEmpty) {
                    // Use StoreKit prices (real, localized)
                    plans = _iapBloc!.mergeWithServerData(plansData);
                    debugPrint('IAP: Using StoreKit prices for ${plans.length} products');
                  } else {
                    // Fallback to server prices if StoreKit unavailable
                    debugPrint('IAP: Falling back to server prices (StoreKit unavailable)');
                    plans = plansData.whereType<Map<String, dynamic>>().map((plan) {
                      try {
                        String priceDisplay = '';
                        dynamic priceValue = 0.0;

                        final price = plan['price'];
                        if (price is String && price.isNotEmpty) {
                          priceDisplay = price;
                          priceValue = double.tryParse(plan['price_amount']?.toString() ?? '0') ?? 0.0;
                        } else if (price is num) {
                          priceValue = price;
                          priceDisplay = '\$${priceValue.toStringAsFixed(2)}';
                        } else {
                          priceDisplay = '\$0.00';
                        }

                        String billingPeriod = '';
                        final interval = plan['interval'];
                        final duration = plan['duration'];
                        if (interval != null && interval.toString().isNotEmpty) {
                          billingPeriod = interval.toString();
                        } else if (duration != null && duration.toString().isNotEmpty) {
                          billingPeriod = duration.toString();
                        }

                        return {
                          'name': plan['name']?.toString() ?? '',
                          'price': priceValue,
                          'priceDisplay': priceDisplay,
                          'billingPeriod': billingPeriod,
                          'stripe_price_id': plan['stripe_price_id']?.toString() ?? '',
                        };
                      } catch (e) {
                        return {
                          'name': '',
                          'price': 0.0,
                          'priceDisplay': '\$0.00',
                          'billingPeriod': '',
                          'stripe_price_id': '',
                        };
                      }
                    }).toList();
                  }
                } catch (e) {
                  debugPrint('IAP: Error merging products: $e');
                  plans = [];
                }
                
                List<Map<String, dynamic>> features = [];
                try {
                  if (plansData.isNotEmpty) {
                    final firstPlan = plansData.first;
                    List<dynamic> planFeatures = firstPlan['features'] as List<dynamic>? ?? 
                                                 firstPlan['plan_details'] as List<dynamic>? ?? [];
                    features = planFeatures.map((feature) => {'title': feature?.toString() ?? ''}).toList();
                  }
                } catch (e) {
                  features = [];
                }

                if (plans.isEmpty && features.isEmpty) {
                  return _buildLoadingSkeleton(theme);
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Transform.rotate(
                                angle: 45 * 3.1415926535 / 180,
                                child: Image.asset('assets/icons/add_icon.png', width: 28, height: 28),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(color: theme.colorScheme.onSecondary, shape: BoxShape.circle),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Image.asset('assets/images/nepika_logo_image.png', color: theme.primaryIconTheme.color),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text('Nepika Premium', style: theme.textTheme.displaySmall),
                      const SizedBox(height: 5),
                      Text(
                        'Know what touches your skin',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.brightness == Brightness.dark ? const Color(0xFFB0B0B0) : const Color(0xFF7F7F7F),
                        ),
                      ),
                      const SizedBox(height: 30),

                      if (hasSubscription && currentPlan != null)
                        _buildCurrentSubscriptionCard(currentPlan, theme),
                      
                      if (hasSubscription && currentPlan != null)
                        const SizedBox(height: 30),

                      ...features.map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 15, left: 20, right: 20),
                          child: Row(
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                ),
                                child: Center(
                                  child: hasSubscription 
                                      ? Icon(Icons.check, color: theme.colorScheme.primary, size: 20)
                                      : Image.asset('assets/icons/unlock_icon.png', width: 18, height: 18),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(child: Text(feature['title'] ?? '', style: theme.textTheme.headlineLarge)),
                            ],
                          ),
                        ),
                      ),

                      if (!hasSubscription) ...[
                        const SizedBox(height: 24),
                        ...List.generate(plans.length, (index) {
                          final plan = plans[index];
                          final isSelected = selectedPlanIndex == index;
                          return GestureDetector(
                            onTap: () => setState(() => selectedPlanIndex = index),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                              decoration: BoxDecoration(
                                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                border: Border.all(color: theme.colorScheme.primary),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: isSelected ? theme.colorScheme.onSecondary : theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      plan['name'] ?? '',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: isSelected ? theme.colorScheme.onSecondary : theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatPrice(plan),
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: isSelected ? theme.colorScheme.onSecondary : theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        plan['billingPeriod']?.toString().isNotEmpty == true 
                                            ? 'Per ${plan['billingPeriod']}' 
                                            : 'Per billing period',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: isSelected ? theme.colorScheme.onSecondary : theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CustomButton(
                          text: hasSubscription ? 'Manage Subscription' : 'Continue',
                          isLoading: _isLoading,
                          onPressed: _isLoading 
                              ? null 
                              : () => hasSubscription 
                                  ? _onManageSubscription(currentPlan) 
                                  : _onContinuePressed(plans),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.start,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.termsOfUse),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    child: Text(
                                      'Terms',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(' and ', style: theme.textTheme.bodyMedium),
                                InkWell(
                                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.privacyPolicy),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    child: Text(
                                      'Privacy',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Restore button - now triggers IAP restore
                            GestureDetector(
                              onTap: () => _iapBloc?.add(RestorePurchases()),
                              child: Text('Restore', style: theme.textTheme.bodyMedium),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ==================== IAP PURCHASE FLOW ====================
  
  void _onContinuePressed(List<dynamic> plans) {
    if (plans.isEmpty || selectedPlanIndex >= plans.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid plan'), backgroundColor: Colors.red),
      );
      return;
    }

    final selectedPlan = plans[selectedPlanIndex];
    
    // Show IAP purchase bottom sheet instead of Stripe checkout
    IAPPurchaseBottomSheet.show(
      context: context,
      selectedPlan: selectedPlan,
      iapBloc: _iapBloc!,
      onSuccess: () {
        // Refresh subscription data after successful purchase
        context.read<AppBloc>().add(AppSubscriptions(token));
      },
      onCancel: () {
        // User cancelled - nothing to do
      },
    );
  }

  // ==================== EXISTING METHODS (unchanged) ====================

  void _onManageSubscription(Map<String, dynamic>? currentPlan) {
    if (currentPlan != null) {
      _showManageSubscriptionBottomSheet(currentPlan);
    }
  }

  Future<void> _launchCheckoutUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch payment page'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ... Keep ALL your existing helper methods below exactly as they were:
  // _buildLoadingSkeleton, _buildShimmerContainer, _formatPrice,
  // _buildCurrentSubscriptionCard, _formatPlanPrice, _formatDate,
  // _formatDateLocal, _getDaysUntilDate, _getSubscriptionStatusText,
  // _getDetailedDateText, _showManageSubscriptionBottomSheet,
  // _showCancelConfirmationDialog, _cancelSubscription,
  // _reactivateSubscription, _handleCancellationSuccess,
  // _handleReactivationSuccess
  
  // I'm including them for completeness:

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Transform.rotate(
                    angle: 45 * 3.1415926535 / 180,
                    child: Image.asset('assets/icons/add_icon.png', width: 28, height: 28),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(color: theme.colorScheme.onSecondary, shape: BoxShape.circle),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Image.asset('assets/images/nepika_logo_image.png', color: theme.primaryIconTheme.color),
            ),
          ),
          const SizedBox(height: 30),
          _buildShimmerContainer(width: 200, height: 32, theme: theme),
          const SizedBox(height: 5),
          _buildShimmerContainer(width: 250, height: 20, theme: theme),
          const SizedBox(height: 45),
          ...List.generate(4, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 15, left: 20, right: 20),
            child: Row(
              children: [
                _buildShimmerContainer(width: 45, height: 45, theme: theme, isCircle: true),
                const SizedBox(width: 20),
                Expanded(child: _buildShimmerContainer(width: double.infinity, height: 18, theme: theme)),
              ],
            ),
          )),
          const SizedBox(height: 24),
          ...List.generate(2, (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _buildShimmerContainer(width: double.infinity, height: 70, theme: theme, borderRadius: 40),
          )),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildShimmerContainer(width: double.infinity, height: 48, theme: theme, borderRadius: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerContainer({required double width, required double height, required ThemeData theme, bool isCircle = false, double? borderRadius}) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surface,
      highlightColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(borderRadius ?? 8),
        ),
      ),
    );
  }

  String _formatPrice(Map<String, dynamic> plan) {
    try {
      final priceDisplay = plan['priceDisplay'];
      if (priceDisplay != null && priceDisplay.toString().isNotEmpty) return priceDisplay.toString();
      final price = plan['price'];
      if (price != null) {
        if (price is String) return price.isNotEmpty ? price : '\$0.00';
        if (price is num) return '\$${price.toStringAsFixed(2)}';
      }
      return '\$0.00';
    } catch (e) {
      return '\$0.00';
    }
  }

  Widget _buildCurrentSubscriptionCard(Map<String, dynamic>? currentPlan, ThemeData theme) {
    if (currentPlan == null) return const SizedBox.shrink();
    
    try {
      final planName = currentPlan['name']?.toString() ?? 'Premium Plan';
      final planPrice = currentPlan['price']?.toString() ?? currentPlan['price_amount']?.toString() ?? '';
      final billingPeriod = currentPlan['interval']?.toString() ?? currentPlan['duration']?.toString() ?? '';
      final nextBillingDate = currentPlan['current_period_end']?.toString() ?? currentPlan['next_billing_date']?.toString() ?? '';
      final cancelAtPeriodEnd = currentPlan['cancel_at_period_end'] == true;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary.withValues(alpha: 0.1), theme.colorScheme.primary.withValues(alpha: 0.05)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.whiteBlack, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _getSubscriptionStatusText(cancelAtPeriodEnd, nextBillingDate, billingPeriod),
                        style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.whiteBlack, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.star, color: theme.colorScheme.primary, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text(planName, style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.brightness == Brightness.dark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            )),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(_formatPlanPrice(planPrice), style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                if (billingPeriod.isNotEmpty)
                  Text(' / $billingPeriod', style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.brightness == Brightness.dark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  )),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? AppTheme.backgroundColorDark : AppTheme.backgroundColorLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (theme.brightness == Brightness.dark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(cancelAtPeriodEnd ? Icons.event_busy : Icons.event, color: cancelAtPeriodEnd ? AppTheme.errorColor : AppTheme.primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getDetailedDateText(nextBillingDate, cancelAtPeriodEnd, billingPeriod),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.brightness == Brightness.dark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (cancelAtPeriodEnd) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: theme.colorScheme.errorContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Your subscription will not renew automatically',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  String _formatPlanPrice(String price) {
    if (price.startsWith('\$')) return price;
    if (price.isNotEmpty) {
      final numPrice = double.tryParse(price);
      if (numPrice != null) return '\$${numPrice.toStringAsFixed(2)}';
    }
    return '\$0.00';
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Date unavailable';
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatDateLocal(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  int _getDaysUntilDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 0;
    }
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = date.difference(now);
      return difference.inDays;
    } catch (e) {
      return 0;
    }
  }

  String _getSubscriptionStatusText(bool cancelAtPeriodEnd, String? nextBillingDate, String? billingPeriod) {
    if (cancelAtPeriodEnd) {
      if (nextBillingDate != null && nextBillingDate.isNotEmpty) {
        final daysLeft = _getDaysUntilDate(nextBillingDate);
        if (daysLeft <= 7) {
          return 'Expires in $daysLeft days';
        }
      }
      return 'Expires Soon';
    }
    return 'Active';
  }

  String _getDetailedDateText(String? nextBillingDate, bool cancelAtPeriodEnd, String? billingPeriod) {
    if (nextBillingDate == null || nextBillingDate.isEmpty) {
      return cancelAtPeriodEnd ? 'Expires soon' : 'Active subscription';
    }

    final isMonthly = billingPeriod?.toLowerCase().contains('month') ?? false;
    final daysLeft = _getDaysUntilDate(nextBillingDate);
    
    if (cancelAtPeriodEnd) {
      if (isMonthly && daysLeft <= 31) {
        return 'Expires in $daysLeft days (${_formatDateLocal(nextBillingDate)})';
      } else {
        return 'Expires on ${_formatDate(nextBillingDate)}';
      }
    } else {
      if (isMonthly && daysLeft <= 31) {
        return 'Renews in $daysLeft days (${_formatDateLocal(nextBillingDate)})';
      } else {
        return 'Next billing: ${_formatDate(nextBillingDate)}';
      }
    }
  }

  void _showManageSubscriptionBottomSheet(Map<String, dynamic>? currentPlan) {
    if (currentPlan == null) {
      return;
    }
    
    final theme = Theme.of(context);
    final planName = currentPlan['name']?.toString() ?? 'Premium Plan';
    final planPrice = currentPlan['price']?.toString() ?? currentPlan['price_amount']?.toString() ?? '';
    final billingPeriod = currentPlan['interval']?.toString() ?? currentPlan['duration']?.toString() ?? '';
    final nextBillingDate = currentPlan['current_period_end']?.toString() ?? currentPlan['next_billing_date']?.toString() ?? '';
    final cancelAtPeriodEnd = currentPlan['cancel_at_period_end'] == true;
    final subscriptionId = currentPlan['subscription_id']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Manage Subscription',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            
            // Subscription details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan name and status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          planName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cancelAtPeriodEnd 
                              ? theme.colorScheme.errorContainer 
                              : theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          cancelAtPeriodEnd ? 'Expires Soon' : 'Active',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cancelAtPeriodEnd 
                                ? theme.colorScheme.onSurface 
                                : theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Price
                  Row(
                    children: [
                      Text(
                        _formatPlanPrice(planPrice),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (billingPeriod.isNotEmpty) ...[
                        Text(
                          ' / $billingPeriod',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Next billing/expiry date
                  if (nextBillingDate.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cancelAtPeriodEnd ? Icons.event_busy : Icons.event,
                            color: cancelAtPeriodEnd 
                                ? theme.colorScheme.error 
                                : theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cancelAtPeriodEnd ? 'Expires on' : 'Next billing date',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(nextBillingDate),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: cancelAtPeriodEnd 
                                        ? theme.colorScheme.error 
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Cancellation notice
                  if (cancelAtPeriodEnd) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your subscription will not renew automatically',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Cancel subscription button
            if (!cancelAtPeriodEnd) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showCancelConfirmationDialog(subscriptionId, planName, nextBillingDate);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.errorContainer,
                    foregroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel Subscription',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _reactivateSubscription();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Reactivate Subscription',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      // color: theme.colorScheme.onTertiary,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Close',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
            
            // Bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmationDialog(String? subscriptionId, String? planName, String? nextBillingDate) {
    final theme = Theme.of(context);
    bool cancelImmediately = false;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        // margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark 
              ? AppTheme.surfaceColorDark 
              : AppTheme.surfaceColorLight,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark 
                      ? AppTheme.textSecondaryDark.withValues(alpha: 0.4)
                      : AppTheme.textSecondaryLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Cancel Subscription',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.brightness == Brightness.dark 
                            ? AppTheme.textPrimaryDark 
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose when to end your subscription',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.brightness == Brightness.dark 
                            ? AppTheme.textSecondaryDark 
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                
                    // Cancellation options
                    GestureDetector(
                      onTap: () => setDialogState(() => cancelImmediately = false),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: !cancelImmediately 
                              ? theme.colorScheme.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !cancelImmediately 
                                ? theme.colorScheme.primary
                                : (theme.brightness == Brightness.dark 
                                    ? AppTheme.textSecondaryDark 
                                    : AppTheme.textSecondaryLight).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              !cancelImmediately 
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: !cancelImmediately 
                                  ? theme.colorScheme.primary
                                  : (theme.brightness == Brightness.dark 
                                      ? AppTheme.textSecondaryDark 
                                      : AppTheme.textSecondaryLight),
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'At end of billing period',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: !cancelImmediately 
                                          ? theme.colorScheme.primary
                                          : (theme.brightness == Brightness.dark 
                                              ? AppTheme.textPrimaryDark 
                                              : AppTheme.textPrimaryLight),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    nextBillingDate != null && nextBillingDate.isNotEmpty
                                        ? 'Access until ${_formatDate(nextBillingDate)}'
                                        : 'Access until end of billing period',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.brightness == Brightness.dark 
                                          ? AppTheme.textSecondaryDark 
                                          : AppTheme.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Immediate cancellation option
                    GestureDetector(
                      onTap: () => setDialogState(() => cancelImmediately = true),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cancelImmediately 
                              ? AppTheme.warningColor.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cancelImmediately 
                                ? AppTheme.warningColor
                                : (theme.brightness == Brightness.dark 
                                    ? AppTheme.textSecondaryDark 
                                    : AppTheme.textSecondaryLight).withValues(alpha: 0.3),
                            width:  1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              cancelImmediately 
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: cancelImmediately 
                                  ? AppTheme.warningColor
                                  : (theme.brightness == Brightness.dark 
                                      ? AppTheme.textSecondaryDark 
                                      : AppTheme.textSecondaryLight),
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Immediately',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: cancelImmediately 
                                          ? AppTheme.warningColor
                                          : (theme.brightness == Brightness.dark 
                                              ? AppTheme.textPrimaryDark 
                                              : AppTheme.textPrimaryLight),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Access ends now',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.brightness == Brightness.dark 
                                          ? AppTheme.textSecondaryDark 
                                          : AppTheme.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: theme.brightness == Brightness.dark 
                                    ? AppTheme.textSecondaryDark 
                                    : AppTheme.textSecondaryLight,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Keep Subscription',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.brightness == Brightness.dark 
                                    ? AppTheme.textPrimaryDark 
                                    : AppTheme.textPrimaryLight,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _cancelSubscription(cancelImmediately);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.warningColor,
                              foregroundColor: AppTheme.blackWhite,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.blackWhite,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Bottom safe area
                    SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _cancelSubscription(bool cancelImmediately) {
    _paymentBloc?.add(CancelSubscriptionEvent(
      cancelImmediately: cancelImmediately,
    ));
  }

  void _reactivateSubscription() {
    _paymentBloc?.add(ReactivateSubscriptionEvent());
  }
  
  void _handleCancellationSuccess(dynamic subscriptionDetails) {
    final theme = Theme.of(context);
    final originalContext = context; // Capture the original context
    
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.successColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Subscription Canceled',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.brightness == Brightness.dark 
                      ? AppTheme.textPrimaryDark 
                      : AppTheme.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Text(
                'Your subscription has been canceled successfully.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.brightness == Brightness.dark 
                      ? AppTheme.textSecondaryDark 
                      : AppTheme.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(bottomSheetContext); // Close success bottom sheet
                    Navigator.pop(originalContext); // Close pricing screen
                    // Refresh the subscription data using the original context
                    originalContext.read<AppBloc>().add(AppSubscriptions(token));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: AppTheme.whiteBlack,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.whiteBlack,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      // ),
    );
  }

  void _handleReactivationSuccess(dynamic subscriptionDetails) {
    final theme = Theme.of(context);
    final originalContext = context; // Capture the original context
    
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.refresh,
                  color: AppTheme.successColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Subscription Reactivated',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.brightness == Brightness.dark 
                      ? AppTheme.textPrimaryDark 
                      : AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                'Your subscription has been successfully reactivated and will continue renewing automatically.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.dark 
                      ? AppTheme.textSecondaryDark 
                      : AppTheme.textSecondaryLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(bottomSheetContext); // Close success bottom sheet
                    Navigator.pop(originalContext); // Close pricing screen
                    // Refresh the subscription data using the original context
                    originalContext.read<AppBloc>().add(AppSubscriptions(token));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: AppTheme.whiteBlack,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.whiteBlack,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      // ),
    );
  }
}