import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/widgets/custom_button.dart';
import 'package:nepika/data/app/repositories/app_repository.dart';
import 'package:nepika/presentation/bloc/app/app_bloc.dart';
import 'package:nepika/presentation/bloc/app/app_event.dart';
import 'package:nepika/presentation/bloc/app/app_state.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final String token = '';
  int selectedPlanIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocProvider(
        create: (context) =>
            AppBloc(appRepository: AppRepositoryImpl(ApiBase()))
              ..add(AppSubscriptions(token)),
        child: SafeArea(
          child: BlocBuilder<AppBloc, AppState>(
            builder: (context, state) {
              Map<String, dynamic> data = {};
              List<dynamic> features = [];
              List<dynamic> plans = [];

              if (state is AppSubscriptionLoaded) {
                data = state.subscriptionPlan;
                features = data['features'] ?? [];
                plans = data['plans'] ?? [];
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '\$${plan['price'] ?? ''}.00',
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
                        isLoading: false,
                        onPressed: () {},
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
    );
  }
}