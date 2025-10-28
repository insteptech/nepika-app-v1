import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection_container.dart';
import '../../../domain/payments/entities/subscription_status.dart';
import '../../../domain/payments/entities/subscription_details.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';

class SubscriptionManagementScreen extends StatelessWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ServiceLocator.get<PaymentBloc>()..add(LoadSubscriptionStatus()),
      child: const _SubscriptionManagementView(),
    );
  }
}

class _SubscriptionManagementView extends StatelessWidget {
  const _SubscriptionManagementView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is SubscriptionCanceled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.details.cancelAtPeriodEnd
                      ? 'Subscription will cancel at period end'
                      : 'Subscription canceled successfully',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          } else if (state is SubscriptionReactivated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subscription reactivated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is PaymentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PaymentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SubscriptionStatusLoaded) {
            return _buildSubscriptionStatusView(context, state.status);
          }

          if (state is SubscriptionDetailsLoaded ||
              state is SubscriptionCanceled ||
              state is SubscriptionReactivated) {
            SubscriptionDetails details;
            if (state is SubscriptionDetailsLoaded) {
              details = state.details;
            } else if (state is SubscriptionCanceled) {
              details = state.details;
            } else {
              details = (state as SubscriptionReactivated).details;
            }
            return _buildSubscriptionDetailsView(context, details);
          }

          if (state is PaymentError) {
            return _buildErrorView(context, state.message);
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildSubscriptionStatusView(BuildContext context, SubscriptionStatus status) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(context, status),
          const SizedBox(height: 20),
          if (status.hasPremium) ...[
            _buildManageButton(context, 'View Details', () {
              context.read<PaymentBloc>().add(LoadSubscriptionDetails());
            }),
            const SizedBox(height: 12),
          ],
          if (!status.hasPremium) ...[
            _buildManageButton(context, 'Upgrade to Premium', () {
              Navigator.of(context).pushNamed('/subscription-plans');
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetailsView(BuildContext context, SubscriptionDetails details) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailsCard(context, details),
          const SizedBox(height: 20),
          if (details.status == 'active' && !details.cancelAtPeriodEnd) ...[
            _buildManageButton(context, 'Cancel Subscription', () {
              _showCancelConfirmationDialog(context);
            }, isDestructive: true),
          ],
          if (details.cancelAtPeriodEnd) ...[
            _buildManageButton(context, 'Reactivate Subscription', () {
              context.read<PaymentBloc>().add(ReactivateSubscriptionEvent());
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, SubscriptionStatus status) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status.hasPremium ? Icons.star : Icons.star_border,
                  color: status.hasPremium ? Colors.amber : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  status.hasPremium ? 'Premium Active' : 'Free Plan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (status.hasPremium) ...[
              _buildInfoRow('Plan', status.plan.toUpperCase()),
              _buildInfoRow('Billing', status.interval),
              _buildInfoRow('Status', _getStatusDisplay(status.status)),
              _buildInfoRow(
                'Renews on',
                _formatDate(status.currentPeriodEnd),
              ),
              if (status.cancelAtPeriodEnd)
                _buildInfoRow(
                  'Notice',
                  'Will cancel on ${_formatDate(status.currentPeriodEnd)}',
                  isWarning: true,
                ),
            ] else ...[
              Text(
                'Upgrade to Premium for unlimited features',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, SubscriptionDetails details) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Plan', details.plan.toUpperCase()),
            _buildInfoRow('Billing', details.interval),
            _buildInfoRow('Status', _getStatusDisplay(details.status)),
            _buildInfoRow('Started', _formatDate(details.currentPeriodStart)),
            _buildInfoRow('Renews on', _formatDate(details.currentPeriodEnd)),
            if (details.cancelAtPeriodEnd)
              _buildInfoRow(
                'Cancellation',
                'Will cancel on ${_formatDate(details.currentPeriodEnd)}',
                isWarning: true,
              ),
            if (details.canceledAt != null)
              _buildInfoRow('Canceled on', _formatDate(details.canceledAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              color: isWarning ? Colors.orange : null,
              fontWeight: isWarning ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageButton(
    BuildContext context,
    String text,
    VoidCallback onPressed, {
    bool isDestructive = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive ? Colors.red : Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading subscription',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<PaymentBloc>().add(LoadSubscriptionStatus());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Subscription'),
          content: const Text(
            'Are you sure you want to cancel your subscription? You will still have access until the end of your billing period.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Keep Subscription'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<PaymentBloc>().add(
                      const CancelSubscriptionEvent(cancelImmediately: false),
                    );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'canceled':
        return 'Canceled';
      case 'incomplete':
        return 'Incomplete';
      case 'past_due':
        return 'Past Due';
      case 'trialing':
        return 'Trial';
      case 'unpaid':
        return 'Unpaid';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}