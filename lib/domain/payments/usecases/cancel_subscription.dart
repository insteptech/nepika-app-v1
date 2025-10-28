import '../entities/subscription_details.dart';
import '../repositories/payments_repository.dart';

class CancelSubscription {
  final PaymentsRepository repository;

  CancelSubscription(this.repository);

  Future<SubscriptionDetails> call({bool cancelImmediately = false}) async {
    return await repository.cancelSubscription(cancelImmediately: cancelImmediately);
  }
}