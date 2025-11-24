import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart'  hide IAPError;
import 'package:nepika/features/payments/bloc/payment_bloc.dart';
import 'package:nepika/features/payments/bloc/payment_event.dart';
import 'package:nepika/features/payments/bloc/payment_state.dart';

class IAPPurchaseBottomSheet extends StatelessWidget {
  final Map<String, dynamic> selectedPlan;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const IAPPurchaseBottomSheet({
    super.key,
    required this.selectedPlan,
    this.onSuccess,
    this.onCancel,
  });

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> selectedPlan,
    required IAPBloc iapBloc,
    VoidCallback? onSuccess,
    VoidCallback? onCancel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: iapBloc,
        child: IAPPurchaseBottomSheet(
          selectedPlan: selectedPlan,
          onSuccess: onSuccess,
          onCancel: onCancel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planName = selectedPlan['name']?.toString() ?? 'Premium Plan';
    final priceDisplay = selectedPlan['priceDisplay']?.toString() ?? '';
    final billingPeriod = selectedPlan['billingPeriod']?.toString() ?? '';

    return BlocConsumer<IAPBloc, IAPState>(
      listener: (context, state) {
        if (state is IAPPurchaseSuccess) {
          Navigator.pop(context);
          _showSuccessSheet(context, state.purchaseDetails);
          onSuccess?.call();
        } else if (state is IAPError) {
          _showErrorSnackBar(context, state.message);
        } else if (state is IAPPurchaseCanceled) {
          Navigator.pop(context);
          onCancel?.call();
        }
      },
      builder: (context, state) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (state is IAPLoading || state is IAPPurchasePending)
                    _buildLoadingState(theme, state)
                  else if (state is IAPError)
                    _buildErrorState(theme, state, context, billingPeriod)
                  else if (state is IAPNotAvailable)
                    _buildErrorState(theme, IAPError(state.message), context, billingPeriod)
                  else
                    _buildPurchaseState(theme, context, planName, priceDisplay, billingPeriod),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(ThemeData theme, IAPState state) {
    String message = 'Processing...';
    if (state is IAPLoading && state.message != null) {
      message = state.message!;
    } else if (state is IAPPurchasePending) {
      message = 'Waiting for payment confirmation...';
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          message,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Please do not close this screen',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme, IAPError state, BuildContext context, String billingPeriod) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error_outline, color: theme.colorScheme.error, size: 40),
        ),
        const SizedBox(height: 20),
        Text(
          'Purchase Failed',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            state.message,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _startPurchase(context, billingPeriod),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPurchaseState(
    ThemeData theme,
    BuildContext context,
    String planName,
    String priceDisplay,
    String billingPeriod,
  ) {
    final iapBloc = context.read<IAPBloc>();
    final storeProduct = iapBloc.getProductByInterval(billingPeriod);
    final displayPrice = storeProduct?.price ?? priceDisplay;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.workspace_premium, color: theme.colorScheme.primary, size: 40),
        ),
        const SizedBox(height: 20),
        Text(
          'Confirm Purchase',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      planName, 
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'PREMIUM',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    displayPrice,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (billingPeriod.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '/ $billingPeriod',
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'You will be charged through your ${_getPlatformStoreName()} account. '
            'Subscription auto-renews unless cancelled at least 24 hours before the end of the current period.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _startPurchase(context, billingPeriod),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Subscribe Now',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onCancel?.call();
          },
          child: Text(
            'Cancel',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
      ],
    );
  }

  void _startPurchase(BuildContext context, String billingPeriod) {
    String interval = 'weekly'; // default
    if (billingPeriod.toLowerCase().contains('year')) {
      interval = 'yearly';
    } else if (billingPeriod.toLowerCase().contains('week')) {
      interval = 'weekly';
    }
    context.read<IAPBloc>().add(PurchaseByInterval(interval));
  }

  String _getPlatformStoreName() {
    if (Platform.isIOS) return 'App Store';
    if (Platform.isAndroid) return 'Google Play';
    return 'App Store / Google Play';
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccessSheet(BuildContext context, PurchaseDetails purchase) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                'Purchase Successful!',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome to Nepika Premium!\nYou now have access to all premium features.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Get Started',
                    style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}