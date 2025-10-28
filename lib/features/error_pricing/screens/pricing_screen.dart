import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/widgets/custom_button.dart';
import 'package:nepika/core/di/injection_container.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nepika/data/app/repositories/app_repository.dart';
import 'package:nepika/presentation/bloc/app/app_bloc.dart';
import 'package:nepika/presentation/bloc/app/app_event.dart';
import 'package:nepika/presentation/bloc/app/app_state.dart';
import 'package:nepika/features/payments/bloc/payment_bloc.dart';
import 'package:nepika/features/payments/bloc/payment_event.dart';
import 'package:nepika/features/payments/bloc/payment_state.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  String token = '';
  int selectedPlanIndex = 0;
  late PaymentBloc _paymentBloc;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _paymentBloc = ServiceLocator.get<PaymentBloc>();
    _getToken();
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
    _paymentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AppBloc(appRepository: AppRepositoryImpl(ApiBase()))
                  ..add(AppSubscriptions(token)),
          ),
          BlocProvider.value(value: _paymentBloc),
        ],
        child: SafeArea(
          child: BlocListener<PaymentBloc, PaymentState>(
            listener: (context, state) {
              if (state is CheckoutSessionCreated) {
                _launchCheckoutUrl(state.session.url);
              } else if (state is PaymentError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              setState(() {
                _isLoading = state is PaymentLoading;
              });
            },
            child: BlocBuilder<AppBloc, AppState>(
            builder: (context, state) {
              Map<String, dynamic> data = {};
              List<dynamic> features = [];
              List<dynamic> plans = [];

              if (state is AppSubscriptionLoaded) {
                data = state.subscriptionPlan;
                
                // Extract plans from the API response structure
                final plansData = data['plans'] as List<dynamic>? ?? [];
                plans = plansData.map((plan) => {
                  'name': plan['name'],
                  'price': plan['price'],
                  'billingPeriod': plan['duration'],
                  'stripe_price_id': plan['stripe_price_id'],
                }).toList();
                
                // Extract features from the first plan's plan_details
                if (plansData.isNotEmpty) {
                  final firstPlan = plansData.first;
                  final planDetails = firstPlan['plan_details'] as List<dynamic>? ?? [];
                  features = planDetails.map((detail) => {
                    'title': detail.toString(),
                  }).toList();
                }
              }
              
              // Add fallback data if no features/plans loaded
              if (features.isEmpty) {
                features = [
                  {'title': 'Unlimited face scans per month'},
                  {'title': 'Detailed skin analysis across all 9 parameters'},
                  {'title': 'Advanced AI recommendations'},
                  {'title': 'Priority customer support'},
                ];
              }
              
              if (plans.isEmpty) {
                plans = [
                  {
                    'name': 'Nepika Premium Monthly',
                    'price': 6.99,
                    'billingPeriod': 'monthly',
                    'stripe_price_id': 'price_1SLe3b9GE4oycUj8rjX69Us8',
                  },
                  {
                    'name': 'Nepika Premium Yearly',
                    'price': 60.00,
                    'billingPeriod': 'yearly',
                    'stripe_price_id': 'price_1SLe3c9GE4oycUj8rjX69Us9',
                  }
                ];
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Transform.rotate(
                              angle:
                                  45 *
                                  3.1415926535 /
                                  180,
                              child: Image.asset(
                                'assets/icons/add_icon.png',
                                width: 28,
                                height: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSecondary,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Image.asset(
                          'assets/images/nepika_logo_image.png',
                          color: theme.primaryIconTheme.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      data['title'] ?? 'Nepika Premium',
                      style: theme.textTheme.displaySmall
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data['subtitle'] ?? 'Know what touches your skin',
                      style: theme.textTheme.headlineMedium!.secondary(context)
                    ),
                    const SizedBox(height: 45),

                    // Features
                    ...features.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: 15,
                          left: 20,
                          right: 20,
                        ),
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
                                child: Image.asset(
                                  'assets/icons/unlock_icon.png',
                                  width: 18,
                                  height: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Text(
                                feature['title'] ?? '',
                                style: theme.textTheme.headlineLarge
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Plans
                    ...List.generate(plans.length, (index) {
                      final plan = plans[index];
                      final isSelected = selectedPlanIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => selectedPlanIndex = index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            border: Border.all(color: theme.colorScheme.primary),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? theme.colorScheme.onSecondary
                                    : theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  plan['name'] ?? '',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: isSelected
                                        ? theme.colorScheme.onSecondary
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${plan['price'] ?? ''}',
                                    textAlign: TextAlign.left,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: isSelected
                                        ? theme.colorScheme.onSecondary
                                        : theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600
                                    ),
                                  ),
                                  Text(
                                    'Per ${plan['billingPeriod']}',
                                    textAlign: TextAlign.left,
                                    style: Theme.of(context).textTheme.bodyMedium!.secondary(context).copyWith(
                                      color: isSelected
                                          ? theme.colorScheme.onSecondary
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CustomButton(
                        text: 'Continue',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : () => _onContinuePressed(plans),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Terms and Privacy',
                            style: theme.textTheme.bodyMedium
                          ),
                          Text(
                            'Restore',
                            style: theme.textTheme.bodyMedium
                          ),
                        ],
                      ),
                    ),

                    // const SizedBox(height: 24),
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

  void _onContinuePressed(List<dynamic> plans) {
    if (plans.isEmpty || selectedPlanIndex >= plans.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid plan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedPlan = plans[selectedPlanIndex];
    final priceId = selectedPlan['stripe_price_id']?.toString() ?? '';
    final billingPeriod = selectedPlan['billingPeriod']?.toString().toLowerCase() ?? '';
    
    if (priceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid plan selected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Map billing period to interval
    String interval;
    if (billingPeriod.contains('month')) {
      interval = 'monthly';
    } else if (billingPeriod.contains('year')) {
      interval = 'yearly';
    } else {
      interval = 'monthly'; // Default
    }

    // Create checkout session with the selected plan
    _paymentBloc.add(CreateCheckoutSessionEvent(
      priceId: priceId,
      interval: interval,
    ));
  }

  Future<void> _launchCheckoutUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch payment page'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}