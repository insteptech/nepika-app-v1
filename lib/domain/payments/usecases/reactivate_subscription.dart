import '../entities/subscription_details.dart';
import '../repositories/payments_repository.dart';

class ReactivateSubscription {
  final PaymentsRepository repository;

  ReactivateSubscription(this.repository);

  Future<SubscriptionDetails> call() async {
    return await repository.reactivateSubscription();
  }
}